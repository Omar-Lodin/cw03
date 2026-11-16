import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'screens/sign_in_screen.dart';
import 'screens/challenge_screen.dart';
import 'services/reward_service.dart';

class CloudQuestApp extends StatelessWidget {
  const CloudQuestApp({super.key});

  Future<void> onComplete(BuildContext context) async {
    final String message;

    try {
      final result = await completeChallenge();

      message = result['alreadyCompleted'] == true
          ? 'You already completed this challenge.'
          : 'Earned ${result['points']} points! Badge: ${result['badgeId']}';
    } catch (error, stackTrace) {
      debugPrint('Error completing challenge: $error');
      debugPrint('Stack trace: $stackTrace');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not complete the challenge. Try again.'),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          return user == null
              ? const AuthenticationScreen()
              : ChallengeScreen(user: user, onComplete: () => onComplete(context));
        },
      ),
    );
  }
}
