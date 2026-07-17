import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController(text: '1234'); // Test OTP prefill
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pinController.text.trim() != '1234') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP code! Try 1234')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '[]';
    final users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));

    bool updated = false;
    for (int i = 0; i < users.length; i++) {
      if (users[i]['user'] != null && users[i]['user']['email'] == widget.email) {
        users[i]['user']['password'] = _newPassController.text;
        users[i]['user']['updatedAt'] = DateTime.now().toIso8601String();
        updated = true;
        break;
      } else if (users[i]['email'] == widget.email) {
        users[i]['password'] = _newPassController.text;
        updated = true;
        break;
      }
    }

    if (updated) {
      await prefs.setString('users', jsonEncode(users));
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset successfully! Please login.')),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify & Reset')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Enter OTP sent to:\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 4,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 8),
                    decoration: const InputDecoration(
                      labelText: '4-Digit OTP Code',
                      counterText: '',
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Enter OTP' : null,
                  ),
                  const SizedBox(height: 8),
                  Text('💡 Hint: Enter 1234 to verify', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _newPassController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPassController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) => v != _newPassController.text ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Reset Password'),
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
