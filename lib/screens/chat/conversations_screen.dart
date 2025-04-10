import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/message_provider.dart';
import '../../widgets/chat/conversation_tile.dart';
import '../../screens/search/search_screen.dart';
import 'conversation_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  _ConversationsScreenState createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    // تحميل المحادثات عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MessageProvider>(context, listen: false).refreshConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _navigateToSearch();
            },
            tooltip: 'البحث عن مستخدم للمحادثة',
          ),
        ],
      ),
      body: Consumer<MessageProvider>(
        builder: (context, messageProvider, child) {
          if (messageProvider.loadingConversations) {
            return const Center(child: CircularProgressIndicator());
          }

          if (messageProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('حدث خطأ: ${messageProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => messageProvider.refreshConversations(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          if (messageProvider.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ليس لديك محادثات حاليًا',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ابدأ محادثة جديدة مع أصدقائك',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _navigateToSearch,
                    icon: const Icon(Icons.person_add),
                    label: const Text('بدء محادثة جديدة'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => messageProvider.refreshConversations(),
            child: ListView.separated(
              itemCount: messageProvider.conversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = messageProvider.conversations[index];
                return ConversationTile(
                  conversation: conversation,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConversationScreen(
                          conversationId: conversation.id,
                          otherUserId: conversation.otherUserId ?? '',
                          otherUserName: conversation.otherUserName ?? 'مستخدم',
                          otherUserAvatar: conversation.otherUserAvatar ?? '',
                        ),
                      ),
                    );
                  },
                  onDismiss: () => _showDeleteConfirmation(conversation.id),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToSearch,
        child: const Icon(Icons.chat_bubble_outline), // Cambiado el icono invalido
        tooltip: 'محادثة جديدة',
      ),
    );
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchScreen(), // Removido el parámetro inválido isForChat
      ),
    );
  }

  void _showDeleteConfirmation(String conversationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('حذف المحادثة'),
          content: const Text('هل أنت متأكد من رغبتك في حذف هذه المحادثة؟'),
          actions: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('حذف'),
              onPressed: () {
                Provider.of<MessageProvider>(context, listen: false)
                    .deleteConversation(conversationId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}