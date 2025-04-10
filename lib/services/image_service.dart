import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  // التقاط صورة من الكاميرا
  static Future<File?> takePhoto({
    double? maxWidth = 800,
    double? maxHeight = 800,
    int? imageQuality = 85,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedFile == null) {
        return null;
      }

      // إرجاع الملف بعد التحسين
      return await compressAndPrepareImage(File(pickedFile.path));
    } on PlatformException catch (e) {
      print('خطأ في التقاط صورة: $e');
      return null;
    }
  }

  // اختيار صورة من المعرض
  static Future<File?> pickImage({
    double? maxWidth = 800,
    double? maxHeight = 800,
    int? imageQuality = 85,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (pickedFile == null) {
        return null;
      }

      // إرجاع الملف بعد التحسين
      return await compressAndPrepareImage(File(pickedFile.path));
    } on PlatformException catch (e) {
      print('خطأ في اختيار صورة: $e');
      return null;
    }
  }

  // ضغط وتحسين الصورة
  static Future<File?> compressAndPrepareImage(File image) async {
    try {
      // الحصول على حجم الصورة الأصلية
      final originalSize = await image.length();
      print('حجم الصورة الأصلية: ${originalSize ~/ 1024} كيلوبايت');

      // في حالة كانت الصورة صغيرة بما يكفي، ارجع الصورة كما هي
      if (originalSize < 500 * 1024) { // أقل من 500KB
        return image;
      }

      // استخراج مسار مؤقت جديد لتخزين الصورة المضغوطة
      final tempDir = await path_provider.getTemporaryDirectory();
      final tempPath = path.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

      // ضغط الصورة
      final result = await FlutterImageCompress.compressAndGetFile(
        image.absolute.path,
        tempPath,
        quality: 70, // جودة الضغط (0-100)
        minWidth: 1024, // العرض الأدنى
        minHeight: 1024, // الارتفاع الأدنى
      );

      if (result != null) {
        final compressedSize = await result.length();
        print('حجم الصورة بعد الضغط: ${compressedSize ~/ 1024} كيلوبايت');
        return File(result.path);
      }
      
      return image;
    } catch (e) {
      print('خطأ في ضغط الصورة: $e');
      return image; // إرجاع الصورة الأصلية في حالة حدوث خطأ
    }
  }

  // حفظ الصورة محليًا
  static Future<File?> saveImageLocally(File imageFile, String fileName) async {
    try {
      final directory = await path_provider.getApplicationDocumentsDirectory();
      final String filePath = path.join(directory.path, fileName);
      
      // نسخ الصورة إلى المسار المحدد
      return await imageFile.copy(filePath);
    } catch (e) {
      print('خطأ في حفظ الصورة محليًا: $e');
      return null;
    }
  }

  // عرض خيارات مصدر الصورة (كاميرا أو معرض)
  static Future<File?> showImageSourceActionSheet(BuildContext context) async {
    File? selectedImage;
    
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('اختيار من المعرض'),
                onTap: () async {
                  Navigator.pop(context);
                  selectedImage = await pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('التقاط صورة جديدة'),
                onTap: () async {
                  Navigator.pop(context);
                  selectedImage = await takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
    
    return selectedImage;
  }

  // تحويل مسار الصورة النسبي إلى مسار كامل
  static String getFullImageUrl(String imagePath, String baseUrl) {
    if (imagePath.isEmpty || imagePath == 'default-profile.jpg') {
      return 'https://via.placeholder.com/150';
    }
    
    // إذا كان المسار يبدأ بـ http فهو مسار كامل بالفعل
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    
    // إذا كان المسار يبدأ بـ / قم بإزالة الشرطة الأولى لتجنب الـ //
    String path = imagePath;
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    
    // بناء المسار الكامل
    String fullUrl = baseUrl;
    if (baseUrl.endsWith('/api')) {
      // إذا كان العنوان ينتهي بـ /api قم بإزالته
      fullUrl = baseUrl.substring(0, baseUrl.length - 4);
    }
    
    return '$fullUrl/$path';
  }
}