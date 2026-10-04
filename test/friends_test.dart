import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gameview/data/friends_data.dart';
import 'package:gameview/models/friend.dart';
import 'package:gameview/models/game.dart';
import 'package:gameview/screens/friend_list.dart';
import 'package:gameview/services/friends_service.dart';

void main() {
  const eldenRing = Game(
    id: 1,
    name: 'Elden Ring',
    platform: 'Todas plataformas',
    score: 10,
    imageUrl: 'https://example.com/elden-ring.jpg',
  );
  final catalog = {'elden ring': eldenRing};

  group('FriendsService.rankFor', () {
    test('mantém a ordem informada, começando no 1º lugar', () {
      const friend = Friend(name: 'Teste', topGames: ['A', 'B', 'C']);

      final ranking = FriendsService.rankFor(friend, const {});

      expect(ranking.map((item) => item.rank), [1, 2, 3]);
      expect(ranking.map((item) => item.name), ['A', 'B', 'C']);
    });

    test('ignora maiúsculas/minúsculas e espaços ao buscar no catálogo', () {
      const friend = Friend(name: 'Teste', topGames: ['  ELDEN ring ']);

      final ranking = FriendsService.rankFor(friend, catalog);

      expect(ranking.single.game, eldenRing);
    });

    test('jogo fora do catálogo continua no ranking, sem Game', () {
      const friend = Friend(name: 'Teste', topGames: ['Jogo Inexistente']);

      final ranking = FriendsService.rankFor(friend, catalog);

      expect(ranking.single.name, 'Jogo Inexistente');
      expect(ranking.single.game, isNull);
    });

    test('limita o ranking a 5 jogos', () {
      const friend = Friend(
        name: 'Teste',
        topGames: ['1', '2', '3', '4', '5', '6', '7'],
      );

      expect(FriendsService.rankFor(friend, const {}), hasLength(5));
    });
  });

  testWidgets('Amigos mostra o Nº 1 e abre o top 5 do amigo', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final friend = kFriends.first;

    await tester.pumpWidget(const MaterialApp(home: FriendListScreen()));
    await tester.pump();

    // Na lista aparece o amigo e apenas o jogo Nº 1 dele.
    expect(find.text(friend.name), findsOneWidget);
    expect(find.text(friend.topGames.first), findsOneWidget);
    expect(find.text(friend.topGames.last), findsNothing);

    await tester.tap(find.text(friend.name));
    await tester.pumpAndSettle();

    // No perfil aparecem os jogos do top 5.
    expect(find.text('Top 5 jogos favoritos'), findsOneWidget);
    for (final name in friend.topGames.take(5)) {
      expect(find.text(name), findsOneWidget);
    }
  });
}
