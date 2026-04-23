import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/wrestler.dart';

class WrestlerService {
  static List<Wrestler> _pool = [];

  static Future<List<Wrestler>> loadWrestlers() async {
    final String data = await rootBundle.loadString('assets/wrestlers.json');
    final List<dynamic> jsonList = json.decode(data);
    _pool = jsonList.map((j) => Wrestler.fromJson(j)).toList();
    return _pool;
  }

  static List<Wrestler> get pool => _pool;
}