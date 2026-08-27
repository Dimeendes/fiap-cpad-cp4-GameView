import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _recuperarSenha() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    final emailSalvo = prefs.getString('email');
    final emailDigitado = _emailController.text.trim();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (emailSalvo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nenhuma conta cadastrada.',
          ),
        ),
      );
      return;
    }

    if (emailDigitado.toLowerCase() != emailSalvo.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'E-mail não cadastrado.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Solicitação de recuperação realizada!',
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
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
                        child: Icon(
                          Icons.lock_reset_outlined,
                          size: 55,
                          color: AppColors.blue,
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Center(
                        child: Text(
                          'Recuperar senha',
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
                          'Digite seu e-mail para recuperar o acesso à sua conta.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF777777),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

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
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Digite seu e-mail';
                          }

                          if (!value.contains('@') ||
                              !value.contains('.')) {
                            return 'Digite um e-mail válido';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 28),

                      CustomButton(
                        text: _isLoading
                            ? 'VERIFICANDO...'
                            : 'RECUPERAR SENHA',
                        onPressed:
                            _isLoading ? () {} : _recuperarSenha,
                      ),

                      const SizedBox(height: 15),

                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Voltar para o login',
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