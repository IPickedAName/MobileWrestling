import 'dart:convert';
import 'package:flutter/services.dart';
import 'wrestler.dart';

class WrestlerService {
  static Future<List<Wrestler>> loadWrestlers() async {
    final String jsonString =
        await rootBundle.loadString('assets/wrestlers.json');

    final List<dynamic> jsonData = json.decode(jsonString);

    return jsonData.map((item) => Wrestler.fromJson(item)).toList();
  }
}