// ignore_for_file: depend_on_referenced_packages, avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path_util;

class ApiService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // تعديل عنوان IP ليعمل على المحاكي والأجهزة الحقيقية
  // تأكد من تغيير هذا العنوان حسب بيئة التطوير الخاصة بك
  final String baseUrl = 'http://192.168.88.2:5000/api';

  ApiService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'token');
          if (token != null) {
            options.headers['x-auth-token'] = token;
          }
          return handler.next(options);
        },
      ),
    );

    // إضافة معالج خطأ للتشخيص
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          print('خطأ Dio: ${e.message}');
          print('استجابة: ${e.response?.data}');
          return handler.next(e);
        },
      ),
    );
  }

  // تحويل مسار نسبي إلى URL كامل - نسخة محسنة
  String getFullImageUrl(String imagePath) {
    print('معالجة مسار الصورة: $imagePath');

    // التعامل مع الصورة الافتراضية
    if (imagePath.isEmpty || imagePath == 'default-profile.jpg') {
      return 'http://192.168.88.2:5000/uploads/profiles/default-profile.jpg';
    }

    // إذا كان المسار يبدأ بـ http، فهو مسار كامل بالفعل
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // استخراج الجزء الأساسي من عنوان الـ API والتأكد من أنه صحيح
    String baseUrlWithoutApi = 'http://192.168.88.2:5000';

    // إذا كان المسار يبدأ بـ / نستخدمه كما هو، وإلا نضيف / قبله
    if (imagePath.startsWith('/')) {
      String fullUrl = baseUrlWithoutApi + imagePath;
      print('الرابط الكامل: $fullUrl');
      return fullUrl;
    } else {
      String fullUrl = baseUrlWithoutApi + '/' + imagePath;
      print('الرابط الكامل: $fullUrl');
      return fullUrl;
    }
  }

  // التحقق من حالة مجلدات التحميل
  Future<Map<String, dynamic>> checkServerUploadsStatus() async {
    try {
      final response = await _dio.get('$baseUrl/test-upload/status');
      print('استجابة فحص حالة التحميل: ${response.data}');
      return {'success': response.statusCode == 200, 'data': response.data};
    } catch (e) {
      print('خطأ في فحص حالة التحميل: $e');
      return {
        'success': false,
        'message': 'فشل في التحقق من حالة مجلدات التحميل: $e',
      };
    }
  }

  // اختبار تحميل الصور
  Future<Map<String, dynamic>> testImageUpload(File image) async {
    try {
      print('اختبار تحميل الصور:');
      print('مسار الصورة: ${image.path}');
      print('حجم الصورة: ${await image.length()} بايت');

      // تحضير بيانات النموذج
      String fileName = path_util.basename(image.path);
      String extension = path_util.extension(image.path).toLowerCase();
      String mimeType = 'image/jpeg'; // افتراضي

      // التأكد من نوع MIME المناسب
      if (extension == '.png') {
        mimeType = 'image/png';
      } else if (extension == '.gif') {
        mimeType = 'image/gif';
      } else if (extension == '.jpg' || extension == '.jpeg') {
        mimeType = 'image/jpeg';
      }

      print('نوع MIME المستخدم: $mimeType للامتداد: $extension');

      // تحويل الصورة إلى bytes - محاولة قراءة الملف كبيانات ثنائية
      final bytes = await image.readAsBytes();
      print('تم قراءة الصورة كـ bytes: ${bytes.length} بايت');

      // إنشاء MultipartFile مباشرة من البيانات الثنائية
      final multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      );

      FormData formData = FormData.fromMap({'image': multipartFile});

      print('إرسال الطلب إلى: $baseUrl/test-upload/upload');

      // إضافة تايم آوت أطول للتحميل وإعدادات إضافية
      final response = await _dio.post(
        '$baseUrl/test-upload/upload',
        data: formData,
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          headers: {'Accept': '*/*', 'Content-Type': 'multipart/form-data'},
        ),
      );

      print('رمز الاستجابة: ${response.statusCode}');
      print('بيانات الاستجابة: ${response.data}');

      return {
        'success': response.statusCode == 200,
        'data': response.data,
        'message': response.data['message'] ?? 'تم اكتمال اختبار التحميل',
      };
    } catch (e) {
      print('استثناء في testImageUpload: $e');
      return {'success': false, 'message': 'فشل في اختبار تحميل الصورة: $e'};
    }
  }

  // تسجيل مستخدم جديد
  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      print('بدء تسجيل المستخدم: $username, $email');
      final response = await _dio.post(
        '$baseUrl/users/register',
        data: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        await _storage.write(key: 'token', value: response.data['token']);
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': 'حدث خطأ في التسجيل'};
      }
    } on DioException catch (e) {
      print('خطأ في register: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['msg'] ?? 'حدث خطأ في التسجيل',
      };
    } catch (e) {
      print('استثناء في register: $e');
      return {'success': false, 'message': 'حدث خطأ غير متوقع في التسجيل'};
    }
  }

  // تسجيل الدخول
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('محاولة تسجيل الدخول: $email');
      print('URL: $baseUrl/users/login');

      final response = await _dio.post(
        '$baseUrl/users/login',
        data: jsonEncode({'email': email, 'password': password}),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => true,
        ),
      );

      print('رمز الاستجابة: ${response.statusCode}');
      print('بيانات الاستجابة: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data['token'] != null) {
          print(
            'تم استلام التوكن: ${response.data['token'].substring(0, 20)}...',
          );

          await _storage.write(key: 'token', value: response.data['token']);

          final storedToken = await _storage.read(key: 'token');
          print('التوكن المخزن: ${storedToken?.substring(0, 20)}...');

          return {'success': true, 'data': response.data};
        } else {
          print('رد صحيح لكن بدون توكن!');
          return {'success': false, 'message': 'لم يتم استلام توكن من الخادم'};
        }
      } else {
        print('استجابة خاطئة: ${response.statusCode}');
        return {
          'success': false,
          'message': response.data['msg'] ?? 'بيانات الاعتماد غير صالحة',
        };
      }
    } on DioException catch (e) {
      print('خطأ Dio: ${e.message}');
      print('نوع الخطأ: ${e.type}');
      print('استجابة الخطأ: ${e.response?.data}');
      return {
        'success': false,
        'message': e.response?.data['msg'] ?? 'بيانات الاعتماد غير صالحة',
      };
    } catch (e) {
      print('استثناء في login: $e');
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }

  // الحصول على بيانات المستخدم الحالي
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await _storage.read(key: 'token');
      print('محاولة الحصول على بيانات المستخدم الحالي');
      if (token != null) {
        print('التوكن: ${token.substring(0, 20)}...');
      } else {
        print('لا يوجد توكن');
        return {'success': false, 'message': 'لم يتم تسجيل الدخول'};
      }

      final response = await _dio.get(
        '$baseUrl/users/me',
        options: Options(
          headers: {'x-auth-token': token},
          validateStatus: (status) => true,
        ),
      );

      print('رمز استجابة /users/me: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'message': 'فشل في الحصول على بيانات المستخدم',
        };
      }
    } catch (e) {
      print('استثناء في getCurrentUser: $e');
      return {'success': false, 'message': 'فشل في الحصول على بيانات المستخدم'};
    }
  }

  // إنشاء منشور جديد - تحسين تعامل الصور
  Future<Map<String, dynamic>> createPost(String content, {File? image}) async {
    try {
      print('جاري إنشاء منشور جديد:');
      print('المحتوى: $content');
      print('هل يوجد صورة: ${image != null}');

      if (image != null) {
        print('مسار الصورة: ${image.path}');
        print('حجم الصورة: ${await image.length()} بايت');

        // تأكد من وجود مجلد التحميل
        final statusResponse = await checkServerUploadsStatus();
        print('حالة مجلد التحميل: $statusResponse');

        // تحضير بيانات النموذج
        String fileName = path_util.basename(image.path);
        String extension = path_util.extension(image.path).toLowerCase();
        String mimeType = 'image/jpeg'; // افتراضي

        // محاولة تحديد نوع MIME بناءً على امتداد الملف
        if (extension == '.png') {
          mimeType = 'image/png';
        } else if (extension == '.gif') {
          mimeType = 'image/gif';
        } else if (extension == '.jpg' || extension == '.jpeg') {
          mimeType = 'image/jpeg';
        }

        print('نوع MIME المستخدم: $mimeType للامتداد: $extension');

        // تحويل الصورة إلى bytes - قراءة الملف مباشرة
        final bytes = await image.readAsBytes();
        print('تم قراءة الصورة كـ bytes: ${bytes.length} بايت');

        // إنشاء MultipartFile من البيانات
        final multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        );

        FormData formData = FormData.fromMap({
          'content': content,
          'image': multipartFile,
        });

        print('جاري إرسال الطلب إلى: $baseUrl/posts');

        // إضافة تايم آوت أطول للتحميل ورؤوس إضافية
        final response = await _dio.post(
          '$baseUrl/posts',
          data: formData,
          options: Options(
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
            headers: {'Accept': '*/*', 'Content-Type': 'multipart/form-data'},
          ),
        );

        print('رمز الاستجابة: ${response.statusCode}');
        print('بيانات الاستجابة: ${response.data}');

        if (response.statusCode == 200) {
          return {'success': true, 'data': response.data};
        } else {
          return {'success': false, 'message': 'فشل في إنشاء المنشور'};
        }
      } else {
        // إذا لم تكن هناك صورة، استخدم JSON
        final response = await _dio.post(
          '$baseUrl/posts',
          data: jsonEncode({'content': content}),
        );

        if (response.statusCode == 200) {
          return {'success': true, 'data': response.data};
        } else {
          return {'success': false, 'message': 'فشل في إنشاء المنشور'};
        }
      }
    } on DioException catch (e) {
      print('خطأ في createPost: ${e.message}');
      print('رمز الحالة: ${e.response?.statusCode}');
      print('بيانات الاستجابة: ${e.response?.data}');
      return {
        'success': false,
        'message': e.response?.data['msg'] ?? 'فشل في إنشاء المنشور',
      };
    } catch (e) {
      print('استثناء في createPost: $e');
      return {'success': false, 'message': 'فشل في إنشاء المنشور: $e'};
    }
  }

  // تحديث الملف الشخصي - تحسين تعامل الصور
  Future<Map<String, dynamic>> updateProfile(
    String bio, {
    File? profileImage,
  }) async {
    try {
      print('جاري تحديث الملف الشخصي:');
      print('النبذة: $bio');
      print('هل يوجد صورة جديدة: ${profileImage != null}');

      if (profileImage != null) {
        // تحضير البيانات للصورة
        print('مسار الصورة: ${profileImage.path}');
        print('حجم الصورة: ${await profileImage.length()} بايت');

        // تأكد من وجود مجلد التحميل
        final statusResponse = await checkServerUploadsStatus();
        print('حالة مجلد التحميل: $statusResponse');

        String fileName = path_util.basename(profileImage.path);
        String extension = path_util.extension(profileImage.path).toLowerCase();
        String mimeType = 'image/jpeg'; // افتراضي

        // محاولة تحديد نوع MIME
        if (extension == '.png') {
          mimeType = 'image/png';
        } else if (extension == '.gif') {
          mimeType = 'image/gif';
        } else if (extension == '.jpg' || extension == '.jpeg') {
          mimeType = 'image/jpeg';
        }

        print('نوع MIME المستخدم: $mimeType للامتداد: $extension');

        // تحويل الصورة إلى bytes - قراءة الملف مباشرة
        final bytes = await profileImage.readAsBytes();
        print('تم قراءة الصورة كـ bytes: ${bytes.length} بايت');

        // إنشاء MultipartFile من البيانات
        final multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        );

        FormData formData = FormData.fromMap({
          'bio': bio,
          'profilePicture': multipartFile,
        });

        print('جاري إرسال الطلب إلى: $baseUrl/profiles');

        final response = await _dio.put(
          '$baseUrl/profiles',
          data: formData,
          options: Options(
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
            headers: {'Accept': '*/*', 'Content-Type': 'multipart/form-data'},
          ),
        );

        print('رمز الاستجابة: ${response.statusCode}');
        print('بيانات الاستجابة: ${response.data}');

        if (response.statusCode == 200) {
          return {'success': true, 'data': response.data};
        } else {
          return {'success': false, 'message': 'فشل في تحديث الملف الشخصي'};
        }
      } else {
        // إذا لم تكن هناك صورة جديدة
        final response = await _dio.put(
          '$baseUrl/profiles',
          data: jsonEncode({'bio': bio}),
        );

        if (response.statusCode == 200) {
          return {'success': true, 'data': response.data};
        } else {
          return {'success': false, 'message': 'فشل في تحديث الملف الشخصي'};
        }
      }
    } on DioException catch (e) {
      print('خطأ في updateProfile: ${e.message}');
      print('رمز الحالة: ${e.response?.statusCode}');
      print('بيانات الاستجابة: ${e.response?.data}');
      return {
        'success': false,
        'message': e.response?.data['msg'] ?? 'فشل في تحديث الملف الشخصي',
      };
    } catch (e) {
      print('استثناء في updateProfile: $e');
      return {'success': false, 'message': 'فشل في تحديث الملف الشخصي: $e'};
    }
  }

  // الحصول على جميع المنشورات
// Obtener todas las publicaciones (con soporte para paginación)
  Future<Map<String, dynamic>> getPosts({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/posts',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': 'فشل في الحصول على المنشورات'};
      }
    } on DioException catch (e) {
      print('خطأ في getPosts: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['msg'] ?? 'فشل في الحصول على المنشورات',
      };
    } catch (e) {
      print('استثناء في getPosts: $e');
      return {'success': false, 'message': 'فشل في الحصول على المنشورات'};
    }
  }
  
  // Obtener ID del usuario actual
  String? get currentUserId {
    // Recuperar el ID del token almacenado
    // Esta es una implementación general, deberás modificarla según la estructura de tu token
    try {
      // Implementar análisis JWT aquí si usas token JWT
      return null; // Temporalmente devolvemos valor nulo
    } catch (e) {
      print('خطأ في الحصول على معرف المستخدم الحالي: $e');
      return null;
    }
  }

  // الحصول على منشورات مستخدم محدد
  Future<Map<String, dynamic>> getUserPosts(String userId) async {
    try {
      final response = await _dio.get('$baseUrl/posts/user/$userId');

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'message': 'فشل في الحصول على منشورات المستخدم',
        };
      }
    } on DioException catch (e) {
      print('خطأ في getUserPosts: ${e.message}');
      return {
        'success': false,
        'message':
            e.response?.data['msg'] ?? 'فشل في الحصول على منشورات المستخدم',
      };
    } catch (e) {
      print('استثناء في getUserPosts: $e');
      return {
        'success': false,
        'message': 'فشل في الحصول على منشورات المستخدم',
      };
    }
  }

  // إضافة إعجاب لمنشور
  Future<Map<String, dynamic>> likePost(String postId) async {
    try {
      final response = await _dio.put('$baseUrl/posts/like/$postId');

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': 'فشل في الإعجاب بالمنشور'};
      }
    } on DioException catch (e) {
      print('خطأ في likePost: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['msg'] ?? 'فشل في الإعجاب بالمنشور',
      };
    } catch (e) {
      print('استثناء في likePost: $e');
      return {'success': false, 'message': 'فشل في الإعجاب بالمنشور'};
    }
  }

  // إزالة إعجاب من منشور
  Future<Map<String, dynamic>> unlikePost(String postId) async {
    try {
      final response = await _dio.put('$baseUrl/posts/unlike/$postId');

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': 'فشل في إزالة الإعجاب من المنشور'};
      }
    } on DioException catch (e) {
      print('خطأ في unlikePost: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['msg'] ?? 'فشل في إزالة الإعجاب من المنشور',
      };
    } catch (e) {
      print('استثناء في unlikePost: $e');
      return {'success': false, 'message': 'فشل في إزالة الإعجاب من المنشور'};
    }
  }

  // إضافة تعليق على منشور
  Future<Map<String, dynamic>> addComment(String postId, String text) async {
    try {
      final response = await _dio.post(
        '$baseUrl/posts/comment/$postId',
        data: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': 'فشل في إضافة التعليق'};
      }
    } on DioException catch (e) {
      print('خطأ في addComment: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['msg'] ?? 'فشل في إضافة التعليق',
      };
    } catch (e) {
      print('استثناء في addComment: $e');
      return {'success': false, 'message': 'فشل في إضافة التعليق'};
    }
  }

  // الحصول على بيانات مستخدم بواسطة المعرف
  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final response = await _dio.get('$baseUrl/users/$userId');

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'message': 'فشل في الحصول على بيانات المستخدم',
        };
      }
    } on DioException catch (e) {
      print('خطأ في getUserById: ${e.message}');
      return {
        'success': false,
        'message':
            e.response?.data['msg'] ?? 'فشل في الحصول على بيانات المستخدم',
      };
    } catch (e) {
      print('استثناء في getUserById: $e');
      return {'success': false, 'message': 'فشل في الحصول على بيانات المستخدم'};
    }
  }

  // متابعة مستخدم
  Future<Map<String, dynamic>> followUser(String userId) async {
    try {
      final response = await _dio.put('$baseUrl/profiles/follow/$userId');

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': 'فشل في متابعة المستخدم'};
      }
    } on DioException catch (e) {
      print('خطأ في followUser: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['msg'] ?? 'فشل في متابعة المستخدم',
      };
    } catch (e) {
      print('استثناء في followUser: $e');
      return {'success': false, 'message': 'فشل في متابعة المستخدم'};
    }
  }

  // إلغاء متابعة مستخدم
  Future<Map<String, dynamic>> unfollowUser(String userId) async {
    try {
      final response = await _dio.put('$baseUrl/profiles/unfollow/$userId');

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': 'فشل في إلغاء متابعة المستخدم'};
      }
    } on DioException catch (e) {
      print('خطأ في unfollowUser: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['msg'] ?? 'فشل في إلغاء متابعة المستخدم',
      };
    } catch (e) {
      print('استثناء في unfollowUser: $e');
      return {'success': false, 'message': 'فشل في إلغاء متابعة المستخدم'};
    }
  }

  // البحث عن مستخدمين
  Future<Map<String, dynamic>> searchUsers(String query) async {
    try {
      final response = await _dio.get('$baseUrl/users/search/$query');

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': 'فشل في البحث عن المستخدمين'};
      }
    } on DioException catch (e) {
      print('خطأ في searchUsers: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['msg'] ?? 'فشل في البحث عن المستخدمين',
      };
    } catch (e) {
      print('استثناء في searchUsers: $e');
      return {'success': false, 'message': 'فشل في البحث عن المستخدمين'};
    }
  }

  // الحصول على بيانات عدة مستخدمين
  Future<Map<String, dynamic>> getMultipleUsers(List<String> userIds) async {
    try {
      final response = await _dio.post(
        '$baseUrl/users/multiple',
        data: jsonEncode({'userIds': userIds}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'message': 'فشل في الحصول على بيانات المستخدمين',
        };
      }
    } on DioException catch (e) {
      print('خطأ في getMultipleUsers: ${e.message}');
      return {
        'success': false,
        'message':
            e.response?.data['msg'] ?? 'فشل في الحصول على بيانات المستخدمين',
      };
    } catch (e) {
      print('استثناء في getMultipleUsers: $e');
      return {
        'success': false,
        'message': 'فشل في الحصول على بيانات المستخدمين',
      };
    }
  }

  // الحصول على جميع المستخدمين
  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final response = await _dio.get('$baseUrl/users');

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': 'فشل في جلب المستخدمين'};
      }
    } on DioException catch (e) {
      print('خطأ في getAllUsers: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['msg'] ?? 'فشل في جلب المستخدمين',
      };
    } catch (e) {
      print('استثناء في getAllUsers: $e');
      return {'success': false, 'message': 'حدث خطأ أثناء الاتصال بالخادم'};
    }
  }

  // حذف منشور
  Future<Map<String, dynamic>> deletePost(String postId) async {
    try {
      final response = await _dio.delete('$baseUrl/posts/$postId');

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'تم حذف المنشور بنجاح'};
      } else {
        return {'success': false, 'message': 'فشل في حذف المنشور'};
      }
    } on DioException catch (e) {
      print('خطأ في deletePost: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['msg'] ?? 'فشل في حذف المنشور',
      };
    } catch (e) {
      print('استثناء في deletePost: $e');
      return {'success': false, 'message': 'فشل في حذف المنشور'};
    }
  }

  // حذف تعليق
  Future<Map<String, dynamic>> deleteComment(
    String postId,
    String commentId,
  ) async {
    try {
      final response = await _dio.delete(
        '$baseUrl/posts/comment/$postId/$commentId',
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': 'فشل في حذف التعليق'};
      }
    } on DioException catch (e) {
      print('خطأ في deleteComment: ${e.message}');
      return {
        'success': false,
        'message': e.response?.data['msg'] ?? 'فشل في حذف التعليق',
      };
    } catch (e) {
      print('استثناء في deleteComment: $e');
      return {'success': false, 'message': 'فشل في حذف التعليق'};
    }
  }
// Obtener todas las publicaciones (con soporte para paginación)
  

  // مسح التوكن
  Future<void> clearToken() async {
    try {
      await _storage.delete(key: 'token');
      print('تم مسح التوكن بنجاح');
    } catch (e) {
      print('خطأ في مسح التوكن: $e');
    }
  }
}
