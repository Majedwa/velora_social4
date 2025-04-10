import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../models/story.dart';
import '../models/user.dart';
import 'auth_provider.dart';

class StoryProvider with ChangeNotifier {
  final ApiService _apiService;
  final AuthProvider _authProvider;
  
  List<Story> _stories = [];
  Story? _myStory;
  bool _loading = false;
  String? _error;
  
  StoryProvider(this._apiService, this._authProvider) {
    _initializeStories();
  }
  
  List<Story> get stories => _stories;
  Story? get myStory => _myStory;
  bool get loading => _loading;
  String? get error => _error;
  
  // التهيئة الأولية للقصص
  Future<void> _initializeStories() async {
    if (_authProvider.isAuthenticated) {
      await loadStories();
    }
  }
  
  // تحميل القصص
  Future<void> loadStories() async {
    if (!_authProvider.isAuthenticated) return;
    
    _loading = true;
    _error = null;
    notifyListeners();
    
    try {
      final currentUserId = _authProvider.user!.id;
      
      // في حالة وجود API للقصص
      // final response = await _apiService.getStories();
      
      // للتجربة، سنستخدم بيانات محلية محفوظة
      final prefs = await SharedPreferences.getInstance();
      final storiesJson = prefs.getString('stories');
      
      if (storiesJson != null) {
        final List<dynamic> storiesData = jsonDecode(storiesJson);
        _stories = storiesData
            .map((data) => Story.fromJson(data))
            .where((story) => story.hasValidItems) // فقط القصص الصالحة
            .toList();
        
        // فصل القصة الخاصة بالمستخدم الحالي
        _myStory = _stories.firstWhere(
          (story) => story.userId == currentUserId,
          orElse: () => Story(
            id: currentUserId,
            userId: currentUserId,
            username: _authProvider.user!.username,
            userProfilePicture: _authProvider.user!.profilePicture,
            items: [],
            lastUpdated: DateTime.now(),
          ),
        );
        
        // إزالة قصة المستخدم الحالي من القائمة العامة
        _stories = _stories.where((story) => story.userId != currentUserId).toList();
      } else {
        // إنشاء قصة فارغة للمستخدم الحالي
        _myStory = Story(
          id: currentUserId,
          userId: currentUserId,
          username: _authProvider.user!.username,
          userProfilePicture: _authProvider.user!.profilePicture,
          items: [],
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      print('خطأ في تحميل القصص: $e');
      _error = 'فشل في تحميل القصص';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  
  // حفظ القصص محليًا
  Future<void> _saveStories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // جمع جميع القصص بما فيها قصة المستخدم الحالي
      final allStories = [..._stories];
      if (_myStory != null && _myStory!.hasValidItems) {
        allStories.add(_myStory!);
      }
      
      final storiesJson = jsonEncode(allStories.map((story) => story.toJson()).toList());
      await prefs.setString('stories', storiesJson);
    } catch (e) {
      print('خطأ في حفظ القصص: $e');
    }
  }
  
  // إضافة قصة جديدة
  Future<bool> addStoryItem({
    required StoryType type,
    required String content,
    File? file,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_authProvider.isAuthenticated) return false;
    
    try {
      final currentUser = _authProvider.user!;
      
      // إنشاء عنصر قصة جديد
      final storyItem = StoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        content: content,
        createdAt: DateTime.now(),
        metadata: metadata,
        viewedBy: [currentUser.id], // المستخدم نفسه يُعتبر قد شاهد القصة
      );
      
      // إضافة القصة للمستخدم الحالي
      if (_myStory == null) {
        _myStory = Story(
          id: currentUser.id,
          userId: currentUser.id,
          username: currentUser.username,
          userProfilePicture: currentUser.profilePicture,
          items: [storyItem],
          lastUpdated: DateTime.now(),
        );
      } else {
        // تحديث قائمة القصص
        final updatedItems = [..._myStory!.items, storyItem];
        
        _myStory = Story(
          id: _myStory!.id,
          userId: _myStory!.userId,
          username: _myStory!.username,
          userProfilePicture: _myStory!.userProfilePicture,
          items: updatedItems,
          lastUpdated: DateTime.now(),
        );
      }
      
      // حفظ التغييرات
      await _saveStories();
      
      notifyListeners();
      return true;
    } catch (e) {
      print('خطأ في إضافة قصة: $e');
      _error = 'فشل في إضافة القصة';
      notifyListeners();
      return false;
    }
  }
  
  // إضافة قصة صورة
  Future<bool> addImageStory(File image, {Map<String, dynamic>? metadata}) async {
    // في حالة وجود API، هنا سنقوم برفع الصورة للخادم
    // وإرجاع مسار الصورة على الخادم
    
    // للتجربة، سنستخدم المسار المحلي فقط
    return addStoryItem(
      type: StoryType.image,
      content: image.path,
      file: image,
      metadata: metadata,
    );
  }
  
  // إضافة قصة نصية
  Future<bool> addTextStory(String text, {Map<String, dynamic>? metadata}) async {
    return addStoryItem(
      type: StoryType.text,
      content: text,
      metadata: metadata,
    );
  }
  
  // تحديث حالة مشاهدة القصة - Método público para usar desde StoryViewScreen
  Future<void> markStoryAsViewed(String storyId, String storyItemId) async {
    if (!_authProvider.isAuthenticated) return;
    
    final currentUserId = _authProvider.user!.id;
    
    try {
      // البحث عن القصة
      final storyIndex = _stories.indexWhere((story) => story.id == storyId);
      if (storyIndex != -1) {
        final story = _stories[storyIndex];
        
        // البحث عن عنصر القصة
        final itemIndex = story.items.indexWhere((item) => item.id == storyItemId);
        if (itemIndex != -1) {
          final item = story.items[itemIndex];
          
          // إضافة المستخدم الحالي إلى قائمة المشاهدين
          final updatedItem = item.addViewer(currentUserId);
          
          // تحديث القصة
          final updatedItems = List<StoryItem>.from(story.items);
          updatedItems[itemIndex] = updatedItem;
          
          _stories[storyIndex] = Story(
            id: story.id,
            userId: story.userId,
            username: story.username,
            userProfilePicture: story.userProfilePicture,
            items: updatedItems,
            lastUpdated: story.lastUpdated,
          );
          
          // حفظ التغييرات
          await _saveStories();
          
          notifyListeners();
        }
      }
    } catch (e) {
      print('خطأ في تحديث حالة مشاهدة القصة: $e');
    }
  }
  
  // التحقق مما إذا كان المستخدم يملك قصصًا
  bool hasStories(String userId) {
    if (userId == _authProvider.user?.id) {
      return _myStory != null && _myStory!.hasValidItems;
    } else {
      return _stories.any((story) => story.userId == userId && story.hasValidItems);
    }
  }
  
  // الحصول على قصة مستخدم معين
  Story? getStoryByUserId(String userId) {
    if (userId == _authProvider.user?.id) {
      return _myStory;
    } else {
      return _stories.firstWhere(
        (story) => story.userId == userId,
        orElse: () => null as Story,
      );
    }
  }
  
  // حذف عنصر قصة
  Future<void> deleteStoryItem(String storyItemId) async {
    if (!_authProvider.isAuthenticated || _myStory == null) return;
    
    try {
      // حذف عنصر القصة من قصة المستخدم الحالي
      final updatedItems = _myStory!.items.where((item) => item.id != storyItemId).toList();
      
      _myStory = Story(
        id: _myStory!.id,
        userId: _myStory!.userId,
        username: _myStory!.username,
        userProfilePicture: _myStory!.userProfilePicture,
        items: updatedItems,
        lastUpdated: _myStory!.lastUpdated,
      );
      
      // حفظ التغييرات
      await _saveStories();
      
      notifyListeners();
    } catch (e) {
      print('خطأ في حذف عنصر القصة: $e');
    }
  }
  
  // الحصول على القصص التي لم يشاهدها المستخدم بعد
  List<Story> getUnviewedStories() {
    if (!_authProvider.isAuthenticated) return [];
    
    final currentUserId = _authProvider.user!.id;
    
    return _stories
        .where((story) => story.hasUnviewedItems(currentUserId))
        .toList();
  }
  
  // الحصول على عدد القصص التي لم يشاهدها المستخدم بعد
  int getUnviewedStoriesCount() {
    return getUnviewedStories().length;
  }
  
  // تحديث/تحميل القصص
  Future<void> refreshStories() async {
    await loadStories();
  }
  
  // Método para obtener el AuthProvider (ayuda a evitar el error de acceso directo)
  AuthProvider get authProvider => _authProvider;
}