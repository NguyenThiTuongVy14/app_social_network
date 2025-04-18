import 'package:flutter/material.dart';
import '../models/auth_model.dart';
import '../screens/MainScreen.dart';

class LoginController {
  final AuthModel authModel;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;

  LoginController({required this.authModel});

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
  }

  Future<void> login(BuildContext context) async {
    final email = emailController.text;
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    isLoading = true;
    // Gọi hàm login từ model
    final result = await authModel.login(email, password);

    isLoading = false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );

    if (result['success']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}