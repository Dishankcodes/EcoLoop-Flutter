import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static final Prefs _instance = Prefs._internal();

  factory Prefs() => _instance;

  Prefs._internal();

  static SharedPreferences? _preferences;

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _prefs {
    if (_preferences == null) {
      throw Exception("Prefs not initialized. Call Prefs.init() in main().");
    }
    return _preferences!;
  }

  // --- String ---
  static Future<bool> setString(String key, String value) async =>
      await _prefs.setString(key, value);

  static String getString(String key, {String defaultValue = ''}) =>
      _prefs.getString(key) ?? defaultValue;

  // --- Bool ---
  static Future<bool> setBool(String key, bool value) async =>
      await _prefs.setBool(key, value);

  static bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;

  // --- Int ---
  static Future<bool> setInt(String key, int value) async =>
      await _prefs.setInt(key, value);

  static int getInt(String key, {int defaultValue = 0}) =>
      _prefs.getInt(key) ?? defaultValue;

  // --- Double ---
  static Future<bool> setDouble(String key, double value) async =>
      await _prefs.setDouble(key, value);

  static double getDouble(String key, {double defaultValue = 0.0}) =>
      _prefs.getDouble(key) ?? defaultValue;

  // --- List<String> ---
  static Future<bool> setStringList(String key, List<String> value) async =>
      await _prefs.setStringList(key, value);

  static List<String> getStringList(String key, {List<String>? defaultValue}) =>
      _prefs.getStringList(key) ?? defaultValue ?? [];

  // --- Objects / JSON ---
  static Future<bool> setObject(
    String key,
    Map<String, dynamic> jsonMap,
  ) async {
    return await _prefs.setString(key, jsonEncode(jsonMap));
  }

  static T? getObject<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  // --- Utilities ---
  static bool containsKey(String key) => _prefs.containsKey(key);

  static Future<bool> remove(String key) async => await _prefs.remove(key);

  static Future<bool> clear() async => await _prefs.clear();
}
