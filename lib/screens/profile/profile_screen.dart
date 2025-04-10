import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../models/post.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/post/post_card.dart';
import '../../theme.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // إذا كان null، سيتم عرض الملف الشخصي للمستخدم الحالي
  
  const ProfileScreen({Key? key, this.userId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _isGridView = false; // للتبديل بين عرض القائمة وعرض الشبكة
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    
    // تحميل بيانات المستخدم (الحالي أو الآخر)
    if (widget.userId != null && widget.userId != authProvider.user?.id) {
      // تحميل بيانات مستخدم آخر
      await authProvider.getUserProfile(widget.userId!);
      // تحميل منشورات المستخدم
      await postProvider.fetchUserPosts(widget.userId!);
    } else {
      // تحميل منشورات المستخدم الحالي
      if (authProvider.user != null) {
        await postProvider.fetchUserPosts(authProvider.user!.id);
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    
    final currentUser = authProvider.user;
    final profileUser = widget.userId != null && widget.userId != currentUser?.id
      ? authProvider.viewedUser
      : currentUser;
    
    final isCurrentUserProfile = widget.userId == null || widget.userId == currentUser?.id;
    
    if (_isLoading || profileUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الملف الشخصي')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final isFollowing = currentUser?.following.contains(profileUser.id) ?? false;
    
    // حساب إحصائيات إضافية
    final posts = postProvider.posts;
    int totalLikes = 0;
    int totalComments = 0;
    
    for (var post in posts) {
      totalLikes += post.likes.length;
      totalComments += post.comments.length;
    }
    
    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                actions: [
                  // زر التبديل بين عرض القائمة والشبكة
                  if (isCurrentUserProfile)
                    IconButton(
                      icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                      onPressed: () {
                        setState(() {
                          _isGridView = !_isGridView;
                        });
                      },
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(profileUser.profilePicture),
                            backgroundColor: Colors.grey[200],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            profileUser.username,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            profileUser.bio.isNotEmpty ? profileUser.bio : 'لا توجد نبذة',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // معلومات المستخدم - صف أول
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn(posts.length.toString(), 'المنشورات'),
                          _buildStatColumn(profileUser.followers.length.toString(), 'المتابعين'),
                          _buildStatColumn(profileUser.following.length.toString(), 'المتابَعين'),
                        ],
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // معلومات المستخدم - صف ثاني
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn(totalLikes.toString(), 'الإعجابات'),
                          _buildStatColumn(totalComments.toString(), 'التعليقات'),
                          _buildStatColumn(_calculateEngagementRate(totalLikes, posts.length), 'معدل التفاعل'),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // زر متابعة/تعديل الملف الشخصي
                      SizedBox(
                        width: double.infinity,
                        child: isCurrentUserProfile
                            ? OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const EditProfileScreen(),
                                    ),
                                  ).then((_) => _loadUserData());
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Theme.of(context).primaryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('تعديل الملف الشخصي'),
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  if (isFollowing) {
                                    authProvider.unfollowUser(profileUser.id).then((_) {
                                      setState(() {});
                                    });
                                  } else {
                                    authProvider.followUser(profileUser.id).then((_) {
                                      setState(() {});
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFollowing ? Colors.grey[300] : Theme.of(context).primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(isFollowing ? 'إلغاء المتابعة' : 'متابعة'),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).primaryColor,
                    tabs: const [
                      Tab(text: 'المنشورات'),
                      Tab(text: 'المتابِعون'),
                      Tab(text: 'المتابَعون'),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // المنشورات - عرض قائمة أو شبكة
              _isGridView 
                ? _buildGridView(posts, currentUser?.id ?? '')
                : _buildListView(posts, currentUser?.id ?? '', postProvider),
              
              // المتابِعون
              _buildFollowersList(profileUser.followers),
              
              // المتابَعون
              _buildFollowingList(profileUser.following),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
  
  // حساب معدل التفاعل
  String _calculateEngagementRate(int likes, int postsCount) {
    if (postsCount == 0) return '0%';
    
    double rate = (likes / postsCount) / 10;
    return '${rate.toStringAsFixed(1)}%';
  }
  
  // بناء عرض الشبكة للمنشورات
  Widget _buildGridView(List<Post> posts, String currentUserId) {
    if (posts.isEmpty) {
      return const Center(child: Text('لا توجد منشورات'));
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        
        // إذا كان هناك صورة، نعرضها، وإلا نعرض مربعًا يحتوي على بداية المحتوى النصي
        return GestureDetector(
          onTap: () {
            // عند النقر، عرض تفاصيل المنشور
            _showPostDetails(post, currentUserId);
          },
          child: post.image != null && post.image!.isNotEmpty
            ? Image.network(
                post.image!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, color: Colors.white),
                  );
                },
              )
            : Container(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      post.content.length > 50 
                        ? '${post.content.substring(0, 50)}...'
                        : post.content,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
        );
      },
    );
  }
  
  // عرض تفاصيل المنشور (عند النقر على صورة من الشبكة)
  void _showPostDetails(Post post, String currentUserId) {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ListView(
                controller: scrollController,
                children: [
                  AppBar(
                    title: const Text('تفاصيل المنشور'),
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  PostCard(
                    post: post,
                    currentUserId: currentUserId,
                    onLike: () => postProvider.likePost(post.id),
                    onUnlike: () => postProvider.unlikePost(post.id),
                    onComment: (text) => postProvider.addComment(post.id, text),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  // بناء عرض القائمة للمنشورات
  Widget _buildListView(List<Post> posts, String currentUserId, PostProvider postProvider) {
    if (posts.isEmpty) {
      return const Center(child: Text('لا توجد منشورات'));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return PostCard(
          post: post,
          currentUserId: currentUserId,
          onLike: () => postProvider.likePost(post.id),
          onUnlike: () => postProvider.unlikePost(post.id),
          onComment: (text) => postProvider.addComment(post.id, text),
        );
      },
    );
  }
  
  Widget _buildFollowersList(List<String> followers) {
    if (followers.isEmpty) {
      return const Center(child: Text('لا يوجد متابعون'));
    }
    
    return FutureBuilder<List<User>>(
      future: Provider.of<AuthProvider>(context, listen: false).getMultipleUsers(followers),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا يوجد متابعون'));
        }
        
        final List<User> users = snapshot.data!;
        
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserListItem(user);
          },
        );
      },
    );
  }
  
  Widget _buildFollowingList(List<String> following) {
    if (following.isEmpty) {
      return const Center(child: Text('لا يوجد متابَعون'));
    }
    
    return FutureBuilder<List<User>>(
      future: Provider.of<AuthProvider>(context, listen: false).getMultipleUsers(following),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا يوجد متابَعون'));
        }
        
        final List<User> users = snapshot.data!;
        
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserListItem(user);
          },
        );
      },
    );
  }
  
  Widget _buildUserListItem(User user) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;
    final isCurrentUser = user.id == currentUser?.id;
    final isFollowing = currentUser?.following.contains(user.id) ?? false;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(user.profilePicture),
      ),
      title: Text(user.username),
      subtitle: Text(user.bio.isEmpty ? 'لا توجد نبذة' : user.bio),
      trailing: isCurrentUser
          ? null
          : TextButton(
              onPressed: () {
                if (isFollowing) {
                  authProvider.unfollowUser(user.id).then((_) {
                    setState(() {});
                  });
                } else {
                  authProvider.followUser(user.id).then((_) {
                    setState(() {});
                  });
                }
              },
              child: Text(isFollowing ? 'إلغاء المتابعة' : 'متابعة'),
            ),
      onTap: () {
        if (!isCurrentUser) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: user.id),
            ),
          );
        }
      },
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}