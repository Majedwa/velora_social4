import 'package:flutter/material.dart';
import '../../widgets/common/network_image.dart';

class StoryCircle extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final bool hasStory;
  final bool isViewed;
  final VoidCallback onTap;
  final Widget? addIcon;

  const StoryCircle({
    Key? key,
    required this.imageUrl,
    required this.radius,
    this.hasStory = false,
    this.isViewed = false,
    required this.onTap,
    this.addIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: hasStory
              ? Border.all(
                  color: isViewed
                      ? Colors.grey
                      : Theme.of(context).primaryColor,
                  width: 2,
                )
              : null,
        ),
        child: Stack(
          children: [
            CircleAvatar(
              radius: radius,
              backgroundColor: Colors.grey[300],
              child: ClipOval(
                child: NetworkImageWithPlaceholder(
                  imageUrl: imageUrl,
                  width: radius * 2,
                  height: radius * 2,
                ),
              ),
            ),
            if (addIcon != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: addIcon,
                ),
              ),
          ],
        ),
      ),
    );
  }
}