import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/api_service.dart';
import '../../services/image_service.dart';

class ImageDiagnosticsScreen extends StatefulWidget {
  const ImageDiagnosticsScreen({Key? key}) : super(key: key);

  @override
  _ImageDiagnosticsScreenState createState() => _ImageDiagnosticsScreenState();
}

class _ImageDiagnosticsScreenState extends State<ImageDiagnosticsScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _uploadStatus;
  File? _testImage;
  Map<String, dynamic>? _uploadTestResult;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkUploadStatus();
  }

  Future<void> _checkUploadStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.checkServerUploadsStatus();

      setState(() {
        _uploadStatus = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'خطأ في فحص حالة التحميل: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndTestUpload() async {
    try {
      final selectedImage = await ImageService.showImageSourceActionSheet(context);
      
      if (selectedImage != null) {
        setState(() {
          _testImage = selectedImage;
          _isLoading = true;
          _error = null;
        });

        final apiService = Provider.of<ApiService>(context, listen: false);
        final result = await apiService.testImageUpload(selectedImage);

        setState(() {
          _uploadTestResult = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطأ أثناء اختبار التحميل: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تشخيص مشاكل الصور'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تشخيص مشاكل تحميل وعرض الصور',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Card(
                color: Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // معلومات عن حالة مجلدات التحميل
                  if (_uploadStatus != null) ...[
                    Text(
                      'حالة مجلدات التحميل في الخادم:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('نجاح الاتصال: ${_uploadStatus!['success']}'),
                            if (_uploadStatus!['data'] != null)
                              Text('الحالة: ${_uploadStatus!['data']['status'] ?? 'غير معروف'}'),
                            if (_uploadStatus!['data'] != null &&
                                _uploadStatus!['data']['directories'] != null) ...[
                              const SizedBox(height: 8),
                              const Text('المجلدات:'),
                              Text('مجلد التحميلات: ${_uploadStatus!['data']['directories']['uploads'] ?? 'غير معروف'}'),
                              Text('مجلد الاختبار: ${_uploadStatus!['data']['directories']['test'] ?? 'غير معروف'}'),
                            ],
                            if (_uploadStatus!['data'] != null &&
                                _uploadStatus!['data']['permissions'] != null) ...[
                              const SizedBox(height: 8),
                              const Text('الصلاحيات:'),
                              Text('الكتابة: ${_uploadStatus!['data']['permissions']['write'] ?? 'غير معروف'}'),
                            ],
                            if (_uploadStatus!['data'] != null &&
                                _uploadStatus!['data']['serverInfo'] != null) ...[
                              const SizedBox(height: 8),
                              const Text('معلومات الخادم:'),
                              Text('الرابط الأساسي: ${_uploadStatus!['data']['serverInfo']['baseUrl'] ?? 'غير معروف'}'),
                              Text('رابط التحميلات: ${_uploadStatus!['data']['serverInfo']['uploadsUrl'] ?? 'غير معروف'}'),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // اختبار تحميل الصور
                  Text(
                    'اختبار تحميل الصور:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _pickAndTestUpload,
                    child: const Text('اختر صورة وقم باختبارها'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // عرض الصورة المختارة للاختبار
                  if (_testImage != null) ...[
                    const Text('الصورة المختارة للاختبار:'),
                    const SizedBox(height: 8),
                    Image.file(
                      _testImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Text('المسار: ${_testImage!.path}'),
                    Text('الحجم: ${_testImage!.lengthSync()} بايت'),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // عرض نتيجة اختبار التحميل
                  if (_uploadTestResult != null) ...[
                    Text(
                      'نتيجة اختبار التحميل:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: _uploadTestResult!['success'] ? Colors.green[100] : Colors.red[100],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('نجاح العملية: ${_uploadTestResult!['success']}'),
                            Text('الرسالة: ${_uploadTestResult!['message'] ?? 'غير متوفر'}'),
                            if (_uploadTestResult!['data'] != null &&
                                _uploadTestResult!['data']['file'] != null) ...[
                              const SizedBox(height: 8),
                              const Text('معلومات الملف:'),
                              Text('اسم الملف: ${_uploadTestResult!['data']['file']['filename']}'),
                              Text('المسار: ${_uploadTestResult!['data']['file']['path']}'),
                              Text('الرابط الكامل: ${_uploadTestResult!['data']['file']['fullUrl']}'),
                              const SizedBox(height: 8),
                              const Text('الصورة من الرابط:'),
                              Image.network(
                                _uploadTestResult!['data']['file']['fullUrl'],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    width: double.infinity,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Text('فشل في تحميل الصورة'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            
            const SizedBox(height: 24),
            
            // نصائح لحل المشكلات
            Text(
              'نصائح لحل المشكلات:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildTroubleshootingTip(
              '1. تأكد من وجود مجلدات الصور',
              'تحقق من أن المجلدات uploads و uploads/posts و uploads/profiles موجودة في الخادم ولديها صلاحيات الكتابة المناسبة.'
            ),
            _buildTroubleshootingTip(
              '2. تأكد من عنوان API الصحيح',
              'تأكد من أن عنوان API في ApiService هو العنوان الصحيح للخادم الخاص بك.'
            ),
            _buildTroubleshootingTip(
              '3. تحقق من معالجة روابط الصور',
              'تأكد من أن روابط الصور تتم معالجتها بشكل صحيح من خلال تنفيذ اختبار التحميل.'
            ),
            _buildTroubleshootingTip(
              '4. افحص سجلات الخادم',
              'راجع سجلات الخادم للتحقق من أي أخطاء متعلقة بتحميل الصور.'
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTroubleshootingTip(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }
}