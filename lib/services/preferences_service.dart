import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class PreferencesService {
  static const _lastUrlKey = 'last_url';
  static const _homeUrlKey = 'home_url';

  Future<String> getLastUrl() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_lastUrlKey) ?? await getHomeUrl();
  }

  Future<void> saveLastUrl(String url) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastUrlKey, url);
  }

  Future<String> getHomeUrl() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_homeUrlKey) ?? AppConstants.defaultHomeUrl;
  }

  Future<void> saveHomeUrl(String url) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_homeUrlKey, url);
  }
}
