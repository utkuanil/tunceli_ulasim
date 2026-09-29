import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static const String _favoriteRoutesKey = 'favorite_route_ids';
  static const String _favoriteStopsKey = 'favorite_stop_ids';

  // ============================================================
  // HAT FAVORİLERİ
  // ============================================================

  Future<List<String>> getFavoriteRouteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoriteRoutesKey) ?? [];
  }

  Future<bool> isFavorite(String routeId) async {
    final favoriteIds = await getFavoriteRouteIds();
    return favoriteIds.contains(routeId);
  }

  Future<void> addFavorite(String routeId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList(_favoriteRoutesKey) ?? [];

    if (!favoriteIds.contains(routeId)) {
      favoriteIds.add(routeId);
      await prefs.setStringList(_favoriteRoutesKey, favoriteIds);
    }
  }

  Future<void> removeFavorite(String routeId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList(_favoriteRoutesKey) ?? [];

    favoriteIds.remove(routeId);
    await prefs.setStringList(_favoriteRoutesKey, favoriteIds);
  }

  Future<bool> toggleFavorite(String routeId) async {
    final favorite = await isFavorite(routeId);

    if (favorite) {
      await removeFavorite(routeId);
      return false;
    }

    await addFavorite(routeId);
    return true;
  }

  // ============================================================
  // DURAK FAVORİLERİ
  // ============================================================

  Future<List<String>> getFavoriteStopIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoriteStopsKey) ?? [];
  }

  Future<bool> isStopFavorite(String stopId) async {
    final favoriteIds = await getFavoriteStopIds();
    return favoriteIds.contains(stopId);
  }

  Future<void> addFavoriteStop(String stopId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList(_favoriteStopsKey) ?? [];

    if (!favoriteIds.contains(stopId)) {
      favoriteIds.add(stopId);
      await prefs.setStringList(_favoriteStopsKey, favoriteIds);
    }
  }

  Future<void> removeFavoriteStop(String stopId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList(_favoriteStopsKey) ?? [];

    favoriteIds.remove(stopId);
    await prefs.setStringList(_favoriteStopsKey, favoriteIds);
  }

  Future<bool> toggleFavoriteStop(String stopId) async {
    final favorite = await isStopFavorite(stopId);

    if (favorite) {
      await removeFavoriteStop(stopId);
      return false;
    }

    await addFavoriteStop(stopId);
    return true;
  }
}
