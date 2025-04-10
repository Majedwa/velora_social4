import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              CustomTextField(
                controller: _usernameController,
                labelText: 'اسم المستخدم',
                hintText: 'أدخل اسم المستخدم',
                prefixIcon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال اسم المستخدم';
                  }
                  if (value.length < 3) {
                    return 'اسم المستخدم يجب أن يكون 3 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _emailController,
                labelText: 'البريد الإلكتروني',
                hintText: 'أدخل بريدك الإلكتروني',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال البريد الإلكتروني';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'الرجاء إدخال بريد إلكتروني صالح';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _passwordController,
                labelText: 'كلمة المرور',
                hintText: 'أدخل كلمة المرور',
                prefixIcon: Icons.lock,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال كلمة المرور';
                  }
                  if (value.length < 6) {
                    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _confirmPasswordController,
                labelText: 'تأكيد كلمة المرور',
                hintText: 'أعد إدخال كلمة المرور',
                prefixIcon: Icons.lock,
                isPassword: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء تأكيد كلمة المرور';
                  }
                  if (value != _passwordController.text) {
                    return 'كلمتا المرور غير متطابقتين';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              if (authProvider.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    authProvider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              
              CustomButton(
                text: 'إنشاء حساب',
                isLoading: authProvider.loading,
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final success = await authProvider.register(
                      _usernameController.text.trim(),
                      _emailController.text.trim(),
                      _passwordController.text,
                    );
                    
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إنشاء الحساب بنجاح')),
                      );
                      Navigator.pop(context);
                    }
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('لديك حساب بالفعل؟ تسجيل الدخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}