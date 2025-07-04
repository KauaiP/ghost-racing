import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final UserService _userService = UserService();

  void _handleLogin() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) return;

    await _userService.saveUser(name, email);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFA9C8D4),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 50),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'GhostStride',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF702C50),
                  ),
                ),
                const SizedBox(height: 20),
                Image.asset('lib/assets/ghost_login.png', width: 120),
                const SizedBox(height: 30),
                const Text(
                  'Crie sua conta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF702C50),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'entre com seu nome e seu email',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Digite seu nome',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Digite seu email',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF702C50),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text('Entrar'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
