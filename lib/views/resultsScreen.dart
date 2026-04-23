import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Results')),
      body: const Center(
        child: Text('Results screen coming soon',
            style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
