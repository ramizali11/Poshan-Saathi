import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/botanical_decorations.dart';

class WelcomeRoleScreen extends StatefulWidget {
  const WelcomeRoleScreen({super.key});

  @override
  State<WelcomeRoleScreen> createState() => _WelcomeRoleScreenState();
}

class _WelcomeRoleScreenState extends State<WelcomeRoleScreen> {
  int _selectedRoleIndex = 0; // 0: Parent, 1: Doctor, 2: Admin
  bool _isGujarati = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      body: BotanicalScreenWrapper(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Accredited Banner & Language Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F3E2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF176B3A).withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 14, color: Color(0xFF176B3A)),
                          SizedBox(width: 4),
                          Text(
                            'SFIC 2026-27 Accredited',
                            style: TextStyle(
                              color: Color(0xFF104A2B),
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Language Toggle Pill
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD6E3D3)),
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
                          _langButton('EN', !_isGujarati, () {
                            setState(() => _isGujarati = false);
                          }),
                          _langButton('ગુજરાતી', _isGujarati, () {
                            setState(() => _isGujarati = true);
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Brand Hero Section with Floral Laurel Badge
                Center(
                  child: Column(
                    children: [
                      const BotanicalLogoBadge(size: 74),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🌿', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 6),
                          Text(
                            'PoshanSaathi',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF171B18),
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text('🌸', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isGujarati
                            ? 'પોષણ સાથી • શિશુ આહાર અને સ્વાસ્થ્ય'
                            : 'Child Nutrition & Growth Care',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF176B3A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F3E2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC7E2BF)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🌿', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 4),
                            Text(
                              'WHO Standards Aligned',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF104A2B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Select Role Header with Flower icon
                Row(
                  children: [
                    const Text('🌸', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    Text(
                      _isGujarati ? 'ભૂમિકા પસંદ કરો' : 'Select Your Role',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF171B18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Role Cards
                _buildRoleCard(
                  index: 0,
                  title: 'Parent / Caregiver',
                  gujaratiTitle: 'માતા-પિતા',
                  badgeText: '7m – 6y',
                  description: 'Track growth, meal plans & recipes.',
                  icon: Icons.family_restroom_rounded,
                  accentColor: const Color(0xFF176B3A),
                  flowerEmoji: '🌿',
                ),
                const SizedBox(height: 10),
                _buildRoleCard(
                  index: 1,
                  title: 'Doctor & Clinician',
                  gujaratiTitle: 'ડોક્ટર',
                  badgeText: 'Clinical',
                  description: 'Pediatric care & health audits.',
                  icon: Icons.medical_services_outlined,
                  accentColor: const Color(0xFF2563EB),
                  flowerEmoji: '🌸',
                ),
                const SizedBox(height: 10),
                _buildRoleCard(
                  index: 2,
                  title: 'Admin & Anganwadi',
                  gujaratiTitle: 'સંચાલક',
                  badgeText: 'Admin',
                  description: 'Program & center supervision.',
                  icon: Icons.admin_panel_settings_outlined,
                  accentColor: const Color(0xFFB45309),
                  flowerEmoji: '🌼',
                ),
                const SizedBox(height: 22),

                // CTA Action Button with Emerald Gradient
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF176B3A).withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF176B3A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (_selectedRoleIndex == 0) {
                        Navigator.pushNamed(context, '/login');
                      } else if (_selectedRoleIndex == 1) {
                        Navigator.pushNamed(context, '/clinician_register');
                      } else {
                        Navigator.pushNamed(context, '/clinician_dashboard');
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _selectedRoleIndex == 0
                              ? (_isGujarati ? 'આગળ વધો 🌿' : 'Continue as Parent 🌿')
                              : (_selectedRoleIndex == 1
                                  ? 'Continue as Doctor 🌸'
                                  : 'Continue as Admin 🌼'),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Log In Option
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: RichText(
                      text: const TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(fontSize: 13, color: Color(0xFF5F665F)),
                        children: [
                          TextSpan(
                            text: 'Log In',
                            style: TextStyle(
                              color: Color(0xFF176B3A),
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _langButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF176B3A) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF5F665F),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required int index,
    required String title,
    required String gujaratiTitle,
    required String badgeText,
    required String description,
    required IconData icon,
    required Color accentColor,
    required String flowerEmoji,
  }) {
    final isSelected = _selectedRoleIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedRoleIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4F9F2) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF176B3A) : const Color(0xFFE2E8DF),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF176B3A).withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE7F3E2) : const Color(0xFFF7F9F6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF176B3A).withOpacity(0.3) : const Color(0xFFE2E8DF),
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF176B3A) : accentColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(flowerEmoji, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15.5,
                            color: const Color(0xFF171B18),
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: isSelected ? const Color(0xFF176B3A) : const Color(0xFF9EABA0),
                        size: 20,
                      ),
                    ],
                  ),
                  Text(
                    gujaratiTitle,
                    style: const TextStyle(
                      color: Color(0xFF176B3A),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE7F3E2) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF104A2B) : const Color(0xFF92400E),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF5F665F),
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
