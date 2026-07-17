import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'login_page.dart';

class OtpVerificationPage extends StatefulWidget {
  final CompleteProfile profileToSave;

  const OtpVerificationPage({super.key, required this.profileToSave});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _pinController = TextEditingController(text: '1234'); // Pre-filled test code
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_pinController.text.trim() != '1234') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid verification code! Try 1234')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate API delay

    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '[]';
    final users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));

    // Save complete user + profile payload
    users.add(widget.profileToSave.toJson());
    await prefs.setString('users', jsonEncode(users));

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email verified! Registration successful.')),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.profileToSave.user.email;

    return Scaffold(
      appBar: AppBar(title: const Text('Email Verification')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_unread_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verify Your Email',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a 4-digit verification code to\n$email',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 4,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8),
                  decoration: const InputDecoration(
                    labelText: 'Verification Code',
                    hintText: '1234',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '💡 Hint: Enter 1234 to verify',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Verify & Continue'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification code resent to your email!')),
                    );
                  },
                  child: const Text('Resend Code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
