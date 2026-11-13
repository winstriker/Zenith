import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/database.dart';
import 'person_avatar.dart';

/// A person row: profile picture, full name, flights together and last date.
class PersonTile extends StatelessWidget {
  const PersonTile({
    super.key,
    required this.entry,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });
  final PersonWithLastFlight entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final person = entry.person;
    final last = entry.lastFlight;

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      trailing: trailing,
      leading: PersonAvatar(name: person.name, photo: person.photo),
      title: Text(person.fullName),
      subtitle: Text(
        last == null
            ? 'No flights yet'
            : '${entry.flightCount} '
                  '${entry.flightCount == 1 ? 'flight' : 'flights'} · '
                  'last ${DateFormat.yMMMd().format(last)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
