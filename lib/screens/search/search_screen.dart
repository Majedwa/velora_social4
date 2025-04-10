import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../profile/profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    
    try {
      final results = await Provider.of<AuthProvider>(context, listen: false).searchUsers(query);
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      print('خطأ في البحث: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // مربع البحث
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'البحث عن مستخدمين',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                if (value.length > 2) {
                  _searchUsers(value);
                } else if (value.isEmpty) {
                  _searchUsers('');
                }
              },
            ),
          ),
          
          // نتائج البحث
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.search, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'ابحث عن أصدقائك',
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(height: 8),
                            Text('اكتب اسم المستخدم للبحث'),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? const Center(child: Text('لا توجد نتائج لهذا البحث'))
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(user.profilePicture),
                                ),
                                title: Text(user.username),
                                subtitle: Text(user.bio.isEmpty ? 'لا توجد نبذة' : user.bio),
                                onTap: () {
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