import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../services/coach_service.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({
    super.key,
    required this.user,
    required this.onComplete,
  });
  final User user;
  final VoidCallback onComplete;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  final _questionController = TextEditingController();
  bool _isHintRequested = false;
  String? _reply;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _getHint() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      setState(() => _reply = 'Please enter a question to get a hint.');
      return;
    }

    setState(() {
      _isHintRequested = true;
      _reply = null;
    });
    try {
      final reply = await getQuestHint(question);
      if (!mounted) return;
      setState(() {
        _reply = reply;
      });
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Quest Coach Request failed');
      if (!mounted) return;
      setState(() => _reply = 'Quest Coach not available. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isHintRequested = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cloud Quest')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Signed in as ${widget.user.email ?? widget.user.uid}'),
        TextButton(onPressed: logOut, child: const Text('Sign out')),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .doc('challenges/today')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Error loading challenge data.');
            }
            final document = snapshot.data;
            if (document == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final challenge = document.data();
            if (challenge == null) {
              return const Text('No challenge data available.');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.data()?['title'] as String? ?? 'Today\'s Challenge',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(challenge['prompt'] as String? ?? 'No prompt available.'),
              ],
            );
          },
        ),
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .doc('users/${widget.user.uid}/progress/today')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Error loading user data.');
            }
            final document = snapshot.data;
            if (document == null) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Loading user data...'),
                    SizedBox(height: 8),
                    CircularProgressIndicator(),
                  ],
                ),
              );
            }

            final userData = document.data();
            if (userData == null || userData['completed'] != true) {
              return const Text('No user data available.');
            }
            final points = userData['points'] ;
            final badgeId = userData['badgeId'] ?? 'No badge earned yet';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Points: $points'),
                Text('Badges: $badgeId'),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: widget.onComplete,
          child: const Text('Complete challenge'),
        ),
        TextField(
          controller: _questionController,
          maxLength: 300,
          decoration: InputDecoration(
            labelText: 'Ask the Quest Coach for a hint',
          ),
        ),
        OutlinedButton(
          onPressed: _isHintRequested ? null : _getHint,
          child: Text(_isHintRequested ? 'Getting insight...' : 'Get hint'),
        ),
        if (_reply != null) ...[
          const SizedBox(height: 8),
          Text(_reply!, style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
      ],
    ),
  );
}
