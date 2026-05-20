import 'package:flutter/material.dart';
import '../services/chatbot_api_service.dart';

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final ChatbotApiService _apiService = ChatbotApiService();
  final TextEditingController _controller = TextEditingController();
  late List<Map<String, String>> _messages;
  bool _isExpanded = false;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messages = _apiService.uiMessages;
  }

  void _toggleChat() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    await _apiService.sendMessage(
      text,
      onConfirm: (action, params) async {
        return await _showConfirmationDialog(action, params);
      },
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<bool> _showConfirmationDialog(String action, Map<String, dynamic> params) async {
    String title = "Confirm Action";
    String content = "Are you sure you want to proceed?";

    if (action == 'delete_food_log') {
      title = "Confirm Deletion";
      content = "The AI wants to delete a food log entry. Do you agree?";
    } else if (action == 'update_food_log') {
      title = "Confirm Update";
      content = "The AI wants to update a food log entry. Do you agree?";
    } else if (action == 'delete_recipe') {
      title = "Delete Recipe";
      content = "The AI wants to move a saved recipe to the recipe bin. Do you agree?";
    } else if (action == 'delete_recipe_ingredient') {
      title = "Remove Ingredient";
      content = "The AI wants to remove an ingredient from your recipe. Do you agree?";
    } else if (action == 'update_recipe_ingredient') {
      title = "Update Ingredient";
      content = "The AI wants to change the amount of an ingredient in your recipe. Do you agree?";
    } else if (action == 'add_recipe_ingredient') {
      title = "Add Ingredient";
      content = "The AI wants to add a new ingredient to your saved recipe. Do you agree?";
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isExpanded ? 350 : 60,
      height: _isExpanded ? 500 : 60,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_isExpanded ? 20 : 30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isExpanded ? _buildChatWindow() : _buildChatButton(),
    );
  }

  Widget _buildChatButton() {
    return GestureDetector(
      onTap: _toggleChat,
      child: const Center(
        child: Icon(Icons.chat, color: Color(0xFF10B981), size: 30),
      ),
    );
  }

  Widget _buildChatWindow() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI Nutrition Assistant',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: _toggleChat,
              ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg['role'] == 'user';
                    return _buildMessageBubble(msg['text'] ?? '', isUser);
                  },
                ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
            ),
          ),
        // Input
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Ask me anything...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: const CircleAvatar(
                  backgroundColor: Color(0xFF10B981),
                  child: Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, color: Colors.grey[400], size: 50),
          const SizedBox(height: 16),
          Text(
            'How can I help you today?',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF10B981) : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isUser ? 12 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 12),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black),
        ),
      ),
    );
  }
}
