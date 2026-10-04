import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';

import '../navigation/app_navigator.dart';
import '../theme/app_colors.dart';
import '../widgets/app_page_header.dart';
import '../widgets/custom_text_field.dart';

class ConfigsScreen extends StatefulWidget {
  const ConfigsScreen({super.key});

  @override
  State<ConfigsScreen> createState() => _ConfigsScreenState();
}

class _ConfigsScreenState extends State<ConfigsScreen> {
  bool senhaAtualVisivel = false;
  bool novaSenhaVisivel = false;
  bool confirmarSenhaVisivel = false;

  Future<void> alterarNome() async {
    final prefs = await SharedPreferences.getInstance();
    final nomeSalvo = prefs.getString('nome') ?? '';

    final nomeController = TextEditingController(text: nomeSalvo);

    String? erro;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Alterar nome'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: nomeController,
                    hintText: 'Digite seu novo nome',
                    icon: Icons.person_outline,
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      erro!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nomeController.text.trim().isEmpty) {
                      setStateDialog(() {
                        erro = 'Digite um nome.';
                      });
                      return;
                    }

                    await prefs.setString(
                      'nome',
                      nomeController.text.trim(),
                    );

                    if (!mounted) return;

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nome alterado com sucesso!'),
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> alterarEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final emailSalvo = prefs.getString('email') ?? '';

    final emailController = TextEditingController(text: emailSalvo);

    String? erro;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Alterar e-mail'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: emailController,
                    hintText: 'Digite seu novo e-mail',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      erro!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final novoEmail = emailController.text.trim();

                    if (novoEmail.isEmpty) {
                      setStateDialog(() {
                        erro = 'Digite um e-mail.';
                      });
                      return;
                    }

                    if (!novoEmail.contains('@') ||
                        !novoEmail.contains('.')) {
                      setStateDialog(() {
                        erro = 'Digite um e-mail válido.';
                      });
                      return;
                    }

                    await prefs.setString('email', novoEmail);

                    if (!mounted) return;

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('E-mail alterado com sucesso!'),
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> alterarSenha() async {
    final prefs = await SharedPreferences.getInstance();

    final senhaAtualController = TextEditingController();
    final novaSenhaController = TextEditingController();
    final confirmarSenhaController = TextEditingController();

    String? erro;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Alterar senha'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      controller: senhaAtualController,
                      hintText: 'Senha atual',
                      icon: Icons.lock_outline,
                      obscureText: !senhaAtualVisivel,
                      suffixIcon: IconButton(
                        icon: Icon(
                          senhaAtualVisivel
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            senhaAtualVisivel = !senhaAtualVisivel;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: novaSenhaController,
                      hintText: 'Nova senha',
                      icon: Icons.lock_outline,
                      obscureText: !novaSenhaVisivel,
                      suffixIcon: IconButton(
                        icon: Icon(
                          novaSenhaVisivel
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            novaSenhaVisivel = !novaSenhaVisivel;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: confirmarSenhaController,
                      hintText: 'Confirme a nova senha',
                      icon: Icons.lock_outline,
                      obscureText: !confirmarSenhaVisivel,
                      suffixIcon: IconButton(
                        icon: Icon(
                          confirmarSenhaVisivel
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            confirmarSenhaVisivel =
                                !confirmarSenhaVisivel;
                          });
                        },
                      ),
                    ),
                    if (erro != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        erro!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (senhaAtualController.text.isEmpty ||
                        novaSenhaController.text.isEmpty ||
                        confirmarSenhaController.text.isEmpty) {
                      setStateDialog(() {
                        erro = 'Preencha todos os campos.';
                      });
                      return;
                    }

                    if (novaSenhaController.text.length < 6) {
                      setStateDialog(() {
                        erro =
                            'A nova senha deve ter pelo menos 6 caracteres.';
                      });
                      return;
                    }

                    if (novaSenhaController.text !=
                        confirmarSenhaController.text) {
                      setStateDialog(() {
                        erro = 'As senhas não coincidem.';
                      });
                      return;
                    }

                    final senhaSalva = prefs.getString('senha') ?? '';

                    if (senhaAtualController.text != senhaSalva) {
                      setStateDialog(() {
                        erro = 'Senha atual incorreta.';
                      });
                      return;
                    }

                    await prefs.setString(
                      'senha',
                      novaSenhaController.text,
                    );

                    if (!mounted) return;

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Senha alterada com sucesso!'),
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void sobre() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sobre o GameView'),
          content: const Text(
            'Aplicativo para descobrir, pesquisar e avaliar jogos.\n\n'
            'Versão 1.0.0',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void sairDaConta() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sair da conta'),
          content: const Text(
            'Tem certeza que deseja sair da conta?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }

  Widget opcao({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF7F8FC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icone,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Color(0xFF222222),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF999999),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.gradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1100,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  32,
                ),
                children: [
                  AppPageHeader(
                    title: 'Configuração',
                    subtitle:
                        'Gerencie sua conta e suas informações no GameView.',
                    onOpenProfile: () =>
                        AppNavigator.openProfile(context),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Icon(
                            Icons.settings_outlined,
                            color: AppColors.blue,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            'Configurações',
                            style: TextStyle(
                              color: Color(0xFF222222),
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            'Gerencie suas informações da conta',
                            style: TextStyle(
                              color: Color(0xFF777777),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Conta',
                          style: TextStyle(
                            color: Color(0xFF222222),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        opcao(
                          icone: Icons.person_outline,
                          titulo: 'Alterar nome',
                          subtitulo:
                              'Atualize seu nome de usuário',
                          onTap: alterarNome,
                        ),
                        const SizedBox(height: 10),
                        opcao(
                          icone: Icons.email_outlined,
                          titulo: 'Alterar e-mail',
                          subtitulo:
                              'Atualize seu e-mail de acesso',
                          onTap: alterarEmail,
                        ),
                        const SizedBox(height: 10),
                        opcao(
                          icone: Icons.lock_outline,
                          titulo: 'Alterar senha',
                          subtitulo:
                              'Atualize sua senha de acesso',
                          onTap: alterarSenha,
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Informações',
                          style: TextStyle(
                            color: Color(0xFF222222),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        opcao(
                          icone: Icons.info_outline,
                          titulo: 'Sobre',
                          subtitulo:
                              'Informações sobre o GameView',
                          onTap: sobre,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: sairDaConta,
                            icon: const Icon(Icons.logout),
                            label: const Text('Sair da conta'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.blue,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}