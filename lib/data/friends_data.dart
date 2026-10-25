import '../models/friend.dart';
import '../theme/app_colors.dart';

/// Contas reais do sistema (perfis de demonstração persistidos na primeira
/// abertura). Podem ser buscadas, seguidas e abertas como qualquer outra.
const List<Friend> kFriends = [
  Friend(
    id: 'diego',
    name: 'Diego',
    handle: 'diego.gv',
    accent: AppColors.purple,
    favoriteGame: 'Elden Ring',
    reviews: [
      GameReview(
        gameName: 'Hollow Knight: Silksong',
        userScore: 10,
        reviewText:
            'Silksong entrega a mesma precisão do primeiro Hollow Knight, '
            'com chefes ainda mais exigentes. Virei a noite nisso.',
        ratedAtMillis: 1761350400000,
      ),
      GameReview(
        gameName: 'Elden Ring',
        userScore: 10,
        reviewText:
            'Cada atalho e cada boss secreto recompensam a exploração. '
            'Continua sendo o meu RPG favorito.',
        ratedAtMillis: 1761177600000,
      ),
      GameReview(
        gameName: 'Hollow Knight',
        userScore: 10,
        ratedAtMillis: 1761004800000,
      ),
      GameReview(
        gameName: 'Outer Wilds',
        userScore: 10,
        ratedAtMillis: 1760832000000,
      ),
      GameReview(
        gameName: 'Undertale',
        userScore: 10,
        ratedAtMillis: 1760659200000,
      ),
      GameReview(
        gameName: 'Minecraft',
        userScore: 8,
        ratedAtMillis: 1760486400000,
      ),
    ],
  ),
  Friend(
    id: 'thiago',
    name: 'Thiago',
    handle: 'thiago.plays',
    accent: AppColors.blue,
    favoriteGame: 'Red Dead Redemption 2',
    reviews: [
      GameReview(
        gameName: 'The Last of Us',
        userScore: 10,
        reviewText:
            'A jornada de Joel e Ellie ainda aperta o coração. '
            'Rejogar antes da Parte II valeu cada minuto.',
        ratedAtMillis: 1761264000000,
      ),
      GameReview(
        gameName: 'Red Dead Redemption 2',
        userScore: 10,
        reviewText:
            'O mundo respira. Arthur Morgan é um dos melhores protagonistas '
            'que já vi em um jogo.',
        ratedAtMillis: 1761091200000,
      ),
      GameReview(
        gameName: 'The Last of Us Part II',
        userScore: 8,
        ratedAtMillis: 1760918400000,
      ),
      GameReview(
        gameName: 'God of War Ragnarök',
        userScore: 8,
        ratedAtMillis: 1760745600000,
      ),
      GameReview(
        gameName: 'Horizon Zero Dawn',
        userScore: 8,
        ratedAtMillis: 1760572800000,
      ),
      GameReview(
        gameName: 'Detroit: Become Human',
        userScore: 8,
        ratedAtMillis: 1760400000000,
      ),
    ],
  ),
  Friend(
    id: 'pedro',
    name: 'Pedro',
    handle: 'pedro.rpg',
    accent: AppColors.darkBlue,
    favoriteGame: 'The Witcher 3: Wild Hunt',
    reviews: [
      GameReview(
        gameName: 'Kingdom Come: Deliverance II',
        userScore: 10,
        reviewText:
            'Imersão medieval absurda. Combate pesado, missões densas e um '
            'mundo que pune quem tenta apressar o jogo.',
        ratedAtMillis: 1761307200000,
      ),
      GameReview(
        gameName: 'The Witcher 3: Wild Hunt',
        userScore: 10,
        ratedAtMillis: 1761134400000,
      ),
      GameReview(
        gameName: 'The Elder Scrolls V: Skyrim',
        userScore: 8,
        ratedAtMillis: 1760961600000,
      ),
      GameReview(
        gameName: 'Cyberpunk 2077',
        userScore: 8,
        ratedAtMillis: 1760788800000,
      ),
      GameReview(
        gameName: 'Titanfall 2',
        userScore: 10,
        ratedAtMillis: 1760616000000,
      ),
      GameReview(
        gameName: 'Kingdom Come: Deliverance',
        userScore: 8,
        ratedAtMillis: 1760443200000,
      ),
    ],
  ),
  Friend(
    id: 'israel',
    name: 'Israel',
    handle: 'israel.halo',
    accent: AppColors.purple,
    favoriteGame: 'Halo 2',
    reviews: [
      GameReview(
        gameName: 'Halo Infinite',
        userScore: 8,
        reviewText:
            'O sandbox aberto deu uma nova cara à campanha. Ainda sinto falta '
            'do ritmo clássico, mas o tiroteio está afiado.',
        ratedAtMillis: 1761220800000,
      ),
      GameReview(
        gameName: 'Halo 2',
        userScore: 10,
        ratedAtMillis: 1761048000000,
      ),
      GameReview(
        gameName: 'Halo 3',
        userScore: 10,
        ratedAtMillis: 1760875200000,
      ),
      GameReview(
        gameName: 'Halo: Reach',
        userScore: 10,
        ratedAtMillis: 1760702400000,
      ),
      GameReview(
        gameName: 'Call of Duty: Black Ops II',
        userScore: 8,
        ratedAtMillis: 1760529600000,
      ),
      GameReview(
        gameName: 'Halo Combat Evolved',
        userScore: 8,
        ratedAtMillis: 1760356800000,
      ),
    ],
  ),
  Friend(
    id: 'gabriel',
    name: 'Gabriel',
    handle: 'gabriel.nintendista',
    accent: AppColors.blue,
    favoriteGame: 'The Legend of Zelda: Breath of the Wild',
    reviews: [
      GameReview(
        gameName: 'Super Mario Odyssey',
        userScore: 10,
        reviewText:
            'O Chapéu Captura transforma cada reino numa brincadeira nova. '
            'É o Mario mais criativo que já joguei.',
        ratedAtMillis: 1761278400000,
      ),
      GameReview(
        gameName: 'The Legend of Zelda: Breath of the Wild',
        userScore: 10,
        ratedAtMillis: 1761105600000,
      ),
      GameReview(
        gameName: 'Animal Crossing: New Horizons',
        userScore: 8,
        ratedAtMillis: 1760932800000,
      ),
      GameReview(
        gameName: 'Super Smash Bros. Ultimate',
        userScore: 10,
        ratedAtMillis: 1760760000000,
      ),
      GameReview(
        gameName: 'Pokemon: Fire Red',
        userScore: 10,
        ratedAtMillis: 1760587200000,
      ),
      GameReview(
        gameName: 'The Legend of Zelda: Ocarina of Time',
        userScore: 10,
        ratedAtMillis: 1760414400000,
      ),
    ],
  ),
  Friend(
    id: 'gisleine',
    name: 'Gisleine',
    handle: 'gisleine.jrpg',
    accent: AppColors.darkBlue,
    favoriteGame: 'Clair Obscur: Expedition 33',
    reviews: [
      GameReview(
        gameName: 'Persona 3: Reload',
        userScore: 10,
        reviewText:
            'A rotina da SEES, a trilha e os social links me prenderam do '
            'começo ao fim. Reload respeita o original e brilha visualmente.',
        ratedAtMillis: 1761336000000,
      ),
      GameReview(
        gameName: 'Clair Obscur: Expedition 33',
        userScore: 10,
        ratedAtMillis: 1761163200000,
      ),
      GameReview(
        gameName: 'Life is Strange',
        userScore: 10,
        ratedAtMillis: 1760990400000,
      ),
      GameReview(
        gameName: 'Hollow Knight: Silksong',
        userScore: 10,
        ratedAtMillis: 1760817600000,
      ),
      GameReview(
        gameName: 'Undertale',
        userScore: 10,
        ratedAtMillis: 1760644800000,
      ),
      GameReview(
        gameName: 'Beyond Two Souls',
        userScore: 6,
        ratedAtMillis: 1760472000000,
      ),
    ],
  ),
];
