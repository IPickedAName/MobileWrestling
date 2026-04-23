import 'package:flutter/material.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Stats')),
      body: const Center(
        child: Text('Stats screen coming soon',
            style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
