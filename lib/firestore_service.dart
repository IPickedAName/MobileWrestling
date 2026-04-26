import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import '../models/wrestler.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';



class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
  Future<String> uploadProfileImage(File imageFile) async {
  final uid = currentUserId;
  if (uid == null) return '';

  final fileName = DateTime.now().millisecondsSinceEpoch.toString();

  final ref = FirebaseStorage.instance
      .ref()
      .child('profile_pictures')
      .child(uid)
      .child('$fileName.jpg');

  final uploadTask = await ref.putFile(
    imageFile,
    SettableMetadata(contentType: 'image/jpeg'),
  );

  final url = await uploadTask.ref.getDownloadURL();

  await _db.collection('users').doc(uid).set({
    'profilePicUrl': url,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  return url;
}
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
        'activeSeasonId': '',
        'createdAt': FieldValue.serverTimestamp(),
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
    required String profilePicUrl,
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

  Future<String> createNewSeasonFromDraft({
    required String teamName,
    required List<Wrestler> roster,
  }) async {
    final uid = currentUserId;
    if (uid == null) return '';

    final userRef = _db.collection('users').doc(uid);
    final seasonRef = userRef.collection('seasons').doc();

    final rosterData = roster.map((w) {
      return {
        'name': w.name,
        'promotion': w.promotion,
        'role': w.role,
        'class': w.wrestlerClass,
        'inRing': w.inRing,
        'charisma': w.charisma,
        'promoSkill': w.promoSkill,
        'popularity': w.popularity,
        'morale': w.morale,
        'stamina': w.stamina,
        'currentStamina': w.currentStamina,
        'salary': w.salary,
        'contractWeeks': w.contractWeeks,
        'momentum': w.momentum,
        'championshipTitle': w.championshipTitle,
      };
    }).toList();

    await seasonRef.set({
      'teamName': teamName,
      'roster': rosterData,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });

    await seasonRef.collection('stats').doc('current').set({
      'totalPoints': 0,
      'wins': 0,
      'losses': 0,
      'weeksPlayed': 0,
      'bestRating': 0.0,
      'averageRating': 0.0,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    await userRef.set({
      'activeSeasonId': seasonRef.id,
    }, SetOptions(merge: true));

    return seasonRef.id;
  }

  Future<String?> getActiveSeasonId() async {
    final uid = currentUserId;
    if (uid == null) return null;

    final userDoc = await _db.collection('users').doc(uid).get();
    final data = userDoc.data();

    final activeSeasonId = data?['activeSeasonId'];

    if (activeSeasonId == null || activeSeasonId.toString().isEmpty) {
      return null;
    }

    return activeSeasonId.toString();
  }

  Future<List<Map<String, dynamic>>> getSeasons() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('seasons')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['seasonId'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> setActiveSeason(String seasonId) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _db.collection('users').doc(uid).set({
      'activeSeasonId': seasonId,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getCurrentStatsForSeason(
    String seasonId,
  ) async {
    final uid = currentUserId;
    if (uid == null) return null;

    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('seasons')
        .doc(seasonId)
        .collection('stats')
        .doc('current')
        .get();

    return doc.data();
  }

  Future<List<Map<String, dynamic>>> getWeeklyStatsForSeason(
    String seasonId,
  ) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('seasons')
        .doc(seasonId)
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

    final seasonId = await getActiveSeasonId();
    if (seasonId == null) return;

    final seasonRef =
        _db.collection('users').doc(uid).collection('seasons').doc(seasonId);

    final statsRef = seasonRef.collection('stats').doc('current');
    final weekRef = seasonRef.collection('weeks').doc('week_$weekNumber');

    final bool playerWon = playerPoints >= aiPoints;

    await _db.runTransaction((transaction) async {
      final statsSnap = await transaction.get(statsRef);
      final weekSnap = await transaction.get(weekRef);

      final oldStats = statsSnap.data() ?? {};
      final oldWeek = weekSnap.data();

      int totalPoints = _toInt(oldStats['totalPoints']);
      int wins = _toInt(oldStats['wins']);
      int losses = _toInt(oldStats['losses']);
      int weeksPlayed = _toInt(oldStats['weeksPlayed']);
      double averageRating = _toDouble(oldStats['averageRating']);
      double bestRating = _toDouble(oldStats['bestRating']);

      if (oldWeek != null) {
        final int oldPlayerPoints = _toInt(oldWeek['playerPoints']);
        final int oldAiPoints = _toInt(oldWeek['aiPoints']);
        final bool oldWon = oldPlayerPoints >= oldAiPoints;
        final double oldRating = _toDouble(oldWeek['avgRating']);

        totalPoints -= oldPlayerPoints;

        if (oldWon) {
          wins -= 1;
        } else {
          losses -= 1;
        }

        if (weeksPlayed > 1) {
          averageRating =
              ((averageRating * weeksPlayed) - oldRating) / (weeksPlayed - 1);
        } else {
          averageRating = 0.0;
        }

        weeksPlayed -= 1;
      }

      final int newWeeksPlayed = weeksPlayed + 1;
      final int newTotalPoints = totalPoints + playerPoints;
      final int newWins = wins + (playerWon ? 1 : 0);
      final int newLosses = losses + (playerWon ? 0 : 1);

      final double newAverageRating =
          ((averageRating * weeksPlayed) + avgRating) / newWeeksPlayed;

      if (avgRating > bestRating) {
        bestRating = avgRating;
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
  }
}