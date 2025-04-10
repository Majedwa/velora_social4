import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/post/post_card.dart';
import '../search/search_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadPosts();
    
    // إضافة مستمع للتمرير لتحميل المزيد من المنشورات
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  // استماع لأحداث التمرير لتحميل المزيد من المنشورات
  void _scrollListener() {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        !postProvider.loading &&
        !postProvider.loadingMore &&
        postProvider.hasMorePosts) {
      postProvider.loadMorePosts();
    }
  }
  
  Future<void> _loadPosts() async {
    await Provider.of<PostProvider>(context, listen: false).fetchPosts(refresh: true);
  }

  void _showSortOptions() {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: const Text('ترتيب حسب الأحدث'),
                leading: const Icon(Icons.access_time),
                selected: postProvider.currentSortOption == SortOption.latest,
                onTap: () {
                  postProvider.setSortOption(SortOption.latest);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('ترتيب حسب الأكثر إعجابًا'),
                leading: const Icon(Icons.favorite),
                selected: postProvider.currentSortOption == SortOption.mostLiked,
                onTap: () {
                  postProvider.setSortOption(SortOption.mostLiked);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('آخر المنشورات'),
        actions: [
          // زر ترتيب المنشورات
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            tooltip: 'ترتيب المنشورات',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadPosts(),
        child: postProvider.loading && postProvider.posts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : postProvider.error != null && postProvider.posts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'حدث خطأ: ${postProvider.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPosts,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  )
                : postProvider.posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.post_add, size: 80, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد منشورات بعد',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text('ابدأ بمتابعة أصدقائك أو أنشئ منشورًا جديدًا'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                // التنقل إلى شاشة البحث عن المستخدمين
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SearchScreen(),
                                  ),
                                );
                              },
                              child: const Text('البحث عن أصدقاء'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: postProvider.posts.length + (postProvider.loadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // عرض مؤشر التحميل في نهاية القائمة
                          if (index == postProvider.posts.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          
                          final post = postProvider.posts[index];
                          return PostCard(
                            post: post,
                            currentUserId: currentUserId,
                            onLike: () => postProvider.likePost(post.id),
                            onUnlike: () => postProvider.unlikePost(post.id),
                            onComment: (text) => postProvider.addComment(post.id, text),
                          );
                        },
                      ),
      ),
    );
  }
}