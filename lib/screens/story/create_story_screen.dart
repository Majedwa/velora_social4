import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/story_provider.dart';
import '../../models/story.dart';
import '../../services/image_service.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({Key? key}) : super(key: key);

  @override
  _CreateStoryScreenState createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final TextEditingController _textController = TextEditingController();
  File? _selectedImage;
  StoryType _storyType = StoryType.text;
  Color _backgroundColor = Colors.blue;
  bool _isLoading = false;
  
  // خيارات ألوان خلفية القصة النصية
  final List<Color> _backgroundColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImageService.showImageSourceActionSheet(context);
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _storyType = StoryType.image;
        });
      }
    } catch (e) {
      print('خطأ في اختيار الصورة: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في اختيار الصورة: $e')),
      );
    }
  }

  Future<void> _createTextStory() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال نص للقصة')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      
      final success = await storyProvider.addTextStory(
        text,
        metadata: {
          'backgroundColor': _backgroundColor.value,
          'fontColor': Colors.white.value,
          'fontSize': 24.0,
          'alignment': 'center',
        },
      );

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة القصة بنجاح')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في إضافة القصة')),
          );
        }
      }
    } catch (e) {
      print('خطأ في إضافة القصة النصية: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في إضافة القصة: $e')),
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

  Future<void> _createImageStory() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار صورة للقصة')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final storyProvider = Provider.of<StoryProvider>(context, listen: false);
      
      final success = await storyProvider.addImageStory(
        _selectedImage!,
        metadata: {
          'caption': _textController.text.trim(), // يمكن إضافة تعليق للصورة
        },
      );

      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إضافة القصة بنجاح')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في إضافة القصة')),
          );
        }
      }
    } catch (e) {
      print('خطأ في إضافة قصة الصورة: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في إضافة القصة: $e')),
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
  
  Future<void> _createStory() async {
    if (_storyType == StoryType.image) {
      await _createImageStory();
    } else {
      await _createTextStory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء قصة جديدة'),
        actions: [
          // تبديل نوع القصة
          IconButton(
            icon: Icon(
              _storyType == StoryType.text ? Icons.photo : Icons.text_fields,
            ),
            onPressed: () {
              setState(() {
                _storyType = _storyType == StoryType.text
                    ? StoryType.image
                    : StoryType.text;
                
                if (_storyType == StoryType.image && _selectedImage == null) {
                  _pickImage();
                }
              });
            },
            tooltip: _storyType == StoryType.text
                ? 'تبديل إلى قصة صورة'
                : 'تبديل إلى قصة نصية',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _storyType == StoryType.text
              ? _buildTextStoryEditor()
              : _buildImageStoryEditor(),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createStory,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _storyType == StoryType.text ? 'نشر قصة نصية' : 'نشر قصة صورة',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextStoryEditor() {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: _backgroundColor,
            padding: const EdgeInsets.all(16),
            child: Center(
              child: TextField(
                controller: _textController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
                maxLines: null, // لعدم محدود من الأسطر
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'اكتب نص القصة هنا...',
                  hintStyle: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ),
        // اختيار اللون
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _backgroundColors.length,
            itemBuilder: (context, index) {
              final color = _backgroundColors[index];
              final isSelected = color == _backgroundColor;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _backgroundColor = color;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageStoryEditor() {
    return Column(
      children: [
        Expanded(
          child: _selectedImage != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    // عرض الصورة المختارة
                    Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                    
                    // تراكب نصي في الأسفل
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.black.withOpacity(0.5),
                        child: TextField(
                          controller: _textController,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'أضف تعليقًا للصورة (اختياري)...',
                            hintStyle: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // زر اختيار صورة أخرى
                    Positioned(
                      top: 16,
                      right: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.photo_library, color: Colors.white),
                          onPressed: _pickImage,
                          tooltip: 'اختيار صورة أخرى',
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.photo_library,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'لم يتم اختيار صورة بعد',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('اختيار صورة'),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}