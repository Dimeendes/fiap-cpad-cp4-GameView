import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gameview/data/friends_data.dart';
import 'package:gameview/models/friend.dart';
import 'package:gameview/models/game.dart';
import 'package:gameview/screens/friend_list.dart';
import 'package:gameview/services/favorite_game_service.dart';
import 'package:gameview/services/friends_service.dart';
import 'package:gameview/widgets/ratings_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const eldenRing = Game(
    id: 1,
    name: 'Elden Ring',
    platform: 'Todas plataformas',
    score: 10,
    imageUrl: 'https://example.com/elden-ring.jpg',
  );
  final catalog = {'elden ring': eldenRing};

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'nome': 'Jogador',
      'email': 'jogador@gameview.app',
    });
  });

  group('FriendsService.favoriteFor', () {
    test('sem favorito escolhido, devolve null', () {
      const friend = Friend(name: 'Teste');

      expect(FriendsService.favoriteFor(friend, catalog), isNull);
    });

    test('ignora maiúsculas/minúsculas e espaços ao buscar no catálogo', () {
      const friend = Friend(name: 'Teste', favoriteGame: '  ELDEN ring ');

      expect(FriendsService.favoriteFor(friend, catalog)?.game, eldenRing);
    });

    test('jogo fora do catálogo continua como favorito, sem Game', () {
      const friend = Friend(name: 'Teste', favoriteGame: 'Jogo Inexistente');

      final favorite = FriendsService.favoriteFor(friend, catalog);

      expect(favorite?.name, 'Jogo Inexistente');
      expect(favorite?.game, isNull);
    });

    test('contas salvas com top 5 antigo usam o 1º como favorito', () {
      final friend = Friend.fromJson({
        'name': 'Antiga',
        'topGames': ['Elden Ring', 'Hollow Knight'],
      });

      expect(friend.favoriteGame, 'Elden Ring');
      expect(Friend.fromJson(friend.toJson()).favoriteGame, 'Elden Ring');
    });
  });

  group('FavoriteGameService', () {
    test('salva, lê e remove o favorito do perfil', () async {
      expect(await FavoriteGameService.load(), isNull);

      await FavoriteGameService.save('Elden Ring');
      expect(await FavoriteGameService.load(), 'Elden Ring');
      expect(
        (await FriendsService.currentUserAccount())?.favoriteGame,
        'Elden Ring',
      );

      await FavoriteGameService.save(null);
      expect(await FavoriteGameService.load(), isNull);
    });
  });

  group('RatingsSummary.histogram', () {
    test('agrupa notas de 0–10 em 1 a 5 estrelas', () {
      expect(RatingsSummary.histogram([2, 4, 10, 10, 8]), [1, 1, 0, 1, 2]);
    });
  });

  group('contas e recomendações', () {
    test('persiste os perfis seed como contas reais e inclui o usuário logado', () async {
      final directory = await FriendsService.loadDirectory();

      expect(
        directory.accounts.map((account) => account.name),
        containsAll(['Diego', 'Thiago', 'Pedro', 'Israel', 'Gabriel', 'Gisleine', 'Jogador']),
      );
      expect(directory.recommended, hasLength(FriendsService.recommendLimit));
      expect(directory.friends, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(FriendsService.directoryKey), isNotEmpty);
    });

    test('ao seguir, o recomendado sai e outro entra no limite de 3', () async {
      var directory = await FriendsService.loadDirectory();
      final first = directory.recommended.first;
      final fourth = directory.followableAccounts[3];

      expect(directory.recommended, hasLength(3));
      expect(directory.recommended.contains(fourth), isFalse);

      await FriendsService.follow(first.accountId);
      directory = await FriendsService.loadDirectory();

      expect(directory.recommended, hasLength(3));
      expect(
        directory.recommended.map((account) => account.accountId),
        isNot(contains(first.accountId)),
      );
      expect(
        directory.recommended.map((account) => account.accountId),
        contains(fourth.accountId),
      );
      expect(directory.friends.single.accountId, first.accountId);
    });

    test('busca de amigos só vê quem já segue; busca de contas vê todos', () async {
      await FriendsService.follow('gisleine');
      final directory = await FriendsService.loadDirectory();

      expect(directory.searchFriends('gis').single.name, 'Gisleine');
      expect(directory.searchFriends('diego'), isEmpty);
      expect(
        directory.searchAccounts('diego').map((account) => account.name),
        contains('Diego'),
      );
      expect(
        directory.searchAccounts('jogador').single.isCurrentUser,
        isTrue,
      );
    });

    test('perfil expõe um favorito, análise mais recente e os 5 jogos avaliados', () {
      final diego = kFriends.first;

      expect(diego.favoriteGame, 'Elden Ring');
      expect(diego.latestAnalysis?.gameName, 'Hollow Knight: Silksong');
      expect(diego.recentGames(), hasLength(5));
      expect(diego.recentGames().first.gameName, 'Hollow Knight: Silksong');
      expect(
        diego.recentGames().map((review) => review.gameName),
        isNot(contains('Minecraft')),
      );
    });
  });

  testWidgets('Amigos recomenda 3 contas, segue e abre o perfil completo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: FriendListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Amigos recomendados'), findsOneWidget);
    expect(find.text('Diego'), findsOneWidget);
    expect(find.text('Thiago'), findsOneWidget);
    expect(find.text('Pedro'), findsOneWidget);
    expect(find.text('Israel'), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Seguir').first);
    await tester.pumpAndSettle();

    expect(find.text('Seus amigos'), findsOneWidget);
    expect(find.text('Israel'), findsOneWidget);
    expect(find.text('Atividade dos amigos'), findsOneWidget);
    expect(find.text('Diego analisou'), findsWidgets);

    await tester.tap(find.text('Contas'));
    await tester.pumpAndSettle();

    expect(find.text('Todas as contas'), findsOneWidget);
    expect(find.text('Gisleine'), findsOneWidget);
    expect(find.text('Jogador (você)'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'gisleine');
    await tester.pumpAndSettle();

    expect(find.text('Gisleine'), findsOneWidget);
    expect(find.text('Diego'), findsNothing);

    await tester.tap(find.text('Gisleine'));
    await tester.pumpAndSettle();

    expect(find.text('Jogo favorito'), findsOneWidget);
    expect(find.text('Favorito'), findsOneWidget);
    expect(find.text('Estatísticas'), findsOneWidget);
    expect(find.text('Análise mais recente'), findsOneWidget);
    expect(find.text('Jogos recentes'), findsOneWidget);
    expect(find.text('Clair Obscur: Expedition 33'), findsWidgets);
    expect(
      find.textContaining('A rotina da SEES'),
      findsOneWidget,
    );
  });
}
