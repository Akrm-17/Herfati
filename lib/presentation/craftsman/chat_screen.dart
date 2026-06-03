import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/data/models.dart' as app_models;
import 'package:uuid/uuid.dart';

class CraftsmanChatScreen extends StatefulWidget {
  const CraftsmanChatScreen({super.key});

  @override
  State<CraftsmanChatScreen> createState() => _CraftsmanChatScreenState();
}

class _CraftsmanChatScreenState extends State<CraftsmanChatScreen> {
  final FirebaseService _service = FirebaseService();
  final TextEditingController _messageController = TextEditingController();
  String? _orderId;
  String? _clientName;
  String? _currentUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _orderId = args['orderId'];
      _clientName = args['clientName'] ?? "العميل";
      _initUser();
    } else {
      showSnackBar('بيانات غير مكتملة', isError: true);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _initUser() async {
    final user = await _service.getCurrentUser();
    if (user != null) {
      if (mounted) {
        setState(() => _currentUserId = user.id);
      }
    } else {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final msg = app_models.ChatMessage(
      id: const Uuid().v4(),
      orderId: _orderId!,
      senderId: _currentUserId!,
      message: _messageController.text.trim(),
      timestamp: Timestamp.now(),
      isRead: false,
    );
    await _service.sendChatMessage(msg);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_clientName ?? "الدردشة")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(_clientName!), backgroundColor: AppColors.primaryDarkBlue),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<app_models.ChatMessage>>(
              stream: _service.streamChatMessages(_orderId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('خطأ: ${snapshot.error}\nقد تحتاج إلى إنشاء فهرس في Firebase Console.'));
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(child: Text("لا توجد رسائل بعد"));
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == _currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primaryGold.withValues(alpha: 0.2) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(msg.message),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "اكتب رسالة...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primaryGold,
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}