import 'package:flutter/material.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController emailController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFF9EC1CC), // fundo azul da tela
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'GhostStride',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5C1B3C), // roxo escuro (título)
              ),
            ),
            const SizedBox(height: 20),
            Image.asset('lib/assets/ghost_login.png', height: 120),
            const SizedBox(height: 20),
            const Text(
              'Crie sua conta',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5C1B3C), // mesmo roxo escuro
              ),
            ),
            const Text(
              'entre com seu nome e seu email',
              style: TextStyle(color: Color(0xFF9B4B7C)), // roxo médio (descrição)
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Digite seu nome',
                filled: true,
                fillColor: const Color(0xFFEDE3DB), // bege claro nos campos
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'Digite seu email',
                filled: true,
                fillColor: const Color(0xFFEDE3DB), // bege claro
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C1B3C), // botão roxo escuro
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                shadowColor: Colors.black54,
                elevation: 4,
              ),
              child: const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}
