import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_typography.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isRecording = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'user',
      'time': '10:42 AM',
      'text': 'Can I give lemon juice with moong dal khichdi? How does it help?',
    },
    {
      'sender': 'ai',
      'time': '10:42 AM',
      'text':
          'Yes, absolutely! Plant-based non-heme iron from moong dal needs Vitamin C for up to 3x better absorption. Squeezing 3–4 drops of fresh lemon or adding a pinch of fresh amla paste right before feeding helps Aarav\'s body absorb the iron effortlessly without irritating his tummy.',
      'card': {
        'title': 'Vitamin C + Non-Heme Fe Synergy',
        'sub': '+300% Bio-availability • Prevents nutritional anemia',
        'source': 'ICMR-NIN 2024 Infant Feeding Guidelines',
      },
      'audioAvailable': true,
    },
    {
      'sender': 'user',
      'time': '10:45 AM',
      'text': 'Aarav refused coarse texture yesterday, should I liquidize it again?',
    },
    {
      'sender': 'ai',
      'time': '10:45 AM',
      'text':
          'Stage 3 Transition (12-18m): At 14 months, avoid blending into a liquid soup. Instead, try fork-mashing softly with warm dal water or half a teaspoon of desi cow ghee. Gentle lumps support essential chewing oral-motor development and speech muscles. It is completely normal for toddlers to need 8–10 repeated calm exposures to new textures!',
      'audioAvailable': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
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
                    'Aarav Shah (14m) • Active Context',
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
          IconButton(
            icon: const Icon(Icons.volume_up_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gujarati speech playback activated.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () {
              setState(() {
                _messages.clear();
              });
            },
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
                    'ICMR-NIN & WHO Aligned Infant Guidance Ver 2.4 — Evidence-based nutritional insights. Does not replace emergency care.',
                    style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.statusBlue),
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isUser = m['sender'] == 'user';
                return _buildMessageBubble(m, isUser);
              },
            ),
          ),

          // Care Team Escalation Suggestion Cards
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

          // Quick Suggestion Chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _suggestionChip('Iron-rich local foods (લોહતત્વ આહાર)'),
                _suggestionChip('Safe textures at 14m'),
                _suggestionChip('Explain WHO growth curve'),
                _suggestionChip('Weekly Gujarati meal plan'),
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Meal Photo Nutrient Inspector ready!')),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Ask about baby foods, recipes, growth...',
                        hintStyle: AppTypography.bodySmall.copyWith(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                      onSubmitted: _sendMessage,
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
                    icon: const Icon(Icons.arrow_upward_rounded, color: AppColors.primary),
                    onPressed: () => _sendMessage(_textController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> m, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(color: isUser ? AppColors.primary : AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m['text'] as String,
              style: AppTypography.bodyMedium.copyWith(
                color: isUser ? Colors.white : AppColors.textPrimary,
                height: 1.45,
              ),
            ),
            if (m['card'] != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.tertiary.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.science_outlined, size: 16, color: AppColors.tertiaryDark),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            (m['card'] as Map)['title'] as String,
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.tertiaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (m['card'] as Map)['sub'] as String,
                      style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '📖 ${(m['card'] as Map)['source']}',
                      style: AppTypography.labelSmall.copyWith(fontSize: 9, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
            if (m['audioAvailable'] == true) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.volume_up_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Flexible(
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
                m['time'] as String,
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
                  Text(name, style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
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

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'sender': 'user',
        'time': 'Just now',
        'text': text,
      });
      _messages.add({
        'sender': 'ai',
        'time': 'Just now',
        'text':
            'Great question! For a 14-month toddler like Aarav, nutritional consistency is key. Ensure you pair healthy fats (desi cow ghee) with grains for sustained energy and brain development.',
        'audioAvailable': true,
      });
    });
    _textController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}
