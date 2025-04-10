import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/api_service.dart';

class NetworkImageWithPlaceholder extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final double borderRadius;
  final Color placeholderColor;
  final IconData errorIcon;

  const NetworkImageWithPlaceholder({
    Key? key,
    required this.imageUrl,
    this.width = double.infinity,
    this.height = 200,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholderColor = const Color(0xFFEEEEEE),
    this.errorIcon = Icons.image_not_supported_outlined,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageUrl.isEmpty || imageUrl == 'default-profile.jpg'
          ? _buildPlaceholder()
          : _buildNetworkImage(apiService),
    );
  }

  Widget _buildNetworkImage(ApiService apiService) {
    // تطبيق روابط صحيحة ومطلقة
    final String finalUrl = apiService.getFullImageUrl(imageUrl);
    
    print('تحميل الصورة من الرابط: $finalUrl');
    print('الرابط الأصلي: $imageUrl');
    
    // إضافة رقم عشوائي للرابط لتجنب التخزين المؤقت
    String uniqueUrl = '$finalUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    
    return Image.network(
      uniqueUrl,
      width: width,
      height: height,
      fit: fit,
      headers: {
        // إضافة رؤوس لمنع التخزين المؤقت
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
      // إضافة مؤشر عشوائي لمنع التخزين المؤقت
      cacheWidth: (width * 0.8).toInt(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return Container(
          width: width,
          height: height,
          color: placeholderColor,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('خطأ في تحميل الصورة: $finalUrl - $error');
        
        // محاولة تحميل من رابط مطلق
        final absoluteUrl = 'http://192.168.88.2:5000/uploads/profiles/default-profile.jpg?v=${DateTime.now().millisecondsSinceEpoch}';
        print('محاولة تحميل من الرابط المطلق: $absoluteUrl');
        
        return Image.network(
          absoluteUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: placeholderColor,
      child: Center(
        child: Icon(
          errorIcon,
          size: 40,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}