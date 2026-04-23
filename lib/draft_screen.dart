import 'package:flutter/material.dart';
import 'wrestler.dart';
import 'wrestlerService.dart';

class DraftScreen extends StatefulWidget {
  const DraftScreen({super.key});

  @override
  State<DraftScreen> createState() => _DraftScreenState();
}

class _DraftScreenState extends State<DraftScreen> {
  List<Wrestler> wrestlers = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final loadedWrestlers = await WrestlerService.loadWrestlers();
      setState(() {
        wrestlers = loadedWrestlers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load wrestlers';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draft Screen'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : ListView.builder(
                  itemCount: wrestlers.length,
                  itemBuilder: (context, index) {
                    final wrestler = wrestlers[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(wrestler.name),
                        subtitle: Text(
                          '${wrestler.promotion} | ${wrestler.wrestlerClass} | POP ${wrestler.popularity}',
                        ),
                        trailing: Text('\$${wrestler.salary}k'),
                      ),
                    );
                  },
                ),
    );
  }
}