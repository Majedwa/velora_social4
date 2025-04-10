import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/post_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/message_provider.dart';
import 'providers/story_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // خدمة API الأساسية
        Provider<ApiService>(create: (_) => ApiService()),
        
        // مزود المصادقة
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // مزود المنشورات
        ChangeNotifierProvider(create: (_) => PostProvider()),
        
        // مزود السمات
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // مزود المفضلة
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        
        // مزودات الإشعارات والرسائل والقصص
        ChangeNotifierProxyProvider<ApiService, NotificationProvider>(
          create: (context) => NotificationProvider(
            Provider.of<ApiService>(context, listen: false)
          ),
          update: (context, api, previous) => previous ?? NotificationProvider(api),
        ),
        
        // مزود المحادثات - يعتمد على مزود المستخدم والإشعارات
        ChangeNotifierProxyProvider3<ApiService, AuthProvider, NotificationProvider, MessageProvider>(
          create: (context) => MessageProvider(
            Provider.of<ApiService>(context, listen: false),
            Provider.of<AuthProvider>(context, listen: false),
            Provider.of<NotificationProvider>(context, listen: false),
          ),
          update: (context, api, auth, notification, previous) => 
            previous ?? MessageProvider(api, auth, notification),
        ),
        
        // مزود القصص - يعتمد على مزود المستخدم
        ChangeNotifierProxyProvider2<ApiService, AuthProvider, StoryProvider>(
          create: (context) => StoryProvider(
            Provider.of<ApiService>(context, listen: false),
            Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, api, auth, previous) => 
            previous ?? StoryProvider(api, auth),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'تطبيق الشبكة الاجتماعية',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            home: Builder(
              builder: (context) {
                // التحقق من حالة تسجيل الدخول وعرض الشاشة المناسبة
                final authProvider = Provider.of<AuthProvider>(context);
                return authProvider.isAuthenticated ? const HomeScreen() : const LoginScreen();
              }
            ),
          );
        },
      ),
    );
  }
}