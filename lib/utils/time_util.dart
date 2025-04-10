String timeAgo(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  
  if (difference.inSeconds < 60) {
    return 'الآن';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes} دقيقة';
  } else if (difference.inHours < 24) {
    return '${difference.inHours} ساعة';
  } else if (difference.inDays < 30) {
    return '${difference.inDays} يوم';
  } else if (difference.inDays < 365) {
    return '${(difference.inDays / 30).floor()} شهر';
  } else {
    return '${(difference.inDays / 365).floor()} سنة';
  }
}