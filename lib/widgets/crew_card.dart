import 'package:flutter/material.dart';

import '../core/app_page_route.dart';
import '../core/theme.dart';
import '../pages/person_select_page.dart';
import '../services/database.dart';
import 'info_chip.dart';
import 'picker_sheet.dart';
import 'section_header.dart';

/// SELF plus the other crew of a flight. Editable by default; use
/// [CrewCard.readOnly] to only display it.
class CrewCard extends StatelessWidget {
  const CrewCard({
    super.key,
    required this.pilotRole,
    required this.crewMembers,
    this.errorText,
    required ValueChanged<CrewRole> this.onPilotRoleChanged,
    required ValueChanged<CrewMember> this.onCrewMemberAdded,
    required ValueChanged<int> this.onCrewMemberRemoved,
    required void Function(int index, CrewMember member)
    this.onCrewMemberChanged,
    this.proficiencyCheck = false,
    this.onProficiencyCheckChanged,
  }) : onCrewMemberTap = null;

  /// No role changes, no add or remove. [onCrewMemberTap], if given, is
  /// called when a crew member is tapped.
  const CrewCard.readOnly({
    super.key,
    required this.pilotRole,
    required this.crewMembers,
    this.onCrewMemberTap,
  }) : errorText = null,
       proficiencyCheck = false,
       onProficiencyCheckChanged = null,
       onPilotRoleChanged = null,
       onCrewMemberAdded = null,
       onCrewMemberRemoved = null,
       onCrewMemberChanged = null;

  final CrewRole pilotRole;
  final List<CrewMember> crewMembers;

  /// Shown under the crew list when the roles are inconsistent.
  final String? errorText;
  final ValueChanged<CrewRole>? onPilotRoleChanged;
  final ValueChanged<CrewMember>? onCrewMemberAdded;
  final ValueChanged<int>? onCrewMemberRemoved;
  final void Function(int index, CrewMember member)? onCrewMemberChanged;
  final ValueChanged<CrewMember>? onCrewMemberTap;

  /// Whether the "Proficiency Check" box is ticked. The box shows while an
  /// examiner is in the crew and [onProficiencyCheckChanged] is given.
  final bool proficiencyCheck;
  final ValueChanged<bool>? onProficiencyCheckChanged;

  bool get _editable => onCrewMemberAdded != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  color: cs.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
                SectionHeader(
                  title: 'CREW',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SelfRow(
              role: pilotRole,
              onTap: _editable
                  ? () async {
                      final picked = await showCrewRolePicker(
                        context,
                        current: pilotRole,
                      );
                      if (picked != null) onPilotRoleChanged!(picked);
                    }
                  : null,
            ),
            ...crewMembers.asMap().entries.map((entry) {
              final i = entry.key;
              final member = entry.value;
              return Column(
                children: [
                  const Divider(height: 1),
                  _CrewMemberRow(
                    member: member,
                    onRemove: _editable ? () => onCrewMemberRemoved!(i) : null,
                    onTap: _editable
                        ? () async {
                            final role = await showCrewRolePicker(
                              context,
                              current: member.role,
                            );
                            if (role != null && role != member.role) {
                              onCrewMemberChanged!(
                                i,
                                CrewMember(person: member.person, role: role),
                              );
                            }
                          }
                        : onCrewMemberTap == null
                        ? null
                        : () => onCrewMemberTap!(member),
                  ),
                ],
              );
            }),
            if (_editable) ...[
              const Divider(height: 1),
              InkWell(
                onTap: () => _addCrewMember(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add_outlined,
                        color: cs.onSurfaceVariant,
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Add crew member',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (onProficiencyCheckChanged != null &&
                crewMembers.any((m) => m.role == CrewRole.exm)) ...[
              const Divider(height: 1),
              CheckboxListTile(
                value: proficiencyCheck,
                onChanged: (v) => onProficiencyCheckChanged!(v ?? false),
                title: const Text('Check Passed'),
                subtitle: const Text(
                  'A skill test or proficiency check passed: the last check '
                  'of the aircraft\'s class or type rating. Flown as '
                  'candidate (DUAL), it is logged as PIC time for the '
                  'examiner to countersign',
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.error_outline, color: cs.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 1. pick the role, 2. pick (or create) the person, 3. add them.
  Future<void> _addCrewMember(BuildContext context) async {
    final role = await showCrewRolePicker(context);
    if (role == null || !context.mounted) return;
    final person = await Navigator.push<Person>(
      context,
      AppPageRoute(
        builder: (_) => PersonSelectPage(
          title: 'Select ${role.displayName}',
          excludeIds: {for (final m in crewMembers) m.person.id},
        ),
      ),
    );
    if (person != null) {
      onCrewMemberAdded!(CrewMember(person: person, role: role));
    }
  }
}

class _SelfRow extends StatelessWidget {
  const _SelfRow({required this.role, this.onTap});
  final CrewRole role;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _alignedRoleChip(context, role),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SELF',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    onTap != null
                        ? 'Tap to change your role'
                        : role.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

class _CrewMemberRow extends StatelessWidget {
  const _CrewMemberRow({required this.member, this.onRemove, this.onTap});
  final CrewMember member;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _alignedRoleChip(context, member.role),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.person.fullName,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    member.role.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (onRemove != null)
              IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: theme.colorScheme.error,
                ),
                tooltip: 'Remove from crew',
                onPressed: onRemove,
              ),
            if (onRemove == null && onTap != null)
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

/// [InfoChip] with the role's abbreviation in the role's colours.
InfoChip crewRoleChip(BuildContext context, CrewRole role) {
  final colors = context.appColors.crewRole(role);
  return InfoChip(
    label: role.abbreviation,
    backgroundColor: colors.container,
    textColor: colors.onContainer,
  );
}

/// [crewRoleChip] in a fixed-width slot, so the text beside a column of
/// chips lines up.
Widget _alignedRoleChip(BuildContext context, CrewRole role) => SizedBox(
  width: 60,
  child: Align(
    alignment: Alignment.centerLeft,
    child: crewRoleChip(context, role),
  ),
);

/// Roles from the most to the least commonly logged: everyday command and
/// co-pilot, then training and checking, then relief and the rest.
const _rolesByLikelyUse = [
  CrewRole.pic,
  CrewRole.sic,
  CrewRole.dual,
  CrewRole.ins,
  CrewRole.picus,
  CrewRole.spic,
  CrewRole.exm,
  CrewRole.sp,
  CrewRole.crcp,
  CrewRole.p3,
  CrewRole.att,
  CrewRole.oth,
];

Future<CrewRole?> showCrewRolePicker(
  BuildContext context, {
  CrewRole? current,
}) {
  return showPickerSheet<CrewRole>(
    context,
    title: 'Select Role',
    items: _rolesByLikelyUse,
    label: (r) => r.displayName,
    subtitle: (r) => r.subtitle,
    leading: (r) => _alignedRoleChip(context, r),
    selected: current,
    searchHint: null,
  );
}
