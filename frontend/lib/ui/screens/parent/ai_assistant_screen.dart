import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_typography.dart';
import 'package:frontend/core/models/child_model.dart';
import 'package:frontend/core/models/chat_model.dart';
import 'package:frontend/core/services/child_session.dart';
import 'package:frontend/core/services/api_service.dart';
import 'package:frontend/core/widgets/child_selector_widget.dart';

class AiAssistantScreen extends StatefulWidget {
  final int? initialConversationId;

  const AiAssistantScreen({
    super.key,
    this.initialConversationId,
  });

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  int? _activeConversationId;
  String _conversationTitle = 'Nutrition Advice';
  bool _isLoadingHistory = false;
  bool _isTyping = false;
  bool _isRecording = false;

  final List<ChatMessage> _messages = [];
  List<ChatConversationSummary> _conversations = [];

  late AnimationController _dotsAnimController;

  @override
  void initState() {
    super.initState();
    _dotsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _activeConversationId = widget.initialConversationId;
    _initializeChat();
  }

  @override
  void dispose() {
    _dotsAnimController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoadingHistory = true);
    try {
      // 1. Fetch conversations list
      final history = await ApiService.instance.fetchChatHistory();
      if (!mounted) return;

      setState(() {
        _conversations = history;
      });

      // 2. If initial or active conversation exists, load it
      if (_activeConversationId != null) {
        await _loadConversation(_activeConversationId!);
      } else if (history.isNotEmpty) {
        // Load the most recent conversation
        final mostRecent = history.first;
        _activeConversationId = mostRecent.id;
        _conversationTitle = mostRecent.title;
        await _loadConversation(mostRecent.id);
      } else {
        // First-time welcome state with active child context
        _showInitialWelcome();
      }
    } catch (e) {
      debugPrint('ℹ️ Could not initialize chat: $e');
      if (mounted) _showInitialWelcome();
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _showInitialWelcome() {
    final activeChild = ChildSession.instance.activeChild;
    final childName = activeChild?.name ?? 'your child';
    final childAge = activeChild?.ageDisplay ?? 'early childhood';

    _messages.clear();
    _messages.add(ChatMessage(
      senderRole: 'assistant',
      content:
          'Namaste! I am PoshanSaathi AI, your personal child nutrition guide.\n\nI am currently personalized for **$childName** ($childAge). Ask me about age-appropriate complementary feeding, wholesome recipes, growth milestones, or iron-rich foods!',
      createdAt: DateTime.now(),
    ));
  }

  Future<void> _loadConversation(int conversationId) async {
    setState(() => _isLoadingHistory = true);
    try {
      final msgs = await ApiService.instance.fetchChatMessages(conversationId);
      if (!mounted) return;

      setState(() {
        _activeConversationId = conversationId;
        _messages.clear();
        if (msgs.isEmpty) {
          _showInitialWelcome();
        } else {
          _messages.addAll(msgs);
        }
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('ℹ️ Could not load conversation $conversationId: $e');
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _startNewConversation() async {
    final activeChild = ChildSession.instance.activeChild;
    setState(() {
      _activeConversationId = null;
      _conversationTitle = 'Nutrition Advice';
      _showInitialWelcome();
    });

    try {
      final newConv = await ApiService.instance.newChatConversation(
        childId: activeChild?.id,
        title: activeChild != null ? '${activeChild.name} Nutrition' : 'Nutrition Advice',
      );
      if (newConv != null && mounted) {
        setState(() {
          _activeConversationId = newConv.id;
          _conversationTitle = newConv.title;
          _conversations.insert(0, newConv);
        });
      }
    } catch (e) {
      debugPrint('ℹ️ Could not pre-create conversation: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text, {int? retryIndex}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    final activeChild = ChildSession.instance.activeChild;

    ChatMessage userMsg;
    if (retryIndex != null && retryIndex < _messages.length) {
      // Re-use existing failed message
      userMsg = _messages[retryIndex].copyWith(isError: false, isPending: true, errorMessage: null);
      setState(() {
        _messages[retryIndex] = userMsg;
        _isTyping = true;
      });
    } else {
      userMsg = ChatMessage(
        senderRole: 'user',
        content: trimmed,
        createdAt: DateTime.now(),
        isPending: false,
      );
      setState(() {
        _messages.add(userMsg);
        _isTyping = true;
      });
      _textController.clear();
      _scrollToBottom();
    }

    try {
      final result = await ApiService.instance.sendChatMessage(
        message: trimmed,
        conversationId: _activeConversationId,
        childId: activeChild?.id,
      );

      if (!mounted) return;

      if (result.success && result.reply != null) {
        setState(() {
          _isTyping = false;
          if (_activeConversationId == null && result.conversationId != null) {
            _activeConversationId = result.conversationId;
            _refreshHistoryList();
          }

          _messages.add(ChatMessage(
            id: result.messageId,
            conversationId: result.conversationId ?? _activeConversationId,
            senderRole: 'assistant',
            content: result.reply!,
            createdAt: DateTime.now(),
          ));
        });
        _scrollToBottom();
      } else {
        setState(() {
          _isTyping = false;
          final lastIdx = retryIndex ?? _messages.indexOf(userMsg);
          if (lastIdx != -1) {
            _messages[lastIdx] = _messages[lastIdx].copyWith(
              isError: true,
              errorMessage: result.errorMessage ?? 'Failed to send message.',
            );
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        final lastIdx = retryIndex ?? _messages.indexOf(userMsg);
        if (lastIdx != -1) {
          _messages[lastIdx] = _messages[lastIdx].copyWith(
            isError: true,
            errorMessage: 'Network error. Please tap retry.',
          );
        }
      });
    }
  }

  Future<void> _refreshHistoryList() async {
    try {
      final history = await ApiService.instance.fetchChatHistory();
      if (mounted) {
        setState(() => _conversations = history);
      }
    } catch (_) {}
  }

  void _showConversationsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Past Conversations (ઇતિહાસ)',
                          style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _startNewConversation();
                          },
                          icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                          label: Text(
                            'New Chat',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_conversations.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No conversation history yet.\nAsk a question to start your first session!',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _conversations.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final conv = _conversations[index];
                            final isSelected = conv.id == _activeConversationId;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : AppColors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 16,
                                  color: isSelected ? Colors.white : AppColors.primaryDark,
                                ),
                              ),
                              title: Text(
                                conv.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                conv.lastMessage ?? (conv.childName != null ? 'For ${conv.childName}' : 'General Advice'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (dCtx) => AlertDialog(
                                      title: const Text('Delete Conversation?'),
                                      content: const Text('This will permanently delete this conversation and its messages.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dCtx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(dCtx, true),
                                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    final ok = await ApiService.instance.deleteChatConversation(conv.id);
                                    if (ok && mounted) {
                                      setSheetState(() {
                                        _conversations.removeWhere((c) => c.id == conv.id);
                                      });
                                      setState(() {
                                        if (_activeConversationId == conv.id) {
                                          _activeConversationId = null;
                                          _showInitialWelcome();
                                        }
                                      });
                                    }
                                  }
                                },
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                _conversationTitle = conv.title;
                                _loadConversation(conv.id);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ChildModel?>(
      valueListenable: ChildSession.instance.selectedChildNotifier,
      builder: (context, activeChild, _) {
        final childName = activeChild?.name ?? 'Child';
        final childAge = activeChild?.ageDisplay ?? 'Milestone';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppColors.primaryDark, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PoshanSaathi AI (પોષણ સલાહકાર)',
                        style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        activeChild != null
                            ? '$childName ($childAge) • Active Context'
                            : 'AI Nutritional Guidance',
                        style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              const ChildSelectorPill(isCompact: true),
              IconButton(
                tooltip: 'History & Past Chats',
                icon: const Icon(Icons.history_rounded),
                onPressed: _showConversationsBottomSheet,
              ),
              IconButton(
                tooltip: 'New Conversation',
                icon: const Icon(Icons.add_comment_outlined),
                onPressed: _startNewConversation,
              ),
            ],
          ),
          body: Column(
            children: [
              // Clinical Protocol Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.statusBlueContainer,
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, size: 16, color: AppColors.statusBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ICMR-NIN & WHO Aligned Infant Guidance — Evidence-based nutritional insights for $childName. Does not replace emergency medical care.',
                        style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.statusBlue),
                      ),
                    ),
                  ],
                ),
              ),

              // Chat Messages List
              Expanded(
                child: _isLoadingHistory
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isTyping) {
                            return _buildTypingIndicator(childName);
                          }
                          final msg = _messages[index];
                          return _buildMessageBubble(msg, index, childName);
                        },
                      ),
              ),

              // Care Team Escalation Cards
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: _escalationCard(
                        initials: 'MD',
                        name: 'Dr. Meera Patel',
                        role: 'Pediatric Nutritionist',
                        slot: 'Slot: 2:30 PM',
                        color: AppColors.secondary,
                        onTap: () => Navigator.pushNamed(context, '/clinician_dashboard'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _escalationCard(
                        initials: 'KB',
                        name: 'Kavita Ben',
                        role: 'Anganwadi Sector 4',
                        slot: 'Available on Chat',
                        color: AppColors.primary,
                        onTap: () => Navigator.pushNamed(context, '/anganwadi_connect'),
                      ),
                    ),
                  ],
                ),
              ),

              // Dynamic Quick Suggestion Chips for active child
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _suggestionChip('Iron-rich local foods for $childName (લોહતત્વ આહાર)'),
                    _suggestionChip('Safe textures for $childName ($childAge)'),
                    _suggestionChip('Healthy lunch recipe with ragi & ghee'),
                    _suggestionChip('Weekly Gujarati meal plan'),
                    _suggestionChip('Choking hazard rules under 3 yrs'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Input Bar with Voice & Photo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                        tooltip: 'Meal Photo Nutrient Inspector',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Meal Photo Nutrient Inspector ready!')),
                          );
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          enabled: !_isTyping,
                          textInputAction: TextInputAction.send,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: _isTyping
                                ? 'AI is responding...'
                                : 'Ask about foods, recipes, growth for $childName...',
                            hintStyle: AppTypography.bodySmall.copyWith(fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            filled: true,
                            fillColor: _isTyping ? AppColors.surface : AppColors.background,
                          ),
                          onSubmitted: (txt) => _sendMessage(txt),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() => _isRecording = !_isRecording);
                          if (_isRecording) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Listening in Gujarati & English (Speech-to-Text active)...')),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isRecording ? AppColors.statusRed : AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isRecording ? Icons.mic : Icons.mic_none_rounded,
                            color: _isRecording ? Colors.white : AppColors.primaryDark,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: _isTyping
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            : const Icon(Icons.arrow_upward_rounded, color: AppColors.primary),
                        onPressed: _isTyping ? null : () => _sendMessage(_textController.text),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, int index, String childName) {
    final isUser = msg.isUser;
    final timeStr = _formatTime(msg.createdAt);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser
              ? (msg.isError ? Colors.red.shade400 : AppColors.primary)
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: msg.isError
                ? Colors.red.shade300
                : (isUser ? AppColors.primary : AppColors.divider),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              msg.content,
              style: AppTypography.bodyMedium.copyWith(
                color: isUser ? Colors.white : AppColors.textPrimary,
                height: 1.45,
              ),
            ),
            if (msg.isError) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      msg.errorMessage ?? 'Failed to send',
                      style: AppTypography.bodySmall.copyWith(fontSize: 11, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(msg.content, retryIndex: index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Retry',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (!isUser) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.volume_up_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gujarati speech playback activated.')),
                      );
                    },
                    child: Text(
                      'Listen in Gujarati (ગુજરાતીમાં સાંભળો)',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timeStr,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 9,
                  color: isUser ? Colors.white70 : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(String childName) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'PoshanSaathi AI is thinking',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedBuilder(
              animation: _dotsAnimController,
              builder: (context, _) {
                final val = (_dotsAnimController.value * 3).floor();
                final dots = '.' * (val + 1);
                return SizedBox(
                  width: 18,
                  child: Text(
                    dots,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _escalationCard({
    required String initials,
    required String name,
    required String role,
    required String slot,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color,
              child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold), maxLines: 1),
                  Text(slot, style: AppTypography.bodySmall.copyWith(fontSize: 9, color: AppColors.statusGreen)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(String text) {
    return GestureDetector(
      onTap: () => _sendMessage(text),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: AppTypography.labelSmall.copyWith(color: AppColors.primaryDark, fontSize: 11),
        ),
      ),
    );
  }
}
