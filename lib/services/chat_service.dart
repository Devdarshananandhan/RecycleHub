import 'dart:convert';
import 'package:get/get.dart';
import 'package:recyclehub/models/message_model.dart';
import 'package:recyclehub/services/storage_service.dart';

class ChatService extends GetxService {
  final StorageService _storageService = Get.find<StorageService>();
  
  // Map to store active chats in memory
  final Map<String, List<MessageModel>> _activeChats = {};
  
  // Initialize the service
  Future<ChatService> init() async {
    return this;
  }
  
  // Get messages for a specific chat
  Future<List<MessageModel>> getMessages(String chatId) async {
    // Check if chat is already loaded in memory
    if (_activeChats.containsKey(chatId)) {
      return _activeChats[chatId]!;
    }
    
    // Try to load from storage
    final chatData = await _storageService.getData('chat_$chatId');
    if (chatData != null) {
      try {
        final List<dynamic> messagesJson = jsonDecode(chatData);
        final messages = messagesJson
            .map((json) => MessageModel.fromJson(json))
            .toList();
        
        // Sort by timestamp
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        // Store in memory
        _activeChats[chatId] = messages;
        return messages;
      } catch (e) {
        print('Error loading chat: $e');
      }
    }
    
    // If no chat exists, return empty list
    _activeChats[chatId] = [];
    return [];
  }
  
  // Save messages for a specific chat
  Future<void> saveMessages(String chatId, List<MessageModel> messages) async {
    // Update in memory
    _activeChats[chatId] = messages;
    
    // Save to storage
    final messagesJson = messages.map((message) => message.toJson()).toList();
    await _storageService.saveData('chat_$chatId', jsonEncode(messagesJson));
  }
  
  // Get all chats for a user
  Future<List<String>> getUserChats(String userId) async {
    final keys = await _storageService.getAllKeys();
    final allChats = keys
        .where((key) => key.startsWith('chat_'))
        .map((key) => key.replaceFirst('chat_', ''))
        .where((chatId) => chatId.contains(userId))
        .toList();
    
    return allChats;
  }
  
  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    final messages = await getMessages(chatId);
    bool hasChanges = false;
    
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (message.senderId != userId && !message.isRead) {
        // Create a new message with isRead set to true
        final updatedMessage = MessageModel(
          id: message.id,
          chatId: message.chatId,
          senderId: message.senderId,
          senderName: message.senderName,
          content: message.content,
          timestamp: message.timestamp,
          isRead: true,
        );
        
        messages[i] = updatedMessage;
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      await saveMessages(chatId, messages);
    }
  }
  
  // Delete a chat
  Future<void> deleteChat(String chatId) async {
    // Remove from memory
    _activeChats.remove(chatId);
    
    // Remove from storage
    await _storageService.removeData('chat_$chatId');
  }
}