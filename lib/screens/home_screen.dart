import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/ghost_storage_service.dart';
import './map_screen.dart';
import './ghost_selection_screen.dart'; // Nova tela que você criará

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Visitante';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final name = await UserService().getUserName();
    setState(() {
      _userName = name?.isNotEmpty == true ? name! : 'Visitante';
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFB3CDD1),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF87AFC9),
          elevation: 0,
          title: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Bem-vindo, $_userName!',
              style: const TextStyle(
                color: Color(0xFF702C50),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(text: 'Histórico'),
              Tab(text: 'Nova Corrida'),
              Tab(text: 'Desempenho'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            HistoricoScreen(),
            NovaCorridaScreen(),
            DesempenhoScreen(),
          ],
        ),
      ),
    );
  }
}

class NovaCorridaScreen extends StatelessWidget {
  const NovaCorridaScreen({super.key});

  Future<void> _handleStart(BuildContext context) async {
    final ghosts = await GhostStorageService().getAllGhosts();
    if (ghosts.isEmpty) {
      // Nenhum fantasma, começa corrida normal
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MapScreen()),
      );
    } else {
      // Existem fantasmas, ir para a seleção
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GhostSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFB3CDD1),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Image.asset(
            'lib/assets/ghost_home.png',
            height: 100,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _handleStart(context),
            icon: const Icon(Icons.directions_run),
            label: const Text('Iniciar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF85324C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
            ),
          ),
          const SizedBox(height: 30),
          const Dica(text: 'Não esqueça de se alongar!'),
          const Dica(text: 'Esteja hidratado!'),
          const Dica(text: 'Escolha uma rota segura!'),
          const Dica(text: 'Use tênis adequado e confortável!'),
        ],
      ),
    );
  }
}

class Dica extends StatelessWidget {
  final String text;
  const Dica({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check, size: 20, color: Color(0xFF85324C)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF85324C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoricoScreen extends StatelessWidget {
  const HistoricoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFFB3CDD1));
  }
}

class DesempenhoScreen extends StatelessWidget {
  const DesempenhoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFFB3CDD1));
  }
}
