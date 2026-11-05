import 'package:flutter/material.dart';
import '../models/child_model.dart';
import '../services/child_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'missing_field_dialogs.dart';

/// Interactive AppBar / Header pill that displays the currently selected child
/// and allows switching between multiple children or registering a new child.
class ChildSelectorPill extends StatelessWidget {
  final bool isCompact;

  const ChildSelectorPill({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ChildModel?>(
      valueListenable: ChildSession.instance.selectedChildNotifier,
      builder: (context, activeChild, _) {
        if (activeChild == null) {
          // If no children registered yet
          return InkWell(
            onTap: () => showAddNewChildDialog(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primaryDark),
                  SizedBox(width: 6),
                  Text(
                    '+ Add Child',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final ageStr = activeChild.ageDisplay.isNotEmpty ? ' (${activeChild.ageDisplay})' : '';
        final isGirl = activeChild.gender.toLowerCase() == 'girl';

        return InkWell(
          onTap: () => showChildSelectorSheet(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isGirl
                  ? Colors.pink.shade50
                  : AppColors.primaryContainer.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isGirl ? Colors.pink.shade200 : AppColors.primary.withOpacity(0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: isGirl ? Colors.pink.shade400 : AppColors.primary,
                  child: Text(
                    activeChild.shortInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isCompact ? 110 : 160),
                  child: Text(
                    '${activeChild.name}$ageStr',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isGirl ? Colors.pink.shade900 : AppColors.primaryDark,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: isGirl ? Colors.pink.shade900 : AppColors.primaryDark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Bottom modal sheet allowing parent to select among multiple children or add a new child
void showChildSelectorSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: ValueListenableBuilder<List<ChildModel>>(
          valueListenable: ChildSession.instance.childrenNotifier,
          builder: (context, children, _) {
            final activeChild = ChildSession.instance.selectedChild;

            return Column(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Child Profile',
                          style: AppTypography.headline3.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'બાળકની પસંદગી • Switch active care plan',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                if (children.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'No children added yet.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ] else ...[
                  ...children.map((child) {
                    final isSelected = activeChild?.id == child.id;
                    final isGirl = child.gender.toLowerCase() == 'girl';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isGirl ? Colors.pink.shade50 : AppColors.primaryContainer.withOpacity(0.5))
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? (isGirl ? Colors.pink.shade300 : AppColors.primary)
                              : AppColors.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: isGirl ? Colors.pink.shade400 : AppColors.primary,
                          child: Text(
                            child.shortInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                child.name,
                                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isGirl ? Colors.pink.shade100 : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                child.gender,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isGirl ? Colors.pink.shade800 : Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Age: ${child.ageDisplay.isNotEmpty ? child.ageDisplay : "DOB: ${child.dob}"} • Weight: ${child.weightDisplay}',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24)
                            : const Icon(Icons.radio_button_unchecked_rounded, color: AppColors.textMuted, size: 20),
                        onTap: () {
                          ChildSession.instance.selectChild(child);
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                  label: const Text(
                    '+ Add Another Child (બીજું બાળક ઉમેરો)',
                    style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    showAddNewChildDialog(context);
                  },
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

