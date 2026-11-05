import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_typography.dart';
import 'package:frontend/core/constants/app_images_data.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isRecording = false;
  bool _isGujaratiMode = true;
  String? _currentlyPlayingId;
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _messages = [
    {
      'id': 'msg_1',
      'sender': 'user',
      'time': '10:42 AM',
      'text': 'Can I give lemon juice with moong dal khichdi? How does it help?',
    },
    {
      'id': 'msg_2',
      'sender': 'ai',
      'time': '10:42 AM',
      'text':
          'Yes, absolutely! Plant-based non-heme iron from moong dal needs Vitamin C for up to 3x better absorption. Squeezing 3–4 drops of fresh lemon or adding a pinch of fresh amla paste right before feeding helps Aarav\'s body absorb the iron effortlessly without irritating his tummy.',
      'gujarati':
          'હા, ચોક્કસ! મગ દાળમાં રહેલ લોહતત્વ શરીર સરળતાથી પચાવી શકે તે માટે વિટામિન C ખૂબ જરૂરી છે. ખીચડી આપતા પહેલા લીંબુના ૩-૪ ટીપાં અથવા થોડી આમળા પેસ્ટ ઉમેરવાથી આહાર ગુણવત્તા ૩ ગણી વધી જાય છે.',
      'card': {
        'title': 'Vitamin C + Non-Heme Fe Synergy',
        'sub': '+300% Bio-availability • Prevents nutritional anemia',
        'source': 'ICMR-NIN 2024 Infant Feeding Guidelines',
        'icon': Icons.bolt_rounded,
        'badge': 'CLINICALLY PROVEN',
      },
      'audioAvailable': true,
      'audioDuration': '0:22',
      'liked': false,
    },
    {
      'id': 'msg_3',
      'sender': 'user',
      'time': '10:45 AM',
      'text': 'Aarav refused coarse texture yesterday, should I liquidize it again?',
    },
    {
      'id': 'msg_4',
      'sender': 'ai',
      'time': '10:45 AM',
      'text':
          'Stage 3 Transition (12-18m): At 14 months, avoid blending into a liquid soup. Instead, try fork-mashing softly with warm dal water or half a teaspoon of desi cow ghee. Gentle lumps support essential chewing oral-motor development and speech muscles. It is completely normal for toddlers to need 8–10 repeated calm exposures to new textures!',
      'gujarati':
          'સ્ટેજ ૩ સંક્રમણ (૧૨-૧૮ મહિના): ૧૪ મહિનાના બાળકના ખોરાકને મિક્સરમાં પાતળો સૂપ ન બનાવો. ગરમ દાળનું પાણી અથવા અડધી ચમચી દેશી ગાયનું ઘી ઉમેરી કાંટા ચમચીથી નરમ મેશ કરો. આનાથી ચાવવાના સ્નાયુઓ અને બોલવાનો વિકાસ થાય છે.',
      'card': {
        'title': 'Chewing & Speech Muscle Development',
        'sub': 'Texture regression slows jaw strength and self-feeding milestones',
        'source': 'WHO & Indian Academy of Pediatrics (IAP)',
        'icon': Icons.child_care_rounded,
        'badge': 'DEVELOPMENTAL MILESTONE',
      },
      'audioAvailable': true,
      'audioDuration': '0:28',
      'liked': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: _buildModernAppBar(),
      body: Column(
        children: [
          // 1. Clinical Evidence & Child Context Banner
          _buildEvidenceBanner(),

          // 2. Chat Conversation List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isUser = m['sender'] == 'user';
                return _buildMessageBubble(m, isUser);
              },
            ),
          ),

          // 3. Quick Escalation to Doctor / ASHA Worker
          _buildCareTeamEscalationBar(),

          // 4. Suggestion Pills
          _buildSuggestionChips(),

          // 5. Floating Input Dock
          _buildFloatingInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 14,
      toolbarHeight: 70,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF176B3A), Color(0xFF289659)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF176B3A).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Text(
                      'Poshan AI',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Color(0xFF171B18),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.verified_rounded, size: 16, color: Color(0xFF176B3A)),
                  ],
                ),
                Text(
                  'Aarav • 14m • Pediatric Help',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF5F665F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        // Language Toggle Pill
        InkWell(
          onTap: () {
            setState(() {
              _isGujaratiMode = !_isGujaratiMode;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isGujaratiMode ? 'ગુજરાતી અવાજ અને લખાણ સક્રિય (Gujarati Active)' : 'English Voice & Text Active'),
                duration: const Duration(seconds: 1),
                backgroundColor: const Color(0xFF176B3A),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            margin: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: _isGujaratiMode ? const Color(0xFFE7F3E2) : const Color(0xFFF1F5F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isGujaratiMode ? const Color(0xFF176B3A) : const Color(0xFFD0D7CF),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 14,
                  color: _isGujaratiMode ? const Color(0xFF176B3A) : const Color(0xFF5F665F),
                ),
                const SizedBox(width: 4),
                Text(
                  _isGujaratiMode ? 'ગુજરાતી' : 'English',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _isGujaratiMode ? const Color(0xFF104A2B) : const Color(0xFF5F665F),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 22, color: Color(0xFF5F665F)),
          tooltip: 'Clear Chat',
          onPressed: () {
            setState(() {
              _messages.clear();
              _messages.add({
                'id': 'msg_welcome',
                'sender': 'ai',
                'time': 'Just now',
                'text': 'Namaste Priya Ben! I am your PoshanSaathi AI assistant. Ask me anything about Aarav\'s 14-month feeding, recipes, weight gain, or WHO growth standards.',
                'gujarati': 'નમસ્તે પ્રિયા બેન! હું તમારો પોષણ સાથી એઆઈ સહાયક છું. ૧૪ મહિનાના આરવના આહાર, રેસિપી, વજન વધારો કે વિકાસ વિશે પૂછી શકો છો.',
                'audioAvailable': true,
                'audioDuration': '0:15',
              });
            });
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildEvidenceBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E8D1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF176B3A).withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFF176B3A).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF176B3A)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ICMR-NIN & WHO Aligned • Evidence-Based Infant Guidance',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: Color(0xFF104A2B),
                  ),
                ),
                Text(
                  'Live Context: Aarav (14m • Stage 3 Coarse Mash • 9.4 kg Healthy)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2E6342).withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF176B3A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'VERIFIED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> m, bool isUser) {
    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.80),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF176B3A), Color(0xFF13572E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF176B3A).withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                m['text'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                m['time'] as String,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.75),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // AI Message Card
    final bool isPlayingThis = _currentlyPlayingId == m['id'];

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: const Color(0xFFE2E8DF), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Header with Avatar
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F3E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCFE5C7)),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF176B3A), size: 14),
                ),
                const SizedBox(width: 8),
                const Text(
                  'PoshanSaathi AI',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF104A2B),
                  ),
                ),
                const Spacer(),
                Text(
                  m['time'] as String,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF8C968B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Primary Message Body
            Text(
              m['text'] as String,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2420),
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),

            // Gujarati Translation block if available and Gujarati mode active
            if (_isGujaratiMode && m['gujarati'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBF8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE6EDE3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.translate, size: 14, color: Color(0xFF176B3A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m['gujarati'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1B4026),
                          height: 1.42,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Clinical Evidence Card Attachment
            if (m['card'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F8F1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCEE3CA), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon((m['card'] as Map)['icon'] as IconData? ?? Icons.science_outlined,
                            size: 16, color: const Color(0xFF176B3A)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            (m['card'] as Map)['title'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF104A2B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1F0DC),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (m['card'] as Map)['badge'] as String? ?? 'VERIFIED',
                            style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF176B3A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      (m['card'] as Map)['sub'] as String,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF28362B), height: 1.35),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 12, color: Color(0xFF5F665F)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            (m['card'] as Map)['source'] as String,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF5F665F), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Audio Player Bar
            if (m['audioAvailable'] == true) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  setState(() {
                    if (_currentlyPlayingId == m['id']) {
                      _currentlyPlayingId = null;
                    } else {
                      _currentlyPlayingId = m['id'] as String;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isPlayingThis ? const Color(0xFFE7F3E2) : const Color(0xFFF6FAF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPlayingThis ? const Color(0xFF176B3A) : const Color(0xFFDFEADB),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isPlayingThis ? const Color(0xFF176B3A) : const Color(0xFF289659),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlayingThis ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPlayingThis ? 'Playing Gujarati Voice...' : 'Listen in Gujarati (ગુજરાતીમાં સાંભળો)',
                              style: TextStyle(
                                color: const Color(0xFF104A2B),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Clear spoken audio • ${m['audioDuration'] ?? '0:20'}',
                              style: const TextStyle(fontSize: 9.5, color: Color(0xFF5F665F)),
                            ),
                          ],
                        ),
                      ),
                      if (isPlayingThis)
                        Row(
                          children: List.generate(4, (i) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              width: 3,
                              height: (8 + (i * 4)).toDouble(),
                              decoration: BoxDecoration(
                                color: const Color(0xFF176B3A),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        )
                      else
                        const Icon(Icons.volume_up_rounded, size: 18, color: Color(0xFF176B3A)),
                    ],
                  ),
                ),
              ),
            ],

            // Message Actions (Like, Copy, Share)
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      m['liked'] = !(m['liked'] == true);
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          m['liked'] == true ? Icons.thumb_up_rounded : Icons.thumb_up_alt_outlined,
                          size: 14,
                          color: m['liked'] == true ? const Color(0xFF176B3A) : const Color(0xFF7A8578),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Helpful',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: m['liked'] == true ? const Color(0xFF176B3A) : const Color(0xFF7A8578),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Answer copied to clipboard!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.copy_rounded, size: 14, color: Color(0xFF7A8578)),
                        SizedBox(width: 4),
                        Text('Copy', style: TextStyle(fontSize: 10.5, color: Color(0xFF7A8578), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareTeamEscalationBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8DF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent_rounded, size: 18, color: Color(0xFF176B3A)),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Connect with Care Team:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF171B18)),
            ),
          ),
          _escalationPill(
            name: 'Dr. Meera Patel',
            role: 'Pediatrician',
            badgeColor: const Color(0xFF176B3A),
            onTap: () => Navigator.pushNamed(context, '/clinician_dashboard'),
          ),
          const SizedBox(width: 6),
          _escalationPill(
            name: 'Kavita Ben',
            role: 'ASHA',
            badgeColor: const Color(0xFFB45309),
            onTap: () => Navigator.pushNamed(context, '/anganwadi_connect'),
          ),
        ],
      ),
    );
  }

  Widget _escalationPill({
    required String name,
    required String role,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF6FAF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD6E3D3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 9,
              backgroundColor: badgeColor,
              child: Text(
                name.substring(0, 1),
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              name,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF171B18)),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_forward_ios_rounded, size: 8, color: Color(0xFF5F665F)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      {'icon': '🥣', 'text': 'Iron-rich local foods (લોહતત્વ આહાર)'},
      {'icon': '🥄', 'text': 'Safe textures at 14m (વાટીને આપવું)'},
      {'icon': '📈', 'text': 'Is 9.4 kg weight healthy?'},
      {'icon': '🥑', 'text': 'Healthy fats & desi cow ghee'},
      {'icon': '⏰', 'text': 'Today\'s 14m feeding timetable'},
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final s = suggestions[index];
          return GestureDetector(
            onTap: () => _sendMessage(s['text'] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD3DFD1), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s['icon'] as String, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    s['text'] as String,
                    style: const TextStyle(
                      color: Color(0xFF104A2B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8DF), width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Meal Plate Scanner Camera Button
            InkWell(
              onTap: () => _showMealPhotoScannerModal(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F3E2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFCEE3CA)),
                ),
                child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF176B3A), size: 20),
              ),
            ),
            const SizedBox(width: 8),

            // Text Input Field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9F6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD6E3D3)),
                ),
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF171B18)),
                  decoration: InputDecoration(
                    hintText: _isGujaratiMode
                        ? 'ખોરાક, રેસિપી અથવા વિકાસ વિશે પૂછો...'
                        : 'Ask about meals, recipes, weight...',
                    hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF7A8578)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    border: InputBorder.none,
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Gujarati Speech-to-Text Mic Button
            GestureDetector(
              onTap: () {
                setState(() => _isRecording = !_isRecording);
                if (_isRecording) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.mic, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Listening in Gujarati & English (બોલો, સાંભળું છું)...'),
                        ],
                      ),
                      backgroundColor: Color(0xFFD9381E),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  // Simulate voice transcript arrival after 2.5 seconds
                  Timer(const Duration(milliseconds: 2500), () {
                    if (mounted && _isRecording) {
                      setState(() {
                        _isRecording = false;
                        _textController.text = 'Can I add roasted jeera powder to curd?';
                      });
                      _sendMessage(_textController.text);
                    }
                  });
                }
              },
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isRecording
                          ? Color.lerp(const Color(0xFFD9381E), const Color(0xFFB91C1C), _pulseController.value)
                          : const Color(0xFFF1F5F0),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isRecording ? Colors.redAccent : const Color(0xFFD0D7CF),
                      ),
                      boxShadow: _isRecording
                          ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic : Icons.mic_none_rounded,
                      color: _isRecording ? Colors.white : const Color(0xFF176B3A),
                      size: 20,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 6),

            // Send Button
            InkWell(
              onTap: () => _sendMessage(_textController.text),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF176B3A), Color(0xFF289659)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMealPhotoScannerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D7CF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.camera_alt_rounded, color: Color(0xFF176B3A), size: 24),
                SizedBox(width: 8),
                Text(
                  'NutriScan AI (ખોરાક ફોટો તપાસ)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF171B18)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Take or upload a picture of Aarav\'s meal bowl. AI will analyze food groups, texture suitability, and nutrient balance in real time.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF5F665F), height: 1.4),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F3E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_rounded, color: Color(0xFF176B3A)),
              ),
              title: const Text('Capture Live Meal Plate', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Camera analysis for current feeding bowl', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _simulatePhotoAnalysis('Moong Dal Khichdi + Steamed Carrot Mash');
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF3F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB)),
              ),
              title: const Text('Pick from Gallery', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Select a saved meal photo', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _simulatePhotoAnalysis('Sprouted Ragi & Papaya Sheera');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _simulatePhotoAnalysis(String detectedDish) {
    setState(() {
      _messages.add({
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}_u',
        'sender': 'user',
        'time': 'Just now',
        'text': '📸 [Analyzed Photo]: $detectedDish',
      });
      _messages.add({
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}_ai',
        'sender': 'ai',
        'time': 'Just now',
        'text':
            'NutriScan Result for "$detectedDish":\n• Texture: Soft coarse mash (Safe for 14m)\n• Iron & Protein: High from sprouted grains & dal\n• Vitamin A: Excellent beta-carotene rating\n• Recommendation: Add half a tsp desi cow ghee to boost absorption of fat-soluble vitamins!',
        'gujarati':
            '"$detectedDish" ફોટો વિશ્લેષણ:\n• બનાવટ: નરમ મેશ (૧૪ મહિના માટે ઉત્તમ)\n• પ્રોટીન અને આયર્ન: અંકુરિત અનાજમાંથી ભરપૂર\n• વિટામિન A: ઉત્તમ ગુણવત્તા\n• સલાહ: વિટામિન શોષણ વધારવા અડધી ચમચી દેશી ગાયનું ઘી ઉમેરો!',
        'card': {
          'title': 'NutriScan AI Analysis Verified',
          'sub': 'Matched 4 of 5 daily diversity food groups for 14m toddler',
          'source': 'ICMR-NIN Computer Vision Infant Nutrition Model',
          'icon': Icons.camera_alt_rounded,
          'badge': 'AI SCAN VERIFIED',
        },
        'audioAvailable': true,
        'audioDuration': '0:25',
      });
    });

    _scrollToBottom();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final String query = text.trim();
    _textController.clear();

    String replyEn = '';
    String replyGu = '';
    Map<String, dynamic>? cardData;

    if (query.toLowerCase().contains('iron') || query.contains('લોહતત્વ')) {
      replyEn =
          'Top iron-rich local Gujarati foods for 14-month toddlers like Aarav:\n1. Sprouted Ragi (નાચણી) sheera with date syrup\n2. Yellow Moong Dal khichdi with 3 drops lemon juice\n3. Steamed spinach (પાલક) puree folded into bajra porridge\n4. Ripe papaya chunks as a morning finger food.\nRemember: Avoid cow milk immediately with iron meals to prevent absorption blockage!';
      replyGu =
          '૧૪ મહિનાના બાળક માટે લોહતત્વથી ભરપૂર આહાર:\n૧. ખજૂરના પાણી સાથે અંકુરિત રાગીનો શીરો\n૨. લીંબુના ટીપાં સાથે મગની દાળની ખીચડી\n૩. બાજરીના રાબમાં બાફેલી પાલક\n૪. સવારના નાસ્તામાં પાકી પપૈયાના ટુકડા.\nખાસ નોંધ: લોહતત્વવાળા ખોરાક સાથે ગાયનું દૂધ ન આપો!';
      cardData = {
        'title': 'Iron Bio-availability & Brain Health',
        'sub': 'Prevents fatigue, supports cognitive milestones & hemoglobin',
        'source': 'ICMR-NIN & POSHAN Abhiyaan Gujarat Guidelines',
        'icon': Icons.favorite_rounded,
        'badge': 'ESSENTIAL NUTRIENT',
      };
    } else if (query.toLowerCase().contains('weight') || query.contains('9.4') || query.contains('વજન')) {
      replyEn =
          'Aarav\'s weight of 9.4 kg at 14 months is in the WHO GREEN ZONE (50th Percentile) — exactly where a thriving toddler should be! His growth velocity (+300g this month) demonstrates healthy physical development and good nutritional uptake.';
      replyGu =
          '૧૪ મહિનામાં આરવનું ૯.૪ કિલો વજન ડબલ્યુએચઓ (WHO) ગ્રીન ઝોનમાં છે (૫૦મી પર્સેન્ટાઇલ) — જે સંપૂર્ણ સ્વસ્થ છે! આ મહિને +૩૦૦ ગ્રામનો વધારો તેનો ઉત્તમ વિકાસ દર્શાવે છે.';
      cardData = {
        'title': 'WHO Growth Standard: P50 Median',
        'sub': 'Normal weight range for 14m boys: 8.4 kg – 11.1 kg',
        'source': 'WHO Child Growth Standards (Geneva)',
        'icon': Icons.show_chart_rounded,
        'badge': 'WHO GREEN ZONE',
      };
    } else if (query.toLowerCase().contains('texture') || query.contains('વાટીને')) {
      replyEn =
          'At 14 months, coarse mashing with a fork (Stage 3) is critical. Do not blend into baby puree! If Aarav fusses, mix half a teaspoon of desi cow ghee or warm vegetable broth. Giving soft steamed carrot sticks or banana slices also encourages independent finger-feeding.';
      replyGu =
          '૧૪ મહિનાના બાળકને મિક્સરમાં પીસીને આપવાને બદલે કાંટા ચમચીથી નરમ મેશ કરીને આપવું જરૂરી છે. જો બાળક આનાકાની કરે તો થોડું દેશી ઘી અથવા ગરમ દાળનું પાણી ઉમેરી આપો.';
      cardData = {
        'title': 'Oral-Motor Chewing Milestones',
        'sub': 'Transitioning to finger foods builds jaw strength and prevents picky eating',
        'source': 'IAP Pediatric Nutrition Chapter 2024',
        'icon': Icons.restaurant_menu_rounded,
        'badge': 'STAGE 3 COARSE MASH',
      };
    } else {
      replyEn =
          'Great question! For a 14-month toddler like Aarav, nutritional consistency is key. Ensure you pair healthy fats (desi cow ghee) with grains for sustained energy and brain development. Continue offering 4 to 5 food groups daily.';
      replyGu =
          'ખૂબ સરસ પ્રશ્ન! ૧૪ મહિનાના આરવ માટે સંતુલિત આહાર સૌથી મહત્વપૂર્ણ છે. રોજના ૫ માંથી ઓછામાં ઓછા ૪ આહાર જૂથોમાંથી ખોરાક આપવો જોઈએ.';
      cardData = {
        'title': 'Daily Diversity Standard (4/5 Groups)',
        'sub': 'Grains + Pulses + Green Veg + Yellow Fruits + Dairy',
        'source': 'UNICEF & WHO Infant and Young Child Feeding',
        'icon': Icons.eco_rounded,
        'badge': 'HEALTHY PRACTICE',
      };
    }

    setState(() {
      _messages.add({
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}_u',
        'sender': 'user',
        'time': 'Just now',
        'text': query,
      });
      _messages.add({
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}_ai',
        'sender': 'ai',
        'time': 'Just now',
        'text': replyEn,
        'gujarati': replyGu,
        'card': cardData,
        'audioAvailable': true,
        'audioDuration': '0:24',
      });
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
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
}
