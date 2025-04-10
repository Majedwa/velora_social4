import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/story.dart';
import '../../providers/auth_provider.dart';
import '../../providers/story_provider.dart';
import '../../widgets/common/network_image.dart';

class StoryViewScreen extends StatefulWidget {
  final Story story;
  final String userName;
  final String userProfilePicture;

  const StoryViewScreen({
    Key? key,
    required this.story,
    required this.userName,
    required this.userProfilePicture,
  }) : super(key: key);

  @override
  _StoryViewScreenState createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentIndex = 0;
  List<StoryItem> _validItems = [];

  @override
  void initState() {
    super.initState();
    
    // الحصول على جميع العناصر الصالحة
    _validItems = widget.story.validItems;
    
    // تهيئة وحدة التحكم بالصفحات
    _pageController = PageController();
    
    // تهيئة وحدة التحكم بالحركة لمؤشر التقدم
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // المدة القياسية لعرض كل قصة
    );
    
    _animationController.addStatusListener(_handleAnimationStatus);
    
    // تعليم القصة الأولى كمشاهدة
    _markCurrentStoryAsViewed();
    
    // بدء الحركة
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.removeStatusListener(_handleAnimationStatus);
    _animationController.dispose();
    super.dispose();
  }

  // معالجة حالة الحركة
  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // الانتقال إلى العنصر التالي
      _nextStory();
    }
  }

  // الانتقال إلى العنصر التالي
  void _nextStory() {
    if (_currentIndex < _validItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // إغلاق الشاشة عند الانتهاء من جميع العناصر
      Navigator.pop(context);
    }
  }

  // الانتقال إلى العنصر السابق
  void _previousStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // إغلاق الشاشة عند الضغط على السابق في العنصر الأول
      Navigator.pop(context);
    }
  }

  // تعليم القصة الحالية كمشاهدة
  // تعليم القصة الحالية كمشاهدة
  void _markCurrentStoryAsViewed() {
    if (_currentIndex < _validItems.length) {
      final storyItem = _validItems[_currentIndex];
      final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.id;
      
      if (currentUserId != null && !storyItem.isViewedBy(currentUserId)) {
        Provider.of<StoryProvider>(context, listen: false)
            .markStoryAsViewed(widget.story.id, storyItem.id);
      }
    }
  }

  // إيقاف مؤقت/استئناف الحركة
  void _toggleAnimation() {
    if (_animationController.isAnimating) {
      _animationController.stop();
    } else {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_validItems.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('لا توجد عناصر صالحة في هذه القصة'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          // تقسيم الشاشة إلى نصفين
          final screenWidth = MediaQuery.of(context).size.width;
          final tapPosition = details.globalPosition.dx;
          
          if (tapPosition < screenWidth * 0.3) {
            // الضغط على الجزء الأيسر
            _previousStory();
          } else if (tapPosition > screenWidth * 0.7) {
            // الضغط على الجزء الأيمن
            _nextStory();
          } else {
            // الضغط في المنتصف
            _toggleAnimation();
          }
        },
        onLongPressStart: (_) {
          // إيقاف مؤقت عند الضغط المطول
          _animationController.stop();
        },
        onLongPressEnd: (_) {
          // استئناف بعد رفع الإصبع
          _animationController.forward();
        },
        child: Stack(
          children: [
            // عرض محتوى القصة
            PageView.builder(
              controller: _pageController,
              itemCount: _validItems.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _animationController.reset();
                  _markCurrentStoryAsViewed();
                  _animationController.forward();
                });
              },
              itemBuilder: (context, index) {
                final item = _validItems[index];
                return _buildStoryItemContent(item);
              },
            ),
            
            // شريط التقدم في الأعلى
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(
                  _validItems.length,
                  (index) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: LinearProgressIndicator(
                        value: _currentIndex == index
                            ? _animationController.value
                            : _currentIndex > index
                                ? 1.0
                                : 0.0,
                        backgroundColor: Colors.white.withOpacity(0.4),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // معلومات المستخدم في الأعلى
            Positioned(
              top: MediaQuery.of(context).padding.top + 24,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: NetworkImage(widget.userProfilePicture),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getTimeAgo(_validItems[_currentIndex].createdAt),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء محتوى عنصر القصة حسب النوع
  Widget _buildStoryItemContent(StoryItem item) {
    switch (item.type) {
      case StoryType.text:
        // قصة نصية
        final backgroundColor = item.metadata?['backgroundColor'] != null
            ? Color(item.metadata!['backgroundColor'])
            : Colors.blue;
        
        final fontColor = item.metadata?['fontColor'] != null
            ? Color(item.metadata!['fontColor'])
            : Colors.white;
        
        final fontSize = item.metadata?['fontSize'] != null
            ? (item.metadata!['fontSize'] as num).toDouble()
            : 24.0;
        
        return Container(
          color: backgroundColor,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              item.content,
              style: TextStyle(
                color: fontColor,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      
      case StoryType.image:
        // قصة صورة
        final caption = item.metadata?['caption'];
        
        return Stack(
          fit: StackFit.expand,
          children: [
            // عرض الصورة
            _buildImageWidget(item.content),
            
            // عرض التعليق (إذا وجد)
            if (caption != null && caption.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 80,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      
      case StoryType.video:
        // قصة فيديو (يمكن تنفيذها لاحقًا)
        return const Center(
          child: Text(
            'قصة فيديو غير مدعومة حاليًا',
            style: TextStyle(color: Colors.white),
          ),
        );
      
      default:
        return const Center(
          child: Text(
            'نوع قصة غير معروف',
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }

  // بناء عنصر الصورة (محلية أو من الخادم)
  Widget _buildImageWidget(String content) {
    if (content.startsWith('/')) {
      // صورة محلية
      return Image.file(
        File(content),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[900],
            child: const Center(
              child: Icon(Icons.error, color: Colors.red, size: 48),
            ),
          );
        },
      );
    } else {
      // صورة من الخادم
      return NetworkImageWithPlaceholder(
        imageUrl: content,
        height: double.infinity,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
  }

  // الحصول على الوقت المنقضي منذ نشر القصة
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }
}