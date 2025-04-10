import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';

class FavoriteProvider with ChangeNotifier {
  Set<String> _favoritePostIds = {}; // مجموعة معرّفات المنشورات المفضلة
  List<Post> _favoritePosts = []; // قائمة المنشورات المفضلة الكاملة
  
  Set<String> get favoritePostIds => _favoritePostIds;
  List<Post> get favoritePosts => _favoritePosts;
  
  FavoriteProvider() {
    _loadFavorites();
  }
  
  // تحميل المفضلة من التخزين المحلي
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // تحميل معرّفات المنشورات المفضلة
      final idsList = prefs.getStringList('favorite_post_ids') ?? [];
      _favoritePostIds = Set<String>.from(idsList);
      
      // تحميل المنشورات المفضلة الكاملة (إذا وجدت)
      final postsJson = prefs.getString('favorite_posts');
      if (postsJson != null) {
        final List<dynamic> postsData = jsonDecode(postsJson);
        _favoritePosts = postsData
            .map((data) => Post.fromJson(data))
            .toList();
      }
      
      notifyListeners();
    } catch (e) {
      print('خطأ في تحميل المفضلة: $e');
    }
  }
  
  // حفظ المفضلة في التخزين المحلي
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // حفظ معرّفات المنشورات المفضلة
      await prefs.setStringList('favorite_post_ids', _favoritePostIds.toList());
      
      // حفظ المنشورات المفضلة الكاملة
      final postsJson = jsonEncode(_favoritePosts.map((post) => post.toJson()).toList());
      await prefs.setString('favorite_posts', postsJson);
    } catch (e) {
      print('خطأ في حفظ المفضلة: $e');
    }
  }
  
  // إضافة منشور للمفضلة
  Future<void> addToFavorites(Post post) async {
    if (!_favoritePostIds.contains(post.id)) {
      _favoritePostIds.add(post.id);
      _favoritePosts.add(post);
      notifyListeners();
      await _saveFavorites();
    }
  }
  
  // إزالة منشور من المفضلة
  Future<void> removeFromFavorites(String postId) async {
    if (_favoritePostIds.contains(postId)) {
      _favoritePostIds.remove(postId);
      _favoritePosts.removeWhere((post) => post.id == postId);
      notifyListeners();
      await _saveFavorites();
    }
  }
  
  // التحقق ما إذا كان المنشور في المفضلة
  bool isFavorite(String postId) {
    return _favoritePostIds.contains(postId);
  }
  
  // تبديل حالة المفضلة للمنشور
  Future<void> toggleFavorite(Post post) async {
    if (isFavorite(post.id)) {
      await removeFromFavorites(post.id);
    } else {
      await addToFavorites(post);
    }
  }
  
  // تحديث منشور موجود في المفضلة
  Future<void> updateFavoritePost(Post updatedPost) async {
    if (isFavorite(updatedPost.id)) {
      final index = _favoritePosts.indexWhere((post) => post.id == updatedPost.id);
      if (index != -1) {
        _favoritePosts[index] = updatedPost;
        notifyListeners();
        await _saveFavorites();
      }
    }
  }
  
  // مسح كل المفضلة
  Future<void> clearAllFavorites() async {
    _favoritePostIds.clear();
    _favoritePosts.clear();
    notifyListeners();
    await _saveFavorites();
  }
}