import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _criarConta() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    final nome = _nameController.text.trim();
    final email = _emailController.text.trim();
    final senha = _passwordController.text;

    // Verifica se já existe uma conta com esse e-mail.
    final emailExistente = prefs.getString('email');

    if (!mounted) return;

    if (emailExistente != null &&
        emailExistente.toLowerCase() == email.toLowerCase()) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este e-mail já está cadastrado.',
          ),
        ),
      );

      return;
    }

    // Salva os dados da conta.
    await prefs.setString('nome', nome);
    await prefs.setString('email', email);
    await prefs.setString('senha', senha);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Conta criada com sucesso! 🎮',
        ),
      ),
    );

    // Volta para a tela de Login.
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.gradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                ),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.blue,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Center(
                        child: Text(
                          'Criar uma conta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Center(
                        child: Text(
                          'Entre para fazer parte do GameView',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF777777),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'Nome',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      CustomTextField(
                        controller: _nameController,
                        hintText: 'Digite seu nome',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Digite seu nome';
                          }

                          if (value.trim().length < 2) {
                            return 'Digite um nome válido';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'E-mail',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      CustomTextField(
                        controller: _emailController,
                        hintText: 'Digite seu e-mail',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Digite seu e-mail';
                          }

                          if (!value.contains('@') ||
                              !value.contains('.')) {
                            return 'Digite um e-mail válido';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Senha',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      CustomTextField(
                        controller: _passwordController,
                        hintText: 'Digite sua senha',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Digite uma senha';
                          }

                          if (value.length < 6) {
                            return 'A senha deve ter pelo menos 6 caracteres';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Confirmar senha',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      CustomTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Digite a senha novamente',
                        icon: Icons.lock_outline,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirme sua senha';
                          }

                          if (value != _passwordController.text) {
                            return 'As senhas não coincidem';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 28),

                      CustomButton(
                        text: _isLoading
                            ? 'CRIANDO...'
                            : 'CRIAR CONTA',
                        onPressed: _isLoading ? () {} : _criarConta,
                      ),

                      const SizedBox(height: 15),

                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Já tenho uma conta',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}