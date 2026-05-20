// screens/auth_screen.dart

import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AuthScreen extends StatefulWidget {
  final Function(String email) onLogin;

  const AuthScreen({
    super.key,
    required this.onLogin,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isSignUp = false;
  bool isLoading = false;
  String? errorMessage;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  void _showResetHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset is not available yet.'),
      ),
    );
  }

  Future<void> handleSubmit() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() {
        errorMessage = 'Please fill in all fields';
      });
      return;
    }

    if (isSignUp && confirmPasswordController.text.isEmpty) {
      setState(() {
        errorMessage = 'Please confirm your password';
      });
      return;
    }

    if (isSignUp && passwordController.text != confirmPasswordController.text) {
      setState(() {
        errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (isSignUp) {
        await _firebaseService.signUp(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
      } else {
        await _firebaseService.signIn(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
      }
      widget.onLogin(emailController.text.trim());
    } catch (e) {
      setState(() {
        errorMessage = e.toString().split(']').last.trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 40),

                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF4ADE80),
                        Color(0xFF059669),
                      ],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  child: const Icon(
                    Icons.apple,
                    size: 50,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                if (!isSignUp)
                  const Text(
                    'NomNomTracker',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  const Text(
                    'Create your account',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                const SizedBox(height: 8),

                if (!isSignUp)
                  const Text(
                    'Track your nutrition journey',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  )
                else
                  const Text(
                    'Start tracking meals in minutes',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                const SizedBox(height: 40),

                if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'your@email.com',
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    labelText: isSignUp ? 'Create Password' : 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                if (!isSignUp)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showResetHint,
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(color: Color(0xFF10B981)),
                      ),
                    ),
                  ),

                if (isSignUp) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      labelText: 'Verify Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],

                if (isSignUp)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Use at least 6 characters',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isSignUp ? 'Create Account' : 'Sign In',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    setState(() {
                      isSignUp = !isSignUp;
                      errorMessage = null;
                    });
                  },
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black87),
                      children: [
                        TextSpan(
                          text: isSignUp
                              ? 'Already have an account? '
                              : "Don't have an account? ",
                        ),
                        TextSpan(
                          text: isSignUp ? 'Sign In' : 'Sign Up',
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  'By continuing, you agree to our Terms & Privacy Policy',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}