import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> uploadWrestlersFromJson() async {
    final String jsonString =
        await rootBundle.loadString('assets/wrestlers.json');
    final List<dynamic> jsonData = json.decode(jsonString);

    final batch = _db.batch();

    for (final wrestler in jsonData) {
      final docRef = _db.collection('wrestlers').doc(wrestler['name']);
      batch.set(docRef, wrestler);
    }

    await batch.commit();
  }
}