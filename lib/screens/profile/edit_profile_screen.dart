import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../services/image_service.dart';
import '../../widgets/common/network_image.dart';
import '../../widgets/common/custom_button.dart';
import '../../api/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  File? _profileImage;
  bool _isLoading = false;
  String? _imageError;
  
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _bioController.text = authProvider.user?.bio ?? '';
  }

  @override
  void dispose() {
    _bioController.dispose();
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
          _profileImage = selectedImage;
        });
      }
    } catch (e) {
      setState(() {
        _imageError = 'حدث خطأ أثناء اختيار الصورة: $e';
      });
      print(_imageError);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _imageError = null;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.updateProfile(_bioController.text, _profileImage);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error ?? 'فشل في تحديث الملف الشخصي')),
        );
      }
    } catch (e) {
      print('خطأ في تحديث الملف الشخصي: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تحديث الملف الشخصي: $e')),
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
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // صورة الملف الشخصي
            Center(
              child: Stack(
                children: [
                  if (_profileImage != null)
                    // عرض الصورة المختارة
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: FileImage(_profileImage!),
                      backgroundColor: Colors.grey[200],
                    )
                  else
                    // عرض الصورة الحالية
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      child: ClipOval(
                        child: NetworkImageWithPlaceholder(
                          imageUrl: user.profilePicture,
                          width: 120,
                          height: 120,
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
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
            
            const SizedBox(height: 32),
            
            // اسم المستخدم (للعرض فقط)
            TextFormField(
              initialValue: user.username,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم',
                helperText: 'لا يمكن تغيير اسم المستخدم',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // البريد الإلكتروني (للعرض فقط)
            TextFormField(
              initialValue: user.email,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                helperText: 'لا يمكن تغيير البريد الإلكتروني',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // النبذة الشخصية
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'النبذة الشخصية',
                hintText: 'اكتب نبذة قصيرة عنك',
                prefixIcon: Icon(Icons.info_outline),
              ),
              maxLines: 3,
              maxLength: 150,
            ),
            
            const SizedBox(height: 32),
            
            // زر تأكيد التحديث
            CustomButton(
              text: 'تحديث الملف الشخصي',
              isLoading: _isLoading,
              onPressed: _updateProfile,
              color: AppTheme.primaryColor,
            ),
            
            const SizedBox(height: 16),
            
            // زر إلغاء
            if (!_isLoading)
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('إلغاء'),
              ),
          ],
        ),
      ),
    );
  }
}