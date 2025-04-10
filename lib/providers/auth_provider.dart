import 'dart:io';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  User? _viewedUser;
  bool _isAuthenticated = false;
  bool _loading = false;
  String? _error;
  final ApiService _apiService = ApiService();

  User? get user => _user;
  User? get viewedUser => _viewedUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get loading => _loading;
  String? get error => _error;

  // تحميل بيانات المستخدم
  Future<void> loadUser() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      print('بدء تحميل بيانات المستخدم');
      final response = await _apiService.getCurrentUser();
      print('استجابة loadUser: $response');

      if (response['success']) {
        _user = User.fromJson(response['data']);
        _isAuthenticated = true;
        _error = null;
      } else {
        // في حالة الخطأ، لا نعتبرها مشكلة، فقط نشير إلى أن المستخدم غير مصادق عليه
        _user = null;
        _isAuthenticated = false;
        _error = null; // لا نظهر الخطأ للمستخدم
        print('لم يتم تحميل المستخدم: ${response['message']}');
      }
    } catch (e) {
      print('استثناء في loadUser: $e');
      _user = null;
      _isAuthenticated = false;
      _error = null; // لا نظهر الخطأ للمستخدم
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // الحصول على جميع المستخدمين
  Future<Map<String, dynamic>> getUsers() async {
    try {
      print('جاري جلب قائمة المستخدمين');
      final response = await _apiService.getAllUsers();

      if (response['success']) {
        if (response['data'] != null) {
          try {
            final List<User> users =
                (response['data'] as List)
                    .map((json) => User.fromJson(json))
                    .toList();
            return {'success': true, 'data': users};
          } catch (e) {
            print('خطأ في تحويل بيانات المستخدمين: $e');
            return {
              'success': false,
              'message': 'خطأ في معالجة بيانات المستخدمين',
            };
          }
        } else {
          return {'success': true, 'data': []};
        }
      } else {
        return {'success': false, 'message': response['message']};
      }
    } catch (e) {
      print('استثناء في getUsers: $e');
      return {'success': false, 'message': 'فشل في جلب المستخدمين'};
    }
  }

  // تسجيل مستخدم جديد
  Future<bool> register(String username, String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      print('بدء تسجيل مستخدم جديد');
      final response = await _apiService.register(username, email, password);
      print('استجابة Register: $response');

      _loading = false;

      if (response['success']) {
        await loadUser();
        _isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        _error = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('استثناء في register: $e');
      _loading = false;
      _error = 'حدث خطأ أثناء إنشاء الحساب';
      notifyListeners();
      return false;
    }
  }

  // تسجيل الدخول
Future<bool> login(String email, String password) async {
  print('محاولة تسجيل الدخول بـ: $email');
  print('URL الخادم: ${_apiService.baseUrl}');
  _loading = true;
  _error = null;
  notifyListeners();

  try {
    final response = await _apiService.login(email, password);
    
    print('استجابة تسجيل الدخول: $response');
    
    _loading = false;
    
    if (response['success']) {
      // تحميل بيانات المستخدم بشكل منفصل بدلاً من استدعاء loadUser
      try {
        final userResponse = await _apiService.getCurrentUser();
        if (userResponse['success']) {
          _user = User.fromJson(userResponse['data']);
          _isAuthenticated = true;
          notifyListeners();
          return true;
        } else {
          print('فشل استرداد بيانات المستخدم: ${userResponse['message']}');
          _error = 'تم تسجيل الدخول ولكن فشل استرداد البيانات';
          notifyListeners();
          return false;
        }
      } catch (userError) {
        print('خطأ في استرداد بيانات المستخدم: $userError');
        // لكن رغم ذلك، نعتبر أن تسجيل الدخول نجح
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
    } else {
      _error = response['message'];
      notifyListeners();
      return false;
    }
  } catch (e) {
    print('استثناء في login: $e');
    _loading = false;
    _error = 'حدث خطأ أثناء تسجيل الدخول';
    notifyListeners();
    return false;
  }
}

  // تسجيل الخروج
  Future<void> logout() async {
    _loading = true;
    notifyListeners();

    try {
      await _apiService.clearToken();
      _user = null;
      _isAuthenticated = false;
      // لا نحتاج إعادة التوجيه هنا لأنها ستتم في واجهة المستخدم
    } catch (e) {
      print('خطأ في تسجيل الخروج: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // تحديث الملف الشخصي
  Future<bool> updateProfile(String bio, File? profileImage) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateProfile(
        bio,
        profileImage: profileImage,
      );

      _loading = false;

      if (response['success']) {
        await loadUser();
        return true;
      } else {
        _error = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('استثناء في updateProfile: $e');
      _loading = false;
      _error = 'حدث خطأ أثناء تحديث الملف الشخصي';
      notifyListeners();
      return false;
    }
  }

  // الحصول على ملف مستخدم آخر
  Future<bool> getUserProfile(String userId) async {
    _loading = true;
    _error = null;
    _viewedUser = null;
    notifyListeners();

    try {
      final response = await _apiService.getUserById(userId);

      if (response['success']) {
        _viewedUser = User.fromJson(response['data']);
        _error = null;
      } else {
        _error = response['message'];
      }
    } catch (e) {
      print('استثناء في getUserProfile: $e');
      _error = 'فشل في الحصول على بيانات المستخدم';
    } finally {
      _loading = false;
      notifyListeners();
    }

    return _viewedUser != null;
  }

  // الحصول على معلومات عدة مستخدمين دفعة واحدة (للمتابعين)
  Future<List<User>> getMultipleUsers(List<String> userIds) async {
    List<User> users = [];

    if (userIds.isEmpty) {
      return users;
    }

    try {
      final response = await _apiService.getMultipleUsers(userIds);

      if (response['success']) {
        users =
            (response['data'] as List)
                .map((userData) => User.fromJson(userData))
                .toList();
      }
    } catch (e) {
      print('استثناء في getMultipleUsers: $e');
    }

    return users;
  }

  // البحث عن مستخدمين
  Future<List<User>> searchUsers(String query) async {
    List<User> users = [];

    if (query.isEmpty) {
      return users;
    }

    try {
      final response = await _apiService.searchUsers(query);

      if (response['success']) {
        users =
            (response['data'] as List)
                .map((userData) => User.fromJson(userData))
                .toList();
      }
    } catch (e) {
      print('استثناء في searchUsers: $e');
    }

    return users;
  }

  // متابعة مستخدم
  Future<bool> followUser(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.followUser(userId);

      _loading = false;

      if (response['success']) {
        await loadUser();
        return true;
      } else {
        _error = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('استثناء في followUser: $e');
      _loading = false;
      _error = 'حدث خطأ أثناء متابعة المستخدم';
      notifyListeners();
      return false;
    }
  }

  // إلغاء متابعة مستخدم
  Future<bool> unfollowUser(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.unfollowUser(userId);

      _loading = false;

      if (response['success']) {
        await loadUser();
        return true;
      } else {
        _error = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('استثناء في unfollowUser: $e');
      _loading = false;
      _error = 'حدث خطأ أثناء إلغاء متابعة المستخدم';
      notifyListeners();
      return false;
    }
  }
}