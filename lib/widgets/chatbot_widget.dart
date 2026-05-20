import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chatbot_api_service.dart';
import '../providers/data_providers.dart';

class ChatbotWidget extends ConsumerStatefulWidget {
  const ChatbotWidget({super.key});

  @override
  ConsumerState<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends ConsumerState<ChatbotWidget> {
  late ChatbotApiService _apiService;
  final TextEditingController _controller = TextEditingController();
  late List<Map<String, String>> _messages;
  bool _isExpanded = false;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _apiService = ref.read(chatbotApiServiceProvider);
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
    } else if (action == 'create_recipe') {
      title = "Create Recipe";
      content = "The AI wants to create a new saved recipe. Do you agree?";
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Confirm", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      width: _isExpanded ? 350 : 65,
      height: _isExpanded ? 550 : 65,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_isExpanded ? 28 : 32.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_isExpanded ? 28 : 32.5),
        child: _isExpanded ? _buildChatWindow() : _buildChatButton(),
      ),
    );
  }

  Widget _buildChatButton() {
    return GestureDetector(
      onTap: _toggleChat,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4ADE80), Color(0xFF059669)],
          ),
        ),
        child: const Center(
          child: Icon(Icons.auto_awesome, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildChatWindow() {
    return OverflowBox(
      minWidth: 350,
      maxWidth: 350,
      minHeight: 550,
      maxHeight: 550,
      alignment: Alignment.topLeft,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF22C55E), Color(0xFF059669)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NomNom Assistant',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Online • Always ready to help',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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
          child: Container(
            color: const Color(0xFFF8F9FA),
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      return _buildMessageBubble(msg['text'] ?? '', isUser);
                    },
                  ),
          ),
        ),
        if (_isLoading)
          Container(
            color: const Color(0xFFF8F9FA),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Center(
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
              ),
            ),
          ),
        // Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Ask for a summary or log food...',
                      hintStyle: TextStyle(fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Color(0xFF10B981), size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'How can I help you today?',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Try "What did I eat today?" or "Log a cheeseburger for me"',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF10B981) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            if (!isUser)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
