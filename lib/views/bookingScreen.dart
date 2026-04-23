import 'package:flutter/material.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Book a Card')),
      body: const Center(
        child: Text('Booking screen coming soon',
            style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
