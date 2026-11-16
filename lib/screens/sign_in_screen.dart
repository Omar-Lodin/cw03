import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart' as auth_service;

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});
  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmedPasswordController = TextEditingController();
  bool _isRegistering = false;
  String? _authError;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmedPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _authError = null);
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    try {
      if (_isRegistering) {
        await auth_service.register(email, password);
      } else {
        await auth_service.signIn(email, password);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth code: "${e.code}"');
      if (!mounted) return;
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _authError = 'Email is already in use. Please sign in.';
            break;
          case 'user-not-found':
            _authError = 'No user found for that email. Please register.';
            break;
          case 'invalid-email':
            _authError = 'Invalid email format. Please check and try again.';
            break;
          case 'network-request-failed':
            _authError = 'Network error. Please check your connection.';
            break;
          case 'invalid-credentials':
            _authError =
                'Invalid credentials. Please check your email and password.';
            break;
          case 'wrong-password':
            _authError = 'Incorrect password. Please try again.';
            break;
          case 'weak-password':
            _authError = 'Weak password. Please use at least 6 characters.';
          default:
            _authError =
                'Incorrect email/password combination. Please try again.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isRegistering ? 'Register' : 'Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) {
                  if (_authError != null) {
                    setState(() => _authError = null);
                  }
                },
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
                    return 'Enter a valid email address with the format "user@domain.com"';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                controller: _passwordController,
                obscureText: true,
                onChanged: (_) {
                  if (_authError != null) {
                    setState(() => _authError = null);
                  }
                },
                validator: (value) {
                  final password = value?.trim() ?? '';
                  if (password.isEmpty) {
                    return 'Password is required';
                  }
                  if (_isRegistering && password.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              if (_isRegistering)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                  ),
                  controller: _confirmedPasswordController,
                  obscureText: true,
                  validator: (value) {
                    final confirmedPassword = value?.trim() ?? '';
                    if (confirmedPassword.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (confirmedPassword != _passwordController.text.trim()) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ElevatedButton(onPressed: _submit, child: const Text('Continue')),
              if (_authError != null)
                Text(_authError!, style: const TextStyle(color: Colors.red)),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isRegistering = !_isRegistering;
                    _authError = null;
                    _passwordController.clear();
                    _confirmedPasswordController.clear();
                    _formKey.currentState?.reset();
                    // Clear error when switching modes
                  });
                },
                child: Text(
                  _isRegistering
                      ? 'Already have an account? Sign In'
                      : 'Don\'t have an account? Register',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
