import 'dart:convert';
import 'package:flutter/services.dart';
import 'menu_item.dart';

class MenuService {
  static List<MenuItem> _menuItems = [];
  static bool _isLoaded = false;

  static Future<void> loadMenuData() async {
    if (_isLoaded) return;

    try {
      final String response = await rootBundle.loadString(
        'assets/data/tandoori_nights.json',
      );
      final List<dynamic> data = json.decode(response);

      _menuItems = data.map((json) => MenuItem.fromJson(json)).toList();
      _isLoaded = true;
    } catch (e) {
      print('Error loading menu data: $e');
      _menuItems = [];
    }
  }

  static List<MenuItem> getAllItems() {
    return _menuItems.where((item) => item.available).toList();
  }

  static List<MenuItem> getItemsByCategory(String category) {
    return _menuItems
        .where(
          (item) => item.category.trim() == category.trim() && item.available,
        )
        .toList();
  }

  static List<String> getCategories() {
    return _menuItems.map((item) => item.category.trim()).toSet().toList();
  }

  static List<MenuItem> getVegetarianItems() {
    return _menuItems.where((item) => item.isVeg && item.available).toList();
  }

  static List<MenuItem> searchItems(String query) {
    return _menuItems
        .where(
          (item) =>
              item.available &&
              (item.name.toLowerCase().contains(query.toLowerCase()) ||
                  item.description.toLowerCase().contains(query.toLowerCase())),
        )
        .toList();
  }
}
