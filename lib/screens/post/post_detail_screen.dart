import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/post/post_card.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  
  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id ?? '';
    
    // البحث عن المنشور المحدد
    final Post? post = postProvider.posts.firstWhere(
      (post) => post.id == widget.postId,
      orElse: () => null as Post,
    );
    
    if (post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل المنشور')),
        body: const Center(child: Text('المنشور غير موجود')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المنشور')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // عرض المنشور كاملاً
            PostCard(
              post: post,
              currentUserId: currentUserId,
              onLike: () => postProvider.likePost(post.id),
              onUnlike: () => postProvider.unlikePost(post.id),
              onComment: (text) => postProvider.addComment(post.id, text),
            ),
            
            // قسم للتعليقات
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'التعليقات (${post.comments.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // إضافة تعليق جديد
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'أضف تعليقاً...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          if (_commentController.text.isNotEmpty) {
                            postProvider.addComment(post.id, _commentController.text.trim());
                            _commentController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // قائمة التعليقات
                  ...post.comments.map((comment) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(comment.userProfilePicture),
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    comment.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${DateTime.now().difference(comment.createdAt).inDays}d',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(comment.text),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}