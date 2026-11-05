import 'package:flutter/material.dart';
import 'package:frontend/core/models/user_model.dart';
import 'package:frontend/core/services/user_session.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_typography.dart';
import 'package:frontend/core/constants/app_images_data.dart';

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  bool _growthAlarm = true;
  bool _mealAlarm = true;
  bool _doctorAlarm = true;
  bool _isGujarati = true;

  @override
  Widget build(BuildContext context) {
    final user = UserSession.instance.currentUser;
    final userName = user?.name.trim().isNotEmpty == true ? user!.name : 'Priya Shah';
    final initials = userName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    final avatarUrl = user?.avatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.startsWith('http');
    final phone = UserModel.sanitizePhone(user?.phone);
    final email = user?.email?.trim();
    final address = user?.address?.trim();
    final city = user?.city?.trim();
    final district = user?.district?.trim();
    final state = user?.state?.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 14,
        toolbarHeight: 70,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Caregiver & Child Profile (પ્રોફાઈલ)',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFF171B18),
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'PoshanSaathi Family Account • Vadodara, Gujarat',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF5F665F),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFD9381E), size: 22),
            tooltip: 'Log Out',
            onPressed: () => _confirmLogout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Caregiver Hero Profile Card
            _buildCaregiverHeroCard(
              context: context,
              userName: userName,
              initials: initials,
              hasAvatar: hasAvatar,
              avatarUrl: avatarUrl,
              phone: phone,
              email: email,
              address: address,
              city: city,
              district: district,
              state: state,
              user: user,
            ),
            const SizedBox(height: 14),

            // 2. Active Child Card (Aarav Shah)
            _buildActiveChildCard(context),
            const SizedBox(height: 14),

            // 3. Anganwadi Center & ASHA Worker Integration
            _buildAnganwadiIntegrationCard(context),
            const SizedBox(height: 14),

            // 4. Routine Reminders & Smart Alarms
            _buildRemindersSection(),
            const SizedBox(height: 14),

            // 5. App Preferences & Language
            _buildPreferencesSection(),
            const SizedBox(height: 14),

            // 6. Account Actions
            _buildAccountActions(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCaregiverHeroCard({
    required BuildContext context,
    required String userName,
    required String initials,
    required bool hasAvatar,
    String? avatarUrl,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? district,
    String? state,
    UserModel? user,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8DF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with Edit Badge
              Stack(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0xFFE7F3E2),
                    backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
                    child: !hasAvatar
                        ? Text(
                            initials.isNotEmpty ? initials : 'PS',
                            style: const TextStyle(
                              color: Color(0xFF176B3A),
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF176B3A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Name & Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF171B18),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F3E2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD3E6CC)),
                          ),
                          child: const Text(
                            'PRIMARY CAREGIVER • MOTHER',
                            style: TextStyle(
                              color: Color(0xFF104A2B),
                              fontWeight: FontWeight.w800,
                              fontSize: 9.5,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, size: 11, color: Color(0xFF176B3A)),
                              SizedBox(width: 3),
                              Text(
                                'VERIFIED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF176B3A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '📱 ${phone != null && phone.isNotEmpty ? "+91 $phone" : "+91 98765 43210"}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF5F665F), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE8EFE5)),
          const SizedBox(height: 12),

          // Detail rows
          _buildInfoRow(
            icon: Icons.mail_outline_rounded,
            label: 'Email (ઇમેઇલ)',
            value: email?.isNotEmpty == true ? email! : 'priya.shah@poshansaathi.org',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'Location (સરનામું)',
            value: address?.isNotEmpty == true
                ? '$address, ${city ?? "Vadodara"}'
                : 'Sector 4, Akota, Vadodara, Gujarat (390020)',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.storage_rounded,
            label: 'Session State',
            value: 'Permanent Local Storage Active (#${user?.id ?? 1})',
            valueColor: const Color(0xFF176B3A),
          ),
          const SizedBox(height: 14),

          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/edit_profile'),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text(
                'Edit Profile Details (પ્રોફાઇલ બદલો)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF176B3A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChildCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8DF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.child_care_rounded, size: 20, color: Color(0xFF176B3A)),
                  SizedBox(width: 6),
                  Text(
                    'Children Under Care (બાળકો)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF171B18)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F3E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '1 Active Child',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF104A2B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Child Pill Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FBF6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD6E8D1), width: 1.2),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF176B3A),
                  child: const Text(
                    'AS',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Aarav Shah (આરવ)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF171B18)),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.check_circle_rounded, color: Color(0xFF176B3A), size: 16),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        '14 Months • Boy • Born 12 Dec 2024',
                        style: TextStyle(fontSize: 11, color: Color(0xFF5F665F), fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Weight: 9.4 kg (WHO Green Zone) • Stage 3 Mash',
                        style: TextStyle(fontSize: 11, color: Color(0xFF176B3A), fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Add Child Button
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/add_child'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('+ Add Another Child Profile (બીજું બાળક ઉમેરો)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF176B3A),
              side: const BorderSide(color: Color(0xFF176B3A), width: 1.2),
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnganwadiIntegrationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8DF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.apartment_rounded, size: 20, color: Color(0xFF176B3A)),
              SizedBox(width: 8),
              Text(
                'Anganwadi & Health Integration (આંગણવાડી સેવા)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF171B18)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FAF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDFEADB)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFB45309),
                  child: const Text('KB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kavita Ben (ASHA Worker)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF171B18)),
                      ),
                      Text(
                        'Sector 4 Anganwadi Center, Vadodara',
                        style: TextStyle(fontSize: 11, color: Color(0xFF5F665F)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Next Mamta Divas: Thursday, 09:30 AM',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF176B3A)),
                  onPressed: () => Navigator.pushNamed(context, '/anganwadi_connect'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8DF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active_outlined, size: 20, color: Color(0xFF176B3A)),
              SizedBox(width: 8),
              Text(
                'Reminders & Smart Alarms (યાદ અપાવનાર)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF171B18)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildToggleTile(
            title: 'Growth Weigh-in Reminders (Monthly)',
            sub: 'Alerts 3 days before Mamta Divas weigh-in session',
            val: _growthAlarm,
            onChanged: (v) => setState(() => _growthAlarm = v),
          ),
          const Divider(height: 16, color: Color(0xFFE8EFE5)),
          _buildToggleTile(
            title: 'Toddler 4x Feeding Routine Alerts',
            sub: 'Timely reminders for 9:30 AM, 12:30 PM, 4:00 PM, 7:30 PM',
            val: _mealAlarm,
            onChanged: (v) => setState(() => _mealAlarm = v),
          ),
          const Divider(height: 16, color: Color(0xFFE8EFE5)),
          _buildToggleTile(
            title: 'Doctor & ASHA Follow-up Reminders',
            sub: 'Routine Vitamin A, immunization, and clinical visits',
            val: _doctorAlarm,
            onChanged: (v) => setState(() => _doctorAlarm = v),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String sub,
    required bool val,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF171B18))),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 10.5, color: Color(0xFF5F665F))),
            ],
          ),
        ),
        Switch(
          value: val,
          onChanged: onChanged,
          activeColor: const Color(0xFF176B3A),
          activeTrackColor: const Color(0xFFE7F3E2),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8DF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 20, color: Color(0xFF176B3A)),
              SizedBox(width: 8),
              Text(
                'App Preferences (સેટિંગ્સ)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF171B18)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.translate_rounded, color: Color(0xFF176B3A)),
            title: const Text('Primary App Language', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            subtitle: Text(_isGujarati ? 'ગુજરાતી (Gujarati Active)' : 'English Active', style: const TextStyle(fontSize: 11)),
            trailing: InkWell(
              onTap: () {
                setState(() => _isGujarati = !_isGujarati);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isGujarati ? 'ભાષા: ગુજરાતી સક્રિય' : 'Language: English Active'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: const Color(0xFF176B3A),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F3E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF176B3A)),
                ),
                child: Text(
                  _isGujarati ? 'Change to EN' : 'Change to GU',
                  style: const TextStyle(color: Color(0xFF104A2B), fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EFE5)),
          const ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.verified_outlined, color: Color(0xFF176B3A)),
            title: Text('Clinical Guidelines Edition', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            subtitle: Text('ICMR-NIN & WHO Infant Standards Ver 2.4 (2026)', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                icon: const Icon(Icons.switch_account_outlined, size: 16),
                label: const Text('Switch Account', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF176B3A),
                  side: const BorderSide(color: Color(0xFFD0DCD0)),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('Log Out', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDE8E8),
                  foregroundColor: const Color(0xFFD9381E),
                  elevation: 0,
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF176B3A)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF5F665F), fontWeight: FontWeight.w500)),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF171B18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out (બહાર નીકળો)?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: const Text(
          'Are you sure you want to log out of PoshanSaathi? You can log back in anytime with your phone number.',
          style: TextStyle(fontSize: 13, color: Color(0xFF5F665F)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF5F665F), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9381E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await UserSession.instance.clearUser();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

