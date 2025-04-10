import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import 'profile_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late TextEditingController _searchController;
  List<User> _users = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fetchUsers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // هنا نفترض وجود دالة لجلب المستخدمين من AuthProvider
      // في التطبيق الحقيقي يمكنك إضافتها أو إنشاء مزود خاص للمستخدمين
      final response = await Provider.of<AuthProvider>(context, listen: false).getUsers();
      
      if (response['success']) {
        setState(() {
          _users = response['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ أثناء جلب المستخدمين';
        _isLoading = false;
      });
    }
  }
  
  List<User> _getFilteredUsers() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      return _users;
    }
    
    return _users.where((user) => 
      user.username.toLowerCase().contains(query) ||
      user.email.toLowerCase().contains(query)
    ).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id ?? '';
    final filteredUsers = _getFilteredUsers();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('المستخدمين'),
      ),
      body: Column(
        children: [
          // مربع البحث
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن مستخدمين',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          
          // حالة التحميل
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          
          // رسالة خطأ
          else if (_error != null)
            Center(child: Text(_error!))
          
          // لا توجد نتائج
          else if (filteredUsers.isEmpty)
            const Center(child: Text('لا توجد نتائج'))
          
          // قائمة المستخدمين
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  final isCurrentUser = user.id == currentUserId;
                  final isFollowing = authProvider.user?.following.contains(user.id) ?? false;
                  
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
                            // متابعة/إلغاء متابعة المستخدم
                            if (isFollowing) {
                              authProvider.unfollowUser(user.id);
                            } else {
                              authProvider.followUser(user.id);
                            }
                          },
                          child: Text(isFollowing ? 'إلغاء المتابعة' : 'متابعة'),
                        ),
                    onTap: () {
                      // الانتقال إلى صفحة الملف الشخصي للمستخدم
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(userId: user.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}