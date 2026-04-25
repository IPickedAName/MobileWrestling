import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

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

  Future<void> createUserProfileIfMissing({
    required String uid,
    required String email,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        'email': email,
        'name': 'New Booker',
        'bio': 'Tap edit to add your bio.',
        'profilePicUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await userRef.collection('stats').doc('current').set({
        'totalPoints': 0,
        'wins': 0,
        'losses': 0,
        'weeksPlayed': 0,
        'bestRating': 0.0,
        'averageRating': 0.0,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;

    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> updateProfile({
    required String name,
    required String bio,
    String profilePicUrl = '',
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _db.collection('users').doc(uid).set({
      'name': name,
      'bio': bio,
      'profilePicUrl': profilePicUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getCurrentStats() async {
    final uid = currentUserId;
    if (uid == null) return null;

    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('stats')
        .doc('current')
        .get();

    return doc.data();
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('weeks')
        .orderBy('weekNumber')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> recordWeeklyStats({
    required int weekNumber,
    required int playerPoints,
    required int aiPoints,
    required double avgRating,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    final userRef = _db.collection('users').doc(uid);
    final statsRef = userRef.collection('stats').doc('current');
    final weekRef = userRef.collection('weeks').doc('week_$weekNumber');

    final bool playerWon = playerPoints >= aiPoints;

    await _db.runTransaction((transaction) async {
      final statsSnap = await transaction.get(statsRef);
      final oldStats = statsSnap.data() ?? {};

      final int oldTotalPoints = oldStats['totalPoints'] ?? 0;
      final int oldWins = oldStats['wins'] ?? 0;
      final int oldLosses = oldStats['losses'] ?? 0;
      final int oldWeeksPlayed = oldStats['weeksPlayed'] ?? 0;
      final double oldBestRating =
          ((oldStats['bestRating'] ?? 0.0) as num).toDouble();
      final double oldAverageRating =
          ((oldStats['averageRating'] ?? 0.0) as num).toDouble();

      final int newWeeksPlayed = oldWeeksPlayed + 1;
      final int newTotalPoints = oldTotalPoints + playerPoints;
      final int newWins = oldWins + (playerWon ? 1 : 0);
      final int newLosses = oldLosses + (playerWon ? 0 : 1);
      final double newBestRating =
          avgRating > oldBestRating ? avgRating : oldBestRating;

      final double newAverageRating =
          ((oldAverageRating * oldWeeksPlayed) + avgRating) / newWeeksPlayed;

      transaction.set(weekRef, {
        'weekNumber': weekNumber,
        'playerPoints': playerPoints,
        'aiPoints': aiPoints,
        'avgRating': avgRating,
        'result': playerWon ? 'W' : 'L',
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(statsRef, {
        'totalPoints': newTotalPoints,
        'wins': newWins,
        'losses': newLosses,
        'weeksPlayed': newWeeksPlayed,
        'bestRating': newBestRating,
        'averageRating': newAverageRating,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}