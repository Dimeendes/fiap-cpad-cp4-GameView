import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<SharedPreferences> _preferences =
      SharedPreferences.getInstance();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.gradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: FutureBuilder<SharedPreferences>(
                  future: _preferences,
                  builder: (context, snapshot) {
                    final preferences = snapshot.data;
                    final name = preferences?.getString('nome') ?? 'Usuário';
                    final email = preferences?.getString('email') ?? '';

                    return Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            tooltip: 'Voltar ao catálogo',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppColors.blue,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Center(
                            child: CircleAvatar(
                              radius: 42,
                              backgroundColor: Color(0xFFEAF2FF),
                              child: Icon(
                                Icons.person_outline,
                                color: AppColors.blue,
                                size: 44,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: Text(
                              snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? 'Carregando perfil...'
                                  : name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF222222),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'E-mail',
                            style: TextStyle(
                              color: Color(0xFF777777),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            email.isEmpty ? 'Nenhum e-mail cadastrado' : email,
                            style: const TextStyle(
                              color: Color(0xFF222222),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
