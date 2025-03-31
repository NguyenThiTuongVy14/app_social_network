import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:social_network/screens/MainScreen.dart';
import 'screens/home.dart';
import 'screens/login_screen.dart';
import 'theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isUserLoggedIn = await isLoggedIn();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(isUserLoggedIn: isUserLoggedIn),
    ),
  );
}

Future<bool> isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  return token != null && token.isNotEmpty;
}

class MyApp extends StatelessWidget {
  final bool isUserLoggedIn;
  const MyApp({super.key, required this.isUserLoggedIn});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: isUserLoggedIn ? const MainScreen() : const LoginScreen(),
    );
  }
}
