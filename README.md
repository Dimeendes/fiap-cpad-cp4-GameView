# GameView

<img width="300" height="300" alt="logo" src="https://github.com/user-attachments/assets/b1a6f0ae-832b-4ecb-86a0-ca8f87ac8adc" />

 Uma aplicação de review para os amantes de jogos, criada para centralizar em um único espaço a experiência de descobrir, avaliar, organizar e compartilhar opiniões sobre jogos. Diferente das plataformas tradicionais, o aplicativo busca transformar o histórico de jogos do usuário em uma experiência social e personalizada, permitindo criar listas, registrar jogos zerados ou em andamento, atribuir notas e acompanhar avaliações de amigos e da comunidade.

 O diferencial competitivo está em unir a organização pessoal de um backlog com a interação social de uma plataforma de reviews

#
## Naming rationale
O nome **GameView** foi escolhido justamente por combinar as palavras **Game**, que representa o universo dos jogos, e **View**, 
que representa a opinião, avaliação e perspectiva dos jogadores. Esse nome reforça a proposta do app e o intuito de 
reunir experiências, opiniões e interações sobre inúmeros jogos em um único lugar.
# 
## Tom de voz
O app utiliza um tom de voz descontraído e próximo da comunidade gamer, com uma linguagem simples e acessível.  O objetivo é atrair os amantes de jogos e tornar a experiência de avaliar, descobrir e compartilhar opiniões  mais natural e divertida, além de incentivar a interação entre os usuários e seus amigos.


#
## Integrantes
| Nome| RM |
| ----- | ------ |
| Thiago Sobral de Alvarenga | 562695 |
| Pedro Miranda Campos Riato | 562117
| Israel Karacsony de Camargo Nunes | 563435 |
| Diego Antonio Silva Mendes | 565509 |
| Giovanni de Lela Anjos Costa | 563066 |
| Gabriel Hiro Nakamura | 562221 |
| Gisleine Muñoz Ticona |  563804 |

# 
## Informações do MVP
1. Funcionalidade de escrever avaliações e dar notas para diferentes jogos
2. Lista de amigos com função de visualizar suas respectivas avaliações
3. Catálogo de jogos com inúmeras opções
4. Biblioteca para visualizar seus jogos avaliados e adicionar jogos para "Jogar depois"
5. Personalização de perfil

O app permite cadastrar mais de uma conta neste dispositivo. Contas, senhas e biblioteca são armazenadas localmente; cada biblioteca e foto de perfil usa um ID estável próprio, então alterar o e-mail não desvincula os dados. Essas informações não são sincronizadas entre dispositivos.

## Rodar o projeto

`flutter run -d windows --dart-define="SUPABASE_URL=https://<project-ref>.supabase.co" --dart-define="SUPABASE_ANON_KEY=<sua-chave-publica>"`

## Público alvo

Jogadores: Atualmente jogos são muito caros, com a plataforma você pode acompanhar as médias de notas do jogos para decidir se compensa comprar o jogo ou não além de catálogar os seus próprios.

Desenvolvedores: Ler feedbacks da comunidade sobre quais pontos ainda podem ser melhorados no jogo desenvolvido e receber até idéias de possíveis atualizações.

## Modelo de negócio

Para monetizar o app pensamos em parcerias e afiliados com lojas de jogos para ganharmos uma comissão por uma compra feita por um link de um jogo do nosso app.

## Arquitetura do projeto

```
lib/
├── main.dart
├── config/       # Configuração e variáveis de ambiente do Supabase
├── data/         # Dados de demonstração, como os perfis de amigos
├── models/       # Modelos de jogos, usuários e itens da biblioteca
├── navigation/   # Rotas e identificação das páginas do aplicativo
├── screens/      # Telas de login, cadastro, catálogo, biblioteca e perfil
├── services/     # Acesso a dados, regras e persistência local
├── theme/        # Cores e elementos visuais do tema
├── utils/        # Funções utilitárias
└── widgets/      # Componentes reutilizáveis da interface
```

## Aprendizados do grupo

**Banco de dados:** O principal ponto que aprendemos foi a utilizar o supabase para hospedar o nosso banco de dados, ele facilita muito tanto a gestão quanto a criação dos dados

**Persistência de dados:** Também aprendemos a criar a persistência de dados entre contas para realização do projeto em flutter

## Telas do APP
<table>
  <tr>
    <th>Login</th>
    <th>Catálogo</th>
    <th>Amigos</th>
    <th>Biblioteca</th>
    <th>Configurações</th>
  </tr>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/af12ff1f-3df8-47b5-8fba-a62b10251d83" width="180">
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/5c2f4c70-ddc1-4c7d-a3ed-104c78086588" width="180">
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/d9e6b88a-0360-4fba-8b58-101817cb3c95" width="180">
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/7f362d5a-3267-4e71-b167-8e0dbf2ada92" width="180">
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/3fe744fd-d151-4e3e-8a05-27704f042778" width="180">
    </td>
  </tr>
</table>

