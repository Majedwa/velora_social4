import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notification_provider.dart'; 
import '../../providers/story_provider.dart';
import 'feed_screen.dart';
import '../post/create_post_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../chat/conversations_screen.dart';
import '../notification/notification_screen.dart';
import '../story/stories_screen.dart';
import '../diagnostics/image_diagnostics_screen.dart';
import '../auth/login_screen.dart';
import '../../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    // Inicializar datos al cargar la pantalla
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    // Cargar notificaciones
    await Provider.of<NotificationProvider>(context, listen: false).refreshNotifications();
    
    // Cargar historias
    await Provider.of<StoryProvider>(context, listen: false).refreshStories();
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    
    // Lista de pantallas disponibles en la navegación principal
    final List<Widget> screens = [
      const FeedScreen(),
      const SearchScreen(),
      const SizedBox.shrink(), // Será reemplazado por la ventana de crear post
      const ConversationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('الشبكة الاجتماعية'),
        actions: [
          // Botón de notificaciones con indicador
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
              ),
              if (notificationProvider.unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      notificationProvider.unreadCount > 9
                          ? '9+'
                          : notificationProvider.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          
          // Botón de historias
          IconButton(
            icon: const Icon(Icons.auto_stories),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StoriesScreen(),
                ),
              );
            },
          ),
          
          // Botón de cambio de tema
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          
          // Botón de diagnóstico (solo para desarrollo)
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              _showDiagnosticsScreen();
            },
          ),
          
          // Botón de salir
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              _showLogoutDialog();
            },
          ),
        ],
      ),
      body: _currentIndex == 2 
          ? const SizedBox.shrink() 
          : screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex == 2 ? 0 : _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (index) {
          if (index == 2) {
            _showCreatePostModal();
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'البحث',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'إضافة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'المحادثات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'الملف الشخصي',
          ),
        ],
      ),
    );
  }

  void _showCreatePostModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );
  }
  
  void _showDiagnosticsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ImageDiagnosticsScreen(),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('تسجيل الخروج'),
              onPressed: () async {
                Navigator.of(context).pop(); // إغلاق الحوار
                
                // تسجيل الخروج
                await Provider.of<AuthProvider>(context, listen: false).logout();
                
                // إعادة التوجيه إلى شاشة تسجيل الدخول
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}