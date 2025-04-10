import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/post.dart';
import '../../providers/favorite_provider.dart';
import '../../theme.dart';
import '../../utils/time_util.dart';
import '../../screens/profile/profile_screen.dart';
import '../../widgets/common/network_image.dart';
import '../../api/api_service.dart';
import 'carousel_images.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final String currentUserId;
  final Function onLike;
  final Function onUnlike;
  final Function(String) onComment;
  final VoidCallback? onDelete;

  const PostCard({
    Key? key,
    required this.post,
    required this.currentUserId,
    required this.onLike,
    required this.onUnlike,
    required this.onComment,
    this.onDelete,
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  final _commentController = TextEditingController();
  bool _showComments = false;
  late AnimationController _controller;
  bool _isLikeLoading = false;
  bool _isCommentLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showPostOptions(BuildContext context) {
    final bool isOwnPost = widget.post.userId == widget.currentUserId;
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (isOwnPost)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('حذف المنشور'),
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onDelete != null) {
                      widget.onDelete!();
                    }
                  },
                ),
              if (isOwnPost)
                ListTile(
                  leading: const Icon(Icons.push_pin),
                  title: Text(
                    widget.post.isFeatured 
                      ? 'إلغاء تثبيت المنشور' 
                      : 'تثبيت المنشور',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // تنفيذ تثبيت/إلغاء تثبيت المنشور
                    // يمكن إضافة هذه الوظيفة لاحقًا
                  },
                ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('مشاركة المنشور'),
                onTap: () {
                  Navigator.pop(context);
                  _sharePost();
                },
              ),
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('الإبلاغ عن المنشور'),
                onTap: () {
                  Navigator.pop(context);
                  // تنفيذ الإبلاغ عن المنشور
                  // يمكن إضافة هذه الوظيفة لاحقًا
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال البلاغ، شكرًا لمساعدتك في تحسين المحتوى'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // مشاركة المنشور
  void _sharePost() {
    // بناء نص المشاركة
    final String shareText = '${widget.post.username} كتب: ${widget.post.content}';
    
    // إضافة رابط إلى التطبيق (في التطبيق الحقيقي، يمكن استخدام رابط دينامي)
    const String appLink = 'https://example.com/posts/';
    
    // مشاركة المنشور
    Share.share('$shareText\n\n$appLink${widget.post.id}');
  }

  Future<void> _handleLike() async {
    if (_isLikeLoading) return;

    setState(() {
      _isLikeLoading = true;
    });

    try {
      final isLiked = widget.post.likes.contains(widget.currentUserId);
      
      if (isLiked) {
        await widget.onUnlike();
      } else {
        await widget.onLike();
        _controller.forward().then((_) => _controller.reverse());
      }
    } catch (e) {
      print('خطأ في التفاعل مع المنشور: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLikeLoading = false;
        });
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty || _isCommentLoading) return;

    setState(() {
      _isCommentLoading = true;
    });

    try {
      await widget.onComment(_commentController.text.trim());
      _commentController.clear();
    } catch (e) {
      print('خطأ في إضافة تعليق: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCommentLoading = false;
        });
      }
    }
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        
        // عنوان قسم التعليقات
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'التعليقات (${widget.post.comments.length})',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        
        // قائمة التعليقات
        if (widget.post.comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('لا توجد تعليقات بعد. كن أول من يعلق!'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.post.comments.length,
            itemBuilder: (context, index) {
              final comment = widget.post.comments[index];
              return ListTile(
                leading: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(userId: comment.userId),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[200],
                    child: ClipOval(
                      child: NetworkImageWithPlaceholder(
                        imageUrl: comment.userProfilePicture,
                        width: 32,
                        height: 32,
                      ),
                    ),
                  ),
                ),
                title: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: comment.username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      TextSpan(
                        text: '  ${comment.text}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                subtitle: Text(
                  timeAgo(comment.createdAt),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        
        // حقل إضافة تعليق جديد
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'أضف تعليقاً...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: _isCommentLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 18),
                        onPressed: _addComment,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionButton({
    required IconData icon, 
    required String text, 
    required VoidCallback onTap,
    Color? color,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: color ?? Theme.of(context).primaryColor,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(text),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      final bool isLiked = widget.post.likes.contains(widget.currentUserId);
      final favoriteProvider = Provider.of<FavoriteProvider>(context);
      final bool isFavorite = favoriteProvider.isFavorite(widget.post.id);
      
      // تحضير قائمة الصور للعرض
      List<String> displayImages = [];
      
      // أولاً نضيف الصور من قائمة images إذا وجدت
      if (widget.post.images.isNotEmpty) {
        displayImages = List.from(widget.post.images);
      } 
      // وإلا نضيف الصورة الفردية إذا وجدت (للتوافقية مع الكود القديم)
      else if (widget.post.image != null && widget.post.image!.isNotEmpty) {
        displayImages.add(widget.post.image!);
      }
      
      // إذا كان المنشور مثبتًا، نضيف شريط للإشارة إلى ذلك
      Widget pinnedIndicator = const SizedBox.shrink();
      if (widget.post.isFeatured) {
        pinnedIndicator = Container(
          width: double.infinity,
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.push_pin,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                'منشور مثبت',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }
      
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // مؤشر التثبيت
            pinnedIndicator,
            
            // رأس المنشور مع معلومات المستخدم
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              leading: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(userId: widget.post.userId),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  child: ClipOval(
                    child: NetworkImageWithPlaceholder(
                      imageUrl: widget.post.userProfilePicture,
                      width: 40,
                      height: 40,
                    ),
                  ),
                ),
              ),
              title: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(userId: widget.post.userId),
                    ),
                  );
                },
                child: Text(
                  widget.post.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              subtitle: Text(
                timeAgo(widget.post.createdAt),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  _showPostOptions(context);
                },
              ),
            ),
            
            // محتوى المنشور
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                widget.post.content,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            
            // صور المنشور (Carousel)
            if (displayImages.isNotEmpty)
              CarouselImages(
                imageUrls: displayImages,
                height: 300,
              ),
            
            // أزرار التفاعل
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // زر الإعجاب
                  _buildInteractionButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : null,
                    text: widget.post.likes.length.toString(),
                    isLoading: _isLikeLoading,
                    onTap: _handleLike,
                  ),
                  
                  // زر التعليقات
                  _buildInteractionButton(
                    icon: Icons.comment_outlined,
                    text: widget.post.comments.length.toString(),
                    onTap: () {
                      setState(() {
                        _showComments = !_showComments;
                      });
                    },
                  ),
                  
                  // زر المشاركة
                  _buildInteractionButton(
                    icon: Icons.share_outlined,
                    text: 'مشاركة',
                    onTap: _sharePost,
                  ),
                  
                  // زر المفضلة
                  _buildInteractionButton(
                    icon: isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    color: isFavorite ? Colors.amber : null,
                    text: isFavorite ? 'محفوظ' : 'حفظ',
                    onTap: () {
                      favoriteProvider.toggleFavorite(widget.post);
                    },
                  ),
                ],
              ),
            ),
            
            // قسم التعليقات
            if (_showComments) 
              _buildCommentsSection(),
          ],
        ),
      );
    } catch (e) {
      print('خطأ في بناء بطاقة المنشور: $e');
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('حدث خطأ في عرض هذا المنشور: $e'),
        ),
      );
    }
  }
}