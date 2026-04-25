import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

class FirestoreService {
  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  String? get currentUserId => _auth?.currentUser?.uid;

  Future<void> uploadWrestlersFromJson() async {
    final db = _db;
    if (db == null) return;

    final String jsonString =
        await rootBundle.loadString('assets/wrestlers.json');

    final List<dynamic> jsonData = json.decode(jsonString);

    final batch = db.batch();

    for (final wrestler in jsonData) {
      final docRef = db.collection('wrestlers').doc(wrestler['name']);
      batch.set(docRef, wrestler);
    }

    await batch.commit();
  }

  Future<void> createUserProfileIfMissing({
    required String uid,
    required String email,
  }) async {
    final db = _db;
    if (db == null) return;

    final userRef = db.collection('users').doc(uid);
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
    final db = _db;
    if (uid == null || db == null) return null;

    final doc = await db.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> updateProfile({
    required String name,
    required String bio,
    String profilePicUrl = '',
  }) async {
    final uid = currentUserId;
    final db = _db;
    if (uid == null || db == null) return;

    await db.collection('users').doc(uid).set({
      'name': name,
      'bio': bio,
      'profilePicUrl': profilePicUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getCurrentStats() async {
    final uid = currentUserId;
    final db = _db;
    if (uid == null || db == null) return null;

    final doc = await db
        .collection('users')
        .doc(uid)
        .collection('stats')
        .doc('current')
        .get();

    return doc.data();
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final uid = currentUserId;
    final db = _db;
    if (uid == null || db == null) return [];

    final snapshot = await db
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
    final db = _db;
    if (uid == null || db == null) return;

    final userRef = db.collection('users').doc(uid);
    final statsRef = userRef.collection('stats').doc('current');
    final weekRef = userRef.collection('weeks').doc('week_$weekNumber');

    final bool playerWon = playerPoints >= aiPoints;
    bool needsBestRatingRecalc = false;

    await db.runTransaction((transaction) async {
      final statsSnap = await transaction.get(statsRef);
      final weekSnap = await transaction.get(weekRef);

      final oldStats = statsSnap.data() ?? {};
      final oldWeek = weekSnap.data();
      final double oldBestRating =
          ((oldStats['bestRating'] ?? 0.0) as num).toDouble();

      int oldTotalPoints = oldStats['totalPoints'] ?? 0;
      int oldWins = oldStats['wins'] ?? 0;
      int oldLosses = oldStats['losses'] ?? 0;
      int oldWeeksPlayed = oldStats['weeksPlayed'] ?? 0;
      double? previousRating;

      double oldAverageRating =
          ((oldStats['averageRating'] ?? 0.0) as num).toDouble();

      if (oldWeek != null) {
        final int previousPoints = oldWeek['playerPoints'] ?? 0;
        final int previousAiPoints = oldWeek['aiPoints'] ?? 0;
        final bool previousWon = previousPoints >= previousAiPoints;
        previousRating =
            ((oldWeek['avgRating'] ?? 0.0) as num).toDouble();

        oldTotalPoints -= previousPoints;

        if (previousWon) {
          oldWins -= 1;
        } else {
          oldLosses -= 1;
        }

        if (oldWeeksPlayed > 1) {
          oldAverageRating =
              ((oldAverageRating * oldWeeksPlayed) - previousRating) /
                  (oldWeeksPlayed - 1);
        } else {
          oldAverageRating = 0.0;
        }

        oldWeeksPlayed -= 1;
      }

      final int newWeeksPlayed = oldWeeksPlayed + 1;
      final int newTotalPoints = oldTotalPoints + playerPoints;
      final int newWins = oldWins + (playerWon ? 1 : 0);
      final int newLosses = oldLosses + (playerWon ? 0 : 1);

      final double newAverageRating =
          ((oldAverageRating * oldWeeksPlayed) + avgRating) / newWeeksPlayed;
      double bestRating = avgRating > oldBestRating ? avgRating : oldBestRating;

      if (oldWeek != null &&
          previousRating != null &&
          previousRating >= oldBestRating &&
          avgRating < oldBestRating) {
        // The overwritten week held the previous best rating, and new rating is lower.
        // Defer best-rating recompute with a cheap top-1 query after transaction.
        needsBestRatingRecalc = true;
      }

      transaction.set(weekRef, {
        'weekNumber': weekNumber,
        'playerPoints': playerPoints,
        'aiPoints': aiPoints,
        'avgRating': avgRating,
        'result': playerWon ? 'W' : 'L',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(statsRef, {
        'totalPoints': newTotalPoints,
        'wins': newWins,
        'losses': newLosses,
        'weeksPlayed': newWeeksPlayed,
        'bestRating': bestRating,
        'averageRating': newAverageRating,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    if (needsBestRatingRecalc) {
      final topWeekSnap = await userRef
          .collection('weeks')
          .orderBy('avgRating', descending: true)
          .limit(1)
          .get();

      final double recalculatedBest = topWeekSnap.docs.isEmpty
          ? 0.0
          : ((topWeekSnap.docs.first.data()['avgRating'] ?? 0.0) as num)
              .toDouble();

      await statsRef.set({
        'bestRating': recalculatedBest,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}