import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/api_service.dart';
import '../../widgets/common/network_image.dart';

class CarouselImages extends StatefulWidget {
  final List<String> imageUrls;
  final double height;

  const CarouselImages({
    Key? key,
    required this.imageUrls,
    this.height = 300,
  }) : super(key: key);

  @override
  _CarouselImagesState createState() => _CarouselImagesState();
}

class _CarouselImagesState extends State<CarouselImages> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // إذا كانت قائمة الصور فارغة، لا نعرض شيئًا
    if (widget.imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    // إذا كانت هناك صورة واحدة فقط، نعرضها مباشرة بدون مؤشرات تمرير
    if (widget.imageUrls.length == 1) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: NetworkImageWithPlaceholder(
          imageUrl: widget.imageUrls.first,
          height: widget.height,
          fit: BoxFit.cover,
        ),
      );
    }

    // إنشاء عارض الصور مع مؤشرات التمرير
    return Stack(
      children: [
        // صفحة عرض الصور
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return NetworkImageWithPlaceholder(
                imageUrl: widget.imageUrls[index],
                height: widget.height,
                fit: BoxFit.cover,
              );
            },
          ),
        ),
        
        // مؤشرات الصفحات
        Positioned(
          left: 0,
          right: 0,
          bottom: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.imageUrls.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Theme.of(context).primaryColor
                      : Colors.grey.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
        
        // زر السابق
        if (widget.imageUrls.length > 1)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: ClipOval(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                    onPressed: () {
                      if (_currentPage > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        
        // زر التالي
        if (widget.imageUrls.length > 1)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: ClipOval(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                    onPressed: () {
                      if (_currentPage < widget.imageUrls.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        
        // مؤشر الصفحة الحالية / العدد الكلي
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentPage + 1}/${widget.imageUrls.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}