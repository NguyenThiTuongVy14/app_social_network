import 'package:flutter/material.dart';
import '../models/auth_model.dart';
import '../screens/login_screen.dart';

class RegisterController {
  final AuthModel authModel;
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;

  RegisterController({required this.authModel});

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
  }

  Future<void> register(BuildContext context) async {
    final fullName = fullNameController.text;
    final email = emailController.text;
    final password = passwordController.text;

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    isLoading = true;
    final result = await authModel.register(fullName, email, password);
    isLoading = false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );

    if (result['success']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
  }
}