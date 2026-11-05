import 'package:frontend/core/constants/app_images_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_typography.dart';
import 'package:frontend/core/widgets/status_badge.dart';
import 'package:frontend/core/widgets/metric_tile.dart';
import 'package:frontend/core/models/user_model.dart';
import 'package:frontend/core/models/child_model.dart';
import 'package:frontend/core/services/user_session.dart';
import 'package:frontend/core/services/child_session.dart';
import 'package:frontend/core/widgets/child_selector_widget.dart';
import 'package:frontend/core/widgets/missing_field_dialogs.dart';   

class ParentDashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToMeals;
  final VoidCallback? onNavigateToGrowth;
  final VoidCallback? onNavigateToAI;

  const ParentDashboardScreen({
    super.key,
    this.onNavigateToMeals,
    this.onNavigateToGrowth,
    this.onNavigateToAI,
  });

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  void _showUserProfileModal(BuildContext context, UserModel? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final userName = user?.name.trim() ?? '';
        final initials = userName.isNotEmpty
            ? userName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
            : 'U';
        final avatarUrl = user?.avatarUrl?.trim();
        final hasAvatar = avatarUrl != null && avatarUrl.startsWith('http');
        final phone = UserModel.sanitizePhone(user?.phone);
        final email = user?.email?.trim();
        final dob = user?.dob?.trim();
        final address = user?.address?.trim();
        final city = user?.city?.trim();
        final state = user?.state?.trim();
        final district = user?.district?.trim();
        final pinCode = user?.pinCode?.trim();

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryContainer,
                    backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                    child: !hasAvatar
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName.isNotEmpty ? userName : 'Caregiver',
                          style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: user?.authProvider == 'google'
                                    ? AppColors.statusBlueContainer
                                    : AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user?.authProvider == 'google' ? 'GOOGLE ACCOUNT' : (user?.role ?? 'Parent').toUpperCase(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: user?.authProvider == 'google' ? AppColors.statusBlue : AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.verified_rounded, color: AppColors.statusGreen, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'SQLite DB Active',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.statusGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              _buildProfileDetailRow(
                icon: Icons.phone_android_rounded,
                label: 'Mobile Number (મોબાઇલ)',
                value: (phone != null && phone.isNotEmpty)
                    ? '+91 $phone'
                    : 'Not added',
                onAdd: () {
                  Navigator.pop(ctx);
                  showAddParentFieldDialog(
                    context: context,
                    fieldKey: 'phone',
                    fieldTitle: 'Mobile Number',
                    hintText: 'e.g. 9876543210',
                    keyboardType: TextInputType.phone,
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildProfileDetailRow(
                icon: Icons.mail_outline_rounded,
                label: 'Email (ઇમેઇલ)',
                value: (email != null && email.isNotEmpty)
                    ? email
                    : 'Not added',
              ),
              const SizedBox(height: 12),
              _buildProfileDetailRow(
                icon: Icons.cake_outlined,
                label: 'Date of Birth (જન્મ તારીખ)',
                value: (dob != null && dob.isNotEmpty)
                    ? dob
                    : 'Not added',
                onAdd: () {
                  Navigator.pop(ctx);
                  showAddParentFieldDialog(
                    context: context,
                    fieldKey: 'dob',
                    fieldTitle: 'Date of Birth',
                    hintText: 'YYYY-MM-DD',
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildProfileDetailRow(
                icon: Icons.home_outlined,
                label: 'Residential Address (સરનામું)',
                value: (address != null && address.isNotEmpty)
                    ? '$address${city != null && city.isNotEmpty ? ", $city" : ""}'
                    : 'Not added',
                onAdd: () {
                  Navigator.pop(ctx);
                  showAddParentFieldDialog(
                    context: context,
                    fieldKey: 'address',
                    fieldTitle: 'Residential Address',
                    hintText: 'Street / Society / Area',
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildProfileDetailRow(
                icon: Icons.location_on_outlined,
                label: 'District & State (જિલ્લો અને રાજ્ય)',
                value: (district != null || state != null)
                    ? '${district ?? ""}${district != null && state != null ? ", " : ""}${state ?? ""}'
                    : 'Not added',
                onAdd: () {
                  Navigator.pop(ctx);
                  showAddParentFieldDialog(
                    context: context,
                    fieldKey: 'district',
                    fieldTitle: 'District',
                    hintText: 'e.g. Ahmedabad',
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildProfileDetailRow(
                icon: Icons.pin_drop_outlined,
                label: 'PIN Code (પિન કોડ)',
                value: (pinCode != null && pinCode.isNotEmpty)
                    ? pinCode
                    : 'Not added',
                onAdd: () {
                  Navigator.pop(ctx);
                  showAddParentFieldDialog(
                    context: context,
                    fieldKey: 'pin_code',
                    fieldTitle: 'Postal PIN Code',
                    hintText: 'e.g. 380015',
                    keyboardType: TextInputType.number,
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildProfileDetailRow(
                icon: Icons.storage_rounded,
                label: 'Database Record ID',
                value: '#${user?.id ?? 1} (Saved in poshan_saathi.db)',
              ),
              const SizedBox(height: 20),

              // Edit Profile Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/edit_profile');
                },
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Profile Details (પ્રોફાઇલ બદલો)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(context, '/register');
                      },
                      icon: const Icon(Icons.person_add_outlined, size: 16),
                      label: const Text('Add Account', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusRed,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await UserSession.instance.clearUser();
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text('Log Out', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileDetailRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onAdd,
  }) {
    final isNotAdded = value == 'Not added' || value.isEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              if (isNotAdded && onAdd != null)
                Row(
                  children: [
                    Text(
                      'Not added',
                      style: AppTypography.bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onAdd,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add_rounded, size: 12, color: AppColors.primaryDark),
                            SizedBox(width: 2),
                            Text(
                              'Add',
                              style: TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isNotAdded ? AppColors.textMuted : AppColors.textPrimary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('🚨 [DASHBOARD RENDER ERROR CAUGHT]: ${details.exceptionAsString()}');
      originalOnError?.call(details);
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 10,
        toolbarHeight: 74,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.memory(
                AppImagesData.leafLogoBytes,
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PoshanSaathi',
                    style: AppTypography.headline3.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: const Color(0xFF171B18),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'પોષણ સાથી • SEVA FIRST',
                    style: AppTypography.labelSmall.copyWith(
                      color: const Color(0xFF5F665F),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          // Child Switcher Pill
          GestureDetector(
            onTap: () => _showUserProfileModal(context, UserSession.instance.currentUser),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F3E2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDFE6DA)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Color(0xFF176B3A),
                    child: Text('AS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Aarav (14m)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF104A2B),
                      fontSize: 12.5,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF104A2B)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Notification Bell
          IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, size: 26, color: Color(0xFF171B18)),
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => Navigator.pushNamed(context, '/reminders'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Greeting Card (Direct Trigger to Profile - Actual Responsive UI)
            SafeLayoutBox(
              name: 'GreetingCard',
              child: GestureDetector(
                onTap: () => _showUserProfileModal(context, UserSession.instance.currentUser),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'Good morning, Aarav',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text('☀️', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Happy feeding day',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4A6B4F),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Gentle nutrition for today's milestone.",
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          AppImagesData.babyIllustrationBytes,
                          width: 88,
                          height: 88,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Hero Child Growth Card
            SafeLayoutBox(
              name: 'HeroGrowthCard',
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F5E5), Color(0xFFF4FAF2), Color(0xFFE2F2E0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFCCE4CA), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF176B3A).withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Avatar, Name, Stage & WHO Green Zone Badge
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF176B3A), Color(0xFF289659)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF176B3A).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '14m',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  'મહિના',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 8.5,
                                  ),
                                ),
                              ],
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
                                      'Aarav Shah',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: Color(0xFF171B18),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Icon(Icons.check_circle_rounded, color: Color(0xFF176B3A), size: 18),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Stage 3: Coarse Mash 🥣',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF4A554A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFCCE4CA), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.eco_rounded, size: 14, color: Color(0xFF176B3A)),
                                SizedBox(width: 4),
                                Text(
                                  'WHO Green Zone',
                                  style: TextStyle(
                                    color: Color(0xFF176B3A),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 3 High-End Metric Tiles with Colored Circle Icons
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedMetricTile(
                              icon: Icons.scale_rounded,
                              iconBg: const Color(0xFFE8F5E9),
                              iconColor: const Color(0xFF176B3A),
                              label: 'WEIGHT',
                              value: '9.4 kg',
                              subtext: '↑ +0.3 kg / 30d',
                              subtextBg: const Color(0xFFE2F3DF),
                              subtextColor: const Color(0xFF176B3A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildEnhancedMetricTile(
                              icon: Icons.straighten_rounded,
                              iconBg: const Color(0xFFFEF3C7),
                              iconColor: const Color(0xFFB45309),
                              label: 'LENGTH',
                              value: '77.2 cm',
                              subtext: '50th Percentile',
                              subtextBg: const Color(0xFFFEF3C7),
                              subtextColor: const Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildEnhancedMetricTile(
                              icon: Icons.calendar_month_rounded,
                              iconBg: const Color(0xFFE0F2FE),
                              iconColor: const Color(0xFF0369A1),
                              label: 'LAST MEASURED',
                              value: '12 Feb',
                              subtext: 'By ASHA worker',
                              subtextBg: const Color(0xFFE0F2FE),
                              subtextColor: const Color(0xFF075985),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Caregiver & Chart Action Row
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.pushNamed(context, '/anganwadi_connect'),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFD0E5CC)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.group_rounded, size: 16, color: Color(0xFF176B3A)),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Kavita Ben • ASHA',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11.5,
                                          color: Color(0xFF176B3A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF176B3A)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                if (widget.onNavigateToGrowth != null) {
                                  widget.onNavigateToGrowth!();
                                } else {
                                  Navigator.pushNamed(context, '/growth');
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF176B3A),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF176B3A).withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.trending_up_rounded, size: 16, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      'Growth Chart >',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Actions 2x2 Grid
            SafeLayoutBox(
              name: 'QuickActions',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF171B18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.auto_awesome_rounded,
                            iconColor: const Color(0xFFB77908),
                            bgColor: const Color(0xFFFFF0DD),
                            title: 'PoshanSaathi AI',
                            subtitle: '24/7 feeding advice',
                            onTap: () {
                              if (widget.onNavigateToAI != null) {
                                widget.onNavigateToAI!();
                              } else {
                                Navigator.pushNamed(context, '/ai_assistant');
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.straighten_rounded,
                            iconColor: const Color(0xFF176B3A),
                            bgColor: const Color(0xFFE7F3E2),
                            title: 'Log Growth',
                            subtitle: 'Height, weight & teeth',
                            onTap: () {
                              if (widget.onNavigateToGrowth != null) {
                                widget.onNavigateToGrowth!();
                              } else {
                                Navigator.pushNamed(context, '/growth');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.restaurant_rounded,
                            iconColor: const Color(0xFFD3452B),
                            bgColor: const Color(0xFFFCE9E4),
                            title: 'Iron Recipes',
                            subtitle: 'Iron-rich recipes & tips',
                            onTap: () => Navigator.pushNamed(context, '/recipe_details'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.medical_services_rounded,
                            iconColor: const Color(0xFF1593D1),
                            bgColor: const Color(0xFFE7F4FD),
                            title: 'Pediatrician',
                            subtitle: 'Dr. Meera Patel • Available',
                            onTap: () => Navigator.pushNamed(context, '/clinician_dashboard'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Today's Meal Plan Card
            SafeLayoutBox(
              name: 'MealPlanCard',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Meal Plan",
                                style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '3 / 4 Logged • 75% Diversity',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.statusGreen, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (widget.onNavigateToMeals != null) {
                              widget.onNavigateToMeals!();
                            } else {
                              Navigator.pushNamed(context, '/meals');
                            }
                          },
                          child: const Text('Full Planner >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Featured Lunch Meal
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'LUNCH • 12:30 PM',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.bolt_rounded, size: 16, color: AppColors.tertiaryDark),
                              Text('Iron-Rich', style: AppTypography.labelSmall.copyWith(color: AppColors.tertiaryDark, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vegetable Moong Dal Khichdi with Steamed Carrots & Desi Cow Ghee',
                            style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
                          ),
                          
                          Wrap(
                            spacing: 6,
                            children: [
                              _pillChip('Soft Coarse Mash'),
                              _pillChip('⏱️ 20 mins'),
                              _pillChip('~₹22 / serving'),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Absorption Booster Box
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.tertiaryLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.tertiary.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.tips_and_updates_rounded, color: AppColors.tertiaryDark, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Add lemon or amla to boost plant-iron absorption.',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 11,
                                      color: AppColors.tertiaryDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  ),
                                  onPressed: () => Navigator.pushNamed(context, '/recipe_details'),
                                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                                  label: const Text('View Recipe & Cook', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                  ),
                                  onPressed: () {},
                                  icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                  label: const Text('Swap', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Little Nutrition Secret Card (Amber Tint)
            SafeLayoutBox(
              name: 'NutritionSecretCard',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.tertiary.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_rounded, color: AppColors.tertiaryDark, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nutrition Tip',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.tertiaryDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Pair plant-based iron with vitamin C. Avoid cow's milk with grains as calcium limits iron uptake.",
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ICMR-NIN Guidelines',
                      style: AppTypography.labelSmall.copyWith(fontSize: 10, color: AppColors.tertiaryDark),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Community Care Schedule Card
            SafeLayoutBox(
              name: 'CommunityCareCard',
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.event_available_rounded, color: AppColors.primaryDark, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Anganwadi Growth Day',
                            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Thu, 26 Feb • Sector 4 Center',
                            style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.alarm_add_rounded, color: AppColors.primary),
                      onPressed: () => Navigator.pushNamed(context, '/reminders'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6ECE0), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF171B18),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF858B83)),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF5F665F),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildEnhancedMetricTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required String subtext,
    required Color subtextBg,
    required Color subtextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EBE0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF6B7468),
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF171B18),
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
              decoration: BoxDecoration(
                color: subtextBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                subtext,
                style: TextStyle(
                  fontSize: 9.5,
                  color: subtextColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SafeLayoutBox extends SingleChildRenderObjectWidget {
  final String name;

  const SafeLayoutBox({super.key, required super.child, required this.name});

  @override
  RenderObject createRenderObject(BuildContext context) => RenderSafeBox(name: name);
}

class RenderSafeBox extends RenderProxyBox {
  final String name;
  bool _hasLayoutError = false;

  RenderSafeBox({required this.name});

  @override
  void performLayout() {
    if (child != null) {
      try {
        child!.layout(constraints, parentUsesSize: true);
        size = child!.size;
        _hasLayoutError = false;
      } catch (e, stack) {
        _hasLayoutError = true;
        size = constraints.constrain(Size.zero);
        debugPrint('🚨 [SAFE_LAYOUT_BOX CAUGHT IN $name]: $e');
        debugPrint('$stack');
      }
    } else {
      size = constraints.smallest;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_hasLayoutError && child != null) {
      context.paintChild(child!, offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (_hasLayoutError || child == null) return false;
    return super.hitTestChildren(result, position: position);
  }
}

