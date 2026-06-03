import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:herfatiapp/core/constants.dart';
import 'package:herfatiapp/data/firebase_service.dart';
import 'package:herfatiapp/data/models.dart' as app_models;
import 'package:uuid/uuid.dart';

class ClientChatScreen extends StatefulWidget {
  const ClientChatScreen({super.key});

  @override
  State<ClientChatScreen> createState() => _ClientChatScreenState();
}

class _ClientChatScreenState extends State<ClientChatScreen> {
  final FirebaseService _service = FirebaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _orderId;
  String? _craftsmanName;
  String? _currentUserId;
  String? _craftsmanId;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      _showErrorAndPop('بيانات غير مكتملة (لا توجد معاملات)');
      _isInitialized = true;
      return;
    }

    final orderId = args["orderId"] as String?;
    final craftsmanName = args["craftsmanName"] as String?;
    final craftsmanId = args["craftsmanId"] as String?;

    if (orderId == null || craftsmanName == null || craftsmanId == null) {
      _showErrorAndPop(
          "بيانات غير مكتملة (معرّف المحادثة أو اسم الحرفي أو معرّف الحرفي مفقود)");
      _isInitialized = true;
      return;
    }

    _orderId = orderId;
    _craftsmanName = craftsmanName;
    _craftsmanId = craftsmanId;
    _initUser();
    _isInitialized = true;
  }

  void _showErrorAndPop(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showSnackBar(message, isError: true);
        Navigator.pop(context);
      }
    });
  }

  Future<void> _initUser() async {
    final user = await _service.getCurrentUser();
    if (user != null) {
      if (mounted) {
        setState(() {
          _currentUserId = user.id;
        });
      }
    } else {
      _showErrorAndPop('يرجى تسجيل الدخول أولاً');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_orderId == null || _currentUserId == null || _craftsmanId == null) {
      return;
    }

    final msg = app_models.ChatMessage(
      id: const Uuid().v4(),
      orderId: _orderId!,
      senderId: _currentUserId!,
      recipientId: _craftsmanId!,
      message: _messageController.text.trim(),
      timestamp: Timestamp.now(),
      isRead: false,
    );
    await _service.sendChatMessage(msg);
    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null || _orderId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_craftsmanName ?? "المحادثة")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_craftsmanName!),
        backgroundColor: AppColors.primaryDarkBlue,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<app_models.ChatMessage>>(
              stream: _service.streamChatMessages(
                _orderId!,
                alternateId: buildChatId(_currentUserId!, _craftsmanId!),
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                        'خطأ: ${snapshot.error}\nقد تحتاج إلى إنشاء فهرس في Firebase Console.'),
                  );
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("لا توجد رسائل بعد، ابدأ المحادثة"),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == _currentUserId;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.primaryGold.withValues(alpha: 0.2)
                              : Colors.grey[300],
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primaryGold,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
