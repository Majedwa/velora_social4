import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../services/image_service.dart';
import '../../widgets/common/network_image.dart';
import '../../widgets/common/custom_button.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  File? _image;
  bool _isLoading = false;
  String? _imageError;
  
  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    setState(() {
      _imageError = null;
    });
    
    try {
      final File? selectedImage = await ImageService.showImageSourceActionSheet(context);
      
      if (selectedImage != null) {
        setState(() {
          _image = selectedImage;
        });
      }
    } catch (e) {
      setState(() {
        _imageError = 'حدث خطأ أثناء اختيار الصورة: $e';
      });
      print(_imageError);
    }
  }
  
  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة محتوى للمنشور')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await Provider.of<PostProvider>(context, listen: false).createPost(
        _contentController.text.trim(),
        image: _image,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء المنشور بنجاح')),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        final error = Provider.of<PostProvider>(context, listen: false).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'فشل في إنشاء المنشور')),
        );
      }
    } catch (e) {
      print('خطأ في إنشاء المنشور: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إنشاء المنشور: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('منشور جديد'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _createPost,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'نشر',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // معلومات المستخدم
            if (user != null)
              ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(
                    child: NetworkImageWithPlaceholder(
                      imageUrl: user.profilePicture,
                      width: 48,
                      height: 48,
                    ),
                  ),
                ),
                title: Text(
                  user.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: const Text('منشور عام'),
              ),
            
            // محتوى المنشور
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'ماذا يدور في ذهنك؟',
                  border: InputBorder.none,
                ),
                maxLines: 8,
                maxLength: 500,
              ),
            ),
            
            // معاينة الصورة إذا تم اختيارها
            if (_image != null)
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(_image!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.black.withOpacity(0.7),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                        onPressed: () {
                          setState(() {
                            _image = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            
            // رسالة خطأ الصورة (إذا وجدت)
            if (_imageError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _imageError!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // أزرار الإضافات
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: IconButton(
                      icon: Icon(Icons.image, color: AppTheme.primaryColor),
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}