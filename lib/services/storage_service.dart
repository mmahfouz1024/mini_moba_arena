import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/moba_models.dart';

class StorageService {
  static const String _key = 'mini_moba_profile_v1';

  Future<PlayerMetaProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return PlayerMetaProfile();
    try {
      return PlayerMetaProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return PlayerMetaProfile();
    }
  }

  Future<void> saveProfile(PlayerMetaProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }
}
