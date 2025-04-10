import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/message.dart';
import '../../providers/message_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/common/network_image.dart';
import '../../services/image_service.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;

  const ConversationScreen({
    Key? key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
  }) : super(key: key);

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _showAttachmentOptions = false;
  
  @override
  void initState() {
    super.initState();
    _loadMessages();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Provider.of<MessageProvider>(context, listen: false)
          .loadMessages(widget.conversationId);
      
      // التمرير لآخر رسالة بعد تحميل الرسائل
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('خطأ في تحميل الرسائل: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    _messageController.clear();
    
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    
    try {
      final success = await messageProvider.sendMessage(
        recipientId: widget.otherUserId,
        content: text,
      );
      
      if (success) {
        // التمرير لآخر رسالة
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      print('خطأ في إرسال الرسالة: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في إرسال الرسالة: $e')),
      );
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final File? selectedImage = await ImageService.showImageSourceActionSheet(context);
      
      if (selectedImage != null) {
        setState(() {
          _showAttachmentOptions = false;
        });
        
        final messageProvider = Provider.of<MessageProvider>(context, listen: false);
        
        // إرسال الصورة كرسالة
        final success = await messageProvider.sendMessage(
          recipientId: widget.otherUserId,
          content: selectedImage.path, // استخدام مسار الصورة كمحتوى
          type: MessageType.image,
          file: selectedImage,
          metadata: {
            'size': await selectedImage.length(),
            'name': selectedImage.path.split('/').last,
          },
        );
        
        if (success) {
          // التمرير لآخر رسالة
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      print('خطأ في اختيار الصورة: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل الصورة: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(widget.otherUserAvatar),
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            const SizedBox(width: 8),
            Text(widget.otherUserName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // عرض تفاصيل المستخدم الآخر
              // يمكن إضافة هذه الوظيفة لاحقًا
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // عرض الرسائل
          Expanded(
            child: _buildMessagesList(),
          ),
          
          // خيارات المرفقات
          if (_showAttachmentOptions)
            Container(
              color: Theme.of(context).cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo,
                    label: 'صورة',
                    onTap: _pickImage,
                  ),
                  _buildAttachmentOption(
                    icon: Icons.file_present,
                    label: 'ملف',
                    onTap: () {
                      // إرسال ملف
                      // يمكن إضافة هذه الوظيفة لاحقًا
                      setState(() {
                        _showAttachmentOptions = false;
                      });
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.location_on,
                    label: 'موقع',
                    onTap: () {
                      // إرسال موقع
                      // يمكن إضافة هذه الوظيفة لاحقًا
                      setState(() {
                        _showAttachmentOptions = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          
          // مربع إدخال الرسالة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showAttachmentOptions ? Icons.close : Icons.attachment,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _showAttachmentOptions = !_showAttachmentOptions;
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالة...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessagesList() {
    final messages = Provider.of<MessageProvider>(context).messages;
    final conversationMessages = messages[widget.conversationId] ?? [];
    final currentUserId = Provider.of<AuthProvider>(context).user?.id ?? '';
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (conversationMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'ابدأ المحادثة مع ${widget.otherUserName}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'أرسل رسالة للبدء',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: conversationMessages.length,
      itemBuilder: (context, index) {
        final message = conversationMessages[index];
        final isMe = message.senderId == currentUserId;
        
        return MessageBubble(
          message: message,
          isMe: isMe,
          showUserInfo: !isMe,
          userAvatar: isMe ? '' : widget.otherUserAvatar,
          userName: isMe ? '' : widget.otherUserName,
        );
      },
    );
  }
  
  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}