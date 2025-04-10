import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/story.dart';
import '../../providers/story_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/story/story_circle.dart';
import 'create_story_screen.dart';
import 'story_view_screen.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({Key? key}) : super(key: key);

  @override
  _StoriesScreenState createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  @override
  void initState() {
    super.initState();
    // تحميل القصص عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StoryProvider>(context, listen: false).refreshStories();
    });
  }

  void _navigateToCreateStory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateStoryScreen(),
      ),
    );
  }

  void _navigateToViewStory(String userId, String username, String profilePicture) {
    final storyProvider = Provider.of<StoryProvider>(context, listen: false);
    final story = storyProvider.getStoryByUserId(userId);
    
    if (story != null && story.validItems.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryViewScreen(
            story: story,
            userName: username,
            userProfilePicture: profilePicture,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final storyProvider = Provider.of<StoryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;
    
    if (currentUser == null) {
      return const Center(
        child: Text('الرجاء تسجيل الدخول لعرض القصص'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('القصص'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => storyProvider.refreshStories(),
            tooltip: 'تحديث القصص',
          ),
        ],
      ),
      body: storyProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : storyProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('حدث خطأ: ${storyProvider.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => storyProvider.refreshStories(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _buildStoriesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateStory,
        child: const Icon(Icons.add),
        tooltip: 'إضافة قصة جديدة',
      ),
    );
  }

  Widget _buildStoriesList() {
    final storyProvider = Provider.of<StoryProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user!;
    
    // القصص المتاحة (مع استبعاد القصص الفارغة)
    final availableStories = storyProvider.stories
        .where((story) => story.validItems.isNotEmpty)
        .toList();
    
    // قصة المستخدم الحالي
    final myStory = storyProvider.myStory;
    final hasMyStory = myStory != null && myStory.validItems.isNotEmpty;
    
    if (availableStories.isEmpty && !hasMyStory) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_filter,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد قصص حاليًا',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'كن أول من يشارك قصة!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToCreateStory,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('إضافة قصة جديدة'),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        const SizedBox(height: 16),
        
        // قصتي
        ListTile(
          leading: StoryCircle(
            imageUrl: currentUser.profilePicture,
            radius: 24,
            hasStory: hasMyStory,
            isViewed: true, // قصة المستخدم نفسه تعتبر مشاهدة
            onTap: hasMyStory
                ? () => _navigateToViewStory(
                      currentUser.id,
                      currentUser.username,
                      currentUser.profilePicture,
                    )
                : _navigateToCreateStory,
          ),
          title: const Text('قصتي'),
          subtitle: hasMyStory
              ? Text('${myStory!.validItems.length} عناصر')
              : const Text('انقر لإضافة قصة'),
          onTap: hasMyStory
              ? () => _navigateToViewStory(
                    currentUser.id,
                    currentUser.username,
                    currentUser.profilePicture,
                  )
              : _navigateToCreateStory,
        ),
        
        if (availableStories.isNotEmpty) const Divider(),
        
        // قصص الآخرين
        if (availableStories.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text(
              'قصص الأصدقاء',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        
        ...availableStories.map((story) {
          final isViewed = story.allViewedBy(currentUser.id);
          
          return ListTile(
            leading: StoryCircle(
              imageUrl: story.userProfilePicture,
              radius: 24,
              hasStory: true,
              isViewed: isViewed,
              onTap: () => _navigateToViewStory(
                story.userId,
                story.username,
                story.userProfilePicture,
              ),
            ),
            title: Text(story.username),
            subtitle: Text(
              isViewed
                  ? 'تمت المشاهدة'
                  : '${story.validItems.length} عناصر جديدة',
              style: TextStyle(
                color: isViewed
                    ? Theme.of(context).textTheme.bodySmall?.color
                    : Theme.of(context).primaryColor,
              ),
            ),
            onTap: () => _navigateToViewStory(
              story.userId,
              story.username,
              story.userProfilePicture,
            ),
          );
        }).toList(),
      ],
    );
  }
}