import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_typography.dart';

class ProfessionalRegistrationScreen extends StatefulWidget {
  const ProfessionalRegistrationScreen({super.key});

  @override
  State<ProfessionalRegistrationScreen> createState() => _ProfessionalRegistrationScreenState();
}

class _ProfessionalRegistrationScreenState extends State<ProfessionalRegistrationScreen> {
  final _nameController = TextEditingController();
  final _regNumController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _hospitalController = TextEditingController();

  String _selectedRole = 'Pediatrician (MD/DCH)';
  String _selectedSector = 'Ahmedabad Central - Sector 14 (Vadaj & Usmanpura)';
  bool _hasUploadedCert = false;
  bool _isCertified = false;

  @override
  void dispose() {
    _nameController.dispose();
    _regNumController.dispose();
    _qualificationController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clinician Credentialing (તબીબી ચકાસણી)',
              style: AppTypography.headline3.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'PoshanSaathi Care Network • Clinical Portal',
              style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Protocol Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.tertiary.withOpacity(0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_clock_rounded, color: AppColors.tertiaryDark, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restricted Access Protocol (સત્તાવાર ચકાસણી)',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.tertiaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'All professional accounts remain restricted and under review until clinical licenses and registration credentials are authenticated by state administrators.',
                            style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form
              _label('Full Professional Name (તબીબનું પૂરું નામ)', isReq: true),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primary),
                  helperText: 'Must match your registered state medical council license',
                ),
              ),
              const SizedBox(height: 14),

              _label('Clinical / Professional Role (તબીબી હોદ્દો)', isReq: true),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedRole,
                    items: [
                      'Pediatrician (MD/DCH)',
                      'Clinical Pediatric Nutritionist',
                      'Community Child Health Specialist',
                      'Registered Dietitian (RD)',
                    ]
                        .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _label('Medical Registration Number (મેડિકલ કાઉન્સિલ નંબર)', isReq: true),
              TextField(
                controller: _regNumController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.pin_outlined, color: AppColors.primary),
                  helperText: 'e.g., Gujarat Medical Council (GMC) / NMC Registration',
                ),
              ),
              const SizedBox(height: 14),

              _label('Highest Qualification & Specialization', isReq: true),
              TextField(
                controller: _qualificationController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.school_outlined, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 14),

              _label('Hospital, Clinic or Affiliated Center'),
              TextField(
                controller: _hospitalController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.local_hospital_outlined, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 14),

              _label('Associated Anganwadi Sector (Optional)'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedSector,
                    items: [
                      'Ahmedabad Central - Sector 14 (Vadaj & Usmanpura)',
                      'Mandvi - Sector 04 (Rural Kutch)',
                      'Bhuj - Sector 12 (Community Center)',
                    ]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedSector = val!),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Document Upload Box
              _label('Medical License / Registration Certificate (પ્રમાણપત્ર)', isReq: true),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary, style: BorderStyle.solid),
                ),
                child: _hasUploadedCert
                    ? Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryDark, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dr_Meera_Patel_GMC_Certificate.pdf',
                                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '1.8 MB • Ready for administrative validation',
                                  style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.statusGreen),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _hasUploadedCert = false),
                            child: const Text('Change', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          const Icon(Icons.upload_file_rounded, size: 36, color: AppColors.primary),
                          const SizedBox(height: 6),
                          Text('Upload Medical Council Certificate (PDF/JPG)', style: AppTypography.labelSmall),
                          Text('Max file size 10MB', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
                        ],
                      ),
              ),
              const SizedBox(height: 16),

              // Certification Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _isCertified,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _isCertified = v ?? true),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'I hereby certify that my medical council credentials and pediatric qualifications are authentic under the National Commission for Allied and Healthcare Professions Act.',
                        style: AppTypography.bodySmall.copyWith(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Application submitted! Routing to Clinician Dashboard preview...'),
                      backgroundColor: AppColors.statusGreen,
                    ),
                  );
                  Navigator.pushReplacementNamed(context, '/clinician_dashboard');
                },
                icon: const Icon(Icons.task_alt_rounded),
                label: const Text('Submit Application for Verification'),
              ),
              const SizedBox(height: 16),

              // Trust Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _trustBadge(Icons.security_rounded, 'HIPAA/DISHA'),
                  const SizedBox(width: 12),
                  _trustBadge(Icons.health_and_safety_rounded, 'WHO Standards'),
                  const SizedBox(width: 12),
                  _trustBadge(Icons.volunteer_activism_rounded, 'ICDS Connected'),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, {bool isReq = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text,
          style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          children: [
            if (isReq) const TextSpan(text: ' *', style: TextStyle(color: AppColors.statusRed)),
          ],
        ),
      ),
    );
  }

  Widget _trustBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
