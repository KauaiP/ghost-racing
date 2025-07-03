import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1; // Começa na aba 'Nova Corrida'

  static final List<Widget> _screens = [
    const PlaceholderScreen(color: Colors.blue, title: 'Histórico'),
    const NovaCorridaScreen(),
    const PlaceholderScreen(color: Colors.blue, title: 'Desempenho'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GhostStride')),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Histórico'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Nova Corrida'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Desempenho'),
        ],
      ),
    );
  }
}

class NovaCorridaScreen extends StatelessWidget {
  const NovaCorridaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Nova Corrida', style: TextStyle(fontSize: 24)),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final Color color;
  final String title;

  const PlaceholderScreen({Key? key, required this.color, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(color: color, child: Center(child: Text(title, style: const TextStyle(fontSize: 24, color: Colors.white))));
  }
}
