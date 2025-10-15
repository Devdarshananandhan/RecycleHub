import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recyclehub/controllers/auth_controller.dart';
import 'package:recyclehub/models/message_model.dart';
import 'package:recyclehub/services/chat_service.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String productId;
  final String productTitle;

  const ChatScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
    required this.productId,
    required this.productTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = Get.find<ChatService>();
  final AuthController _authController = Get.find<AuthController>();
  
  late RxList<MessageModel> _messages;
  late String _chatId;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() async {
    final currentUser = _authController.currentUser.value!;
    
    // Create a unique chat ID based on the two users and product
    // This ensures the same chat is loaded when either user opens it
    final List<String> userIds = [currentUser.id, widget.sellerId];
    userIds.sort(); // Sort to ensure consistent ID regardless of who initiates
    _chatId = '${userIds.join('_')}_${widget.productId}';
    
    // Initialize empty message list
    _messages = RxList<MessageModel>([]);
    
    // Load existing messages or create a new chat
    final loadedMessages = await _chatService.getMessages(_chatId);
    _messages.assignAll(loadedMessages);
    
    // Add a system message if this is a new chat
    if (_messages.isEmpty) {
      _messages.add(
        MessageModel(
          id: const Uuid().v4(),
          chatId: _chatId,
          senderId: 'system',
          senderName: 'System',
          content: 'Chat started about: ${widget.productTitle}',
          timestamp: DateTime.now(),
          isRead: true,
        ),
      );
      _chatService.saveMessages(_chatId, _messages);
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final currentUser = _authController.currentUser.value!;
    final newMessage = MessageModel(
      id: const Uuid().v4(),
      chatId: _chatId,
      senderId: currentUser.id,
      senderName: currentUser.name,
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
      isRead: false,
    );
    
    _messages.add(newMessage);
    _chatService.saveMessages(_chatId, _messages);
    _messageController.clear();
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    // Simulate typing indicator from other user
    if (currentUser.id != widget.sellerId) {
      setState(() {
        _isTyping = true;
      });
      
      // Simulate reply after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isTyping = false;
          });
          
          // Add mock response
          final responseMessage = MessageModel(
            id: const Uuid().v4(),
            chatId: _chatId,
            senderId: widget.sellerId,
            senderName: widget.sellerName,
            content: _getAutoResponse(newMessage.content),
            timestamp: DateTime.now(),
            isRead: false,
          );
          
          _messages.add(responseMessage);
          _chatService.saveMessages(_chatId, _messages);
          
          // Scroll to bottom again
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });
    }
  }
  
  // Simple auto-response generator for demo purposes
  String _getAutoResponse(String message) {
    message = message.toLowerCase();
    
    if (message.contains('price') || message.contains('cost')) {
      return 'The price is firm, but I could consider reasonable offers.';
    } else if (message.contains('discount') || message.contains('lower')) {
      return 'I might be able to reduce the price by 5% if you can pick it up today.';
    } else if (message.contains('condition') || message.contains('used')) {
      return 'The item is in great condition, barely used. I can send more photos if you want.';
    } else if (message.contains('delivery') || message.contains('shipping')) {
      return 'I can arrange delivery for an additional fee, or you can pick it up from my location.';
    } else if (message.contains('hello') || message.contains('hi') || message.contains('hey')) {
      return 'Hi there! Thanks for your interest in my item. How can I help?';
    } else {
      return 'Thanks for your message. I\'ll get back to you as soon as possible.';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authController.currentUser.value!;
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentUser.id == widget.sellerId 
                  ? 'Chat with Buyer'
                  : widget.sellerName,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'About: ${widget.productTitle}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Obx(() {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                }
              });
              
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final bool isCurrentUser = message.senderId == currentUser.id;
                  final bool isSystemMessage = message.senderId == 'system';
                  
                  if (isSystemMessage) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  }
                  
                  return Align(
                    alignment: isCurrentUser 
                        ? Alignment.centerRight 
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isCurrentUser 
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomRight: isCurrentUser ? const Radius.circular(0) : null,
                          bottomLeft: !isCurrentUser ? const Radius.circular(0) : null,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.content,
                            style: TextStyle(
                              color: isCurrentUser ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: isCurrentUser 
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          
          // Typing Indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                '${widget.sellerName} is typing...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          
          // Message Input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: () {
                    // TODO: Implement image sending
                    Get.snackbar(
                      'Coming Soon',
                      'Image sharing will be available soon',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}