import 'package:flutter/material.dart';

import '../navigation/app_navigator.dart';
import '../theme/app_colors.dart';
import '../widgets/app_page_header.dart';

class FriendListScreen extends StatelessWidget {
  const FriendListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.gradient),
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                children: [
                  AppPageHeader(
                    title: 'Amigos',
                    subtitle:
                        'Em breve você poderá ver avaliações da galera.',
                    onOpenProfile: () => AppNavigator.openProfile(context),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.group_outlined,
                          color: AppColors.blue,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'A lista de amigos ainda está em desenvolvimento.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF222222),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
