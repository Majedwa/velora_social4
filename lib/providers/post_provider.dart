import 'dart:io';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/post.dart';

enum SortOption {
  latest, // الأحدث
  mostLiked, // الأكثر إعجابًا
}

class PostProvider with ChangeNotifier {
  List<Post> _posts = [];
  List<Post> _filteredPosts = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMorePosts = true;
  String? _error;
  final ApiService _apiService = ApiService();
  int _page = 1;
  final int _limit = 10;
  SortOption _currentSortOption = SortOption.latest;

  List<Post> get posts => _filteredPosts;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMorePosts => _hasMorePosts;
  String? get error => _error;
  SortOption get currentSortOption => _currentSortOption;

  // تحديد خيار الترتيب
  void setSortOption(SortOption option) {
    if (_currentSortOption != option) {
      _currentSortOption = option;
      _sortPosts();
      notifyListeners();
    }
  }

  // ترتيب المنشورات حسب الخيار المحدد
  void _sortPosts() {
    switch (_currentSortOption) {
      case SortOption.latest:
        _filteredPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.mostLiked:
        _filteredPosts.sort((a, b) => b.likes.length.compareTo(a.likes.length));
        break;
    }
  }

  // الحصول على جميع المنشورات
  Future<void> fetchPosts({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMorePosts = true;
    }

    if (_loading) return;
    
    _loading = true;
    _error = null;
    
    if (refresh) {
      _posts = [];
      _filteredPosts = [];
    }
    
    notifyListeners();

    try {
      final response = await _apiService.getPosts();
      print('استجابة getPosts: $response');

      if (response['success']) {
        if (response['data'] != null) {
          try {
            _posts = (response['data'] as List)
                .map((post) => Post.fromJson(post))
                .toList();
            
            _filteredPosts = List.from(_posts);
            _sortPosts();
            
            print('تم تحويل ${_posts.length} منشور بنجاح');
          } catch (e) {
            print('خطأ في تحويل المنشورات: $e');
            _error = 'خطأ في معالجة بيانات المنشورات';
          }
        } else {
          _posts = [];
          _filteredPosts = [];
          print('لا توجد منشورات (البيانات فارغة)');
        }
      } else {
        _error = response['message'];
        print('خطأ في جلب المنشورات: $_error');
      }
    } catch (e) {
      print('استثناء في fetchPosts: $e');
      _error = 'حدث خطأ أثناء جلب المنشورات';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // تحميل المزيد من المنشورات (للتمرير اللانهائي)
  Future<void> loadMorePosts() async {
    if (_loadingMore || !_hasMorePosts) return;
    
    _loadingMore = true;
    notifyListeners();

    try {
      _page++;
      
      // في الواقع، ستحتاج هنا إلى تعديل API لدعم الصفحات والحدود
      // هذا مجرد نموذج توضيحي
      final response = await _apiService.getPosts(page: _page, limit: _limit);
      
      if (response['success'] && response['data'] != null) {
        final newPosts = (response['data'] as List)
            .map((post) => Post.fromJson(post))
            .toList();
        
        if (newPosts.isEmpty) {
          _hasMorePosts = false;
        } else {
          _posts.addAll(newPosts);
          _filteredPosts = List.from(_posts);
          _sortPosts();
        }
      } else {
        _hasMorePosts = false;
      }
    } catch (e) {
      print('استثناء في loadMorePosts: $e');
      _error = 'حدث خطأ أثناء تحميل المزيد من المنشورات';
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  // الحصول على منشورات مستخدم معين
  Future<void> fetchUserPosts(String userId, {bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMorePosts = true;
    }

    if (_loading) return;
    
    _loading = true;
    _error = null;
    
    if (refresh) {
      _posts = [];
      _filteredPosts = [];
    }
    
    notifyListeners();

    try {
      final response = await _apiService.getUserPosts(userId);
      print('استجابة getUserPosts: $response');

      if (response['success']) {
        if (response['data'] != null) {
          try {
            _posts = (response['data'] as List)
                .map((post) => Post.fromJson(post))
                .toList();
            
            _filteredPosts = List.from(_posts);
            _sortPosts();
            
            print('تم تحويل ${_posts.length} منشور للمستخدم بنجاح');
          } catch (e) {
            print('خطأ في تحويل منشورات المستخدم: $e');
            _error = 'خطأ في معالجة بيانات المنشورات';
          }
        } else {
          _posts = [];
          _filteredPosts = [];
          print('لا توجد منشورات للمستخدم (البيانات فارغة)');
        }
      } else {
        _error = response['message'];
        print('خطأ في جلب منشورات المستخدم: $_error');
      }
    } catch (e) {
      print('استثناء في fetchUserPosts: $e');
      _error = 'حدث خطأ أثناء جلب منشورات المستخدم';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // إنشاء منشور جديد
  Future<bool> createPost(String content, {File? image}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createPost(content, image: image);
      print('استجابة createPost: $response');
      
      _loading = false;
      
      if (response['success']) {
        await fetchPosts(refresh: true); // تحديث قائمة المنشورات
        return true;
      } else {
        _error = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('استثناء في createPost: $e');
      _loading = false;
      _error = 'حدث خطأ أثناء إنشاء المنشور';
      notifyListeners();
      return false;
    }
  }

  // إضافة إعجاب لمنشور
  Future<bool> likePost(String postId) async {
    try {
      final response = await _apiService.likePost(postId);
      print('استجابة likePost: $response');
      
      if (response['success']) {
        // تحديث المنشور محليًا بدلاً من إعادة تحميل جميع المنشورات
        _updatePostLikes(postId, true);
        return true;
      } else {
        _error = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('استثناء في likePost: $e');
      _error = 'حدث خطأ أثناء الإعجاب بالمنشور';
      notifyListeners();
      return false;
    }
  }

  // إزالة إعجاب من منشور
  Future<bool> unlikePost(String postId) async {
    try {
      final response = await _apiService.unlikePost(postId);
      print('استجابة unlikePost: $response');
      
      if (response['success']) {
        // تحديث المنشور محليًا بدلاً من إعادة تحميل جميع المنشورات
        _updatePostLikes(postId, false);
        return true;
      } else {
        _error = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('استثناء في unlikePost: $e');
      _error = 'حدث خطأ أثناء إلغاء الإعجاب بالمنشور';
      notifyListeners();
      return false;
    }
  }

  // تحديث الإعجابات محليًا
  void _updatePostLikes(String postId, bool isLiking) {
    final currentUserId = _getCurrentUserId();
    if (currentUserId == null) return;
    
    // تحديث في _posts
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      final List<String> updatedLikes = List.from(post.likes);
      
      if (isLiking) {
        if (!updatedLikes.contains(currentUserId)) {
          updatedLikes.add(currentUserId);
        }
      } else {
        updatedLikes.remove(currentUserId);
      }
      
      _posts[postIndex] = Post(
        id: post.id,
        userId: post.userId,
        username: post.username,
        userProfilePicture: post.userProfilePicture,
        content: post.content,
        image: post.image,
        likes: updatedLikes,
        comments: post.comments,
        createdAt: post.createdAt,
      );
    }
    
    // تحديث في _filteredPosts
    final filteredIndex = _filteredPosts.indexWhere((post) => post.id == postId);
    if (filteredIndex != -1) {
      final post = _filteredPosts[filteredIndex];
      final List<String> updatedLikes = List.from(post.likes);
      
      if (isLiking) {
        if (!updatedLikes.contains(currentUserId)) {
          updatedLikes.add(currentUserId);
        }
      } else {
        updatedLikes.remove(currentUserId);
      }
      
      _filteredPosts[filteredIndex] = Post(
        id: post.id,
        userId: post.userId,
        username: post.username,
        userProfilePicture: post.userProfilePicture,
        content: post.content,
        image: post.image,
        likes: updatedLikes,
        comments: post.comments,
        createdAt: post.createdAt,
      );
    }
    
    notifyListeners();
  }

  // الحصول على معرف المستخدم الحالي (مساعدة)
  String? _getCurrentUserId() {
    // هذه طريقة بسيطة، في الواقع ستحتاج إلى الوصول للمستخدم الحالي
    return _apiService.currentUserId;
  }

  // إضافة تعليق على منشور
  Future<bool> addComment(String postId, String text) async {
    try {
      final response = await _apiService.addComment(postId, text);
      print('استجابة addComment: $response');
      
      if (response['success']) {
        // تحديث التعليقات محليًا
        if (response['data'] != null) {
          _updatePostComments(postId, response['data']);
        } else {
          // إذا لم يكن هناك بيانات محددة، أعد تحميل المنشورات
          await fetchPosts(refresh: false);
        }
        return true;
      } else {
        _error = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('استثناء في addComment: $e');
      _error = 'حدث خطأ أثناء إضافة التعليق';
      notifyListeners();
      return false;
    }
  }

  // تحديث التعليقات محليًا
  void _updatePostComments(String postId, dynamic commentsData) {
    // تحديث في _posts
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    // تعديل _posts وكذلك _filteredPosts أسوة بما فعلنا في likes
  }

  // حفظ منشور في المفضلة
  void toggleFavorite(String postId) {
    // يمكن تنفيذ هذه الوظيفة لاحقاً - تتطلب تخزين محلي
  }

  // حذف منشور
  Future<bool> deletePost(String postId) async {
    try {
      final response = await _apiService.deletePost(postId);
      
      if (response['success']) {
        // حذف المنشور محليًا
        _posts.removeWhere((post) => post.id == postId);
        _filteredPosts.removeWhere((post) => post.id == postId);
        notifyListeners();
        return true;
      } else {
        _error = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('استثناء في deletePost: $e');
      _error = 'حدث خطأ أثناء حذف المنشور';
      notifyListeners();
      return false;
    }
  }
}