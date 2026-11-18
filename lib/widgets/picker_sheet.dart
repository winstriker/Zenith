import 'package:flutter/material.dart';

/// Bottom sheet listing [items] to pick one from, with a search field when
/// there are many. Resolves to the picked item, or null when dismissed.
Future<T?> showPickerSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T item) label,
  String Function(T item)? subtitle,
  T? selected,
  String searchHint = 'Search...',
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PickerSheet<T>(
      title: title,
      items: items,
      label: label,
      subtitle: subtitle,
      selected: selected,
      searchHint: searchHint,
    ),
  );
}

class _PickerSheet<T> extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.items,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.searchHint,
  });

  final String title;
  final List<T> items;
  final String Function(T item) label;
  final String Function(T item)? subtitle;
  final T? selected;
  final String searchHint;

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  String _query = '';

  /// Short lists fit on screen and need no search.
  bool get _searchable => widget.items.length > 8;

  List<T> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return [
      for (final item in widget.items)
        if (widget.label(item).toLowerCase().contains(q) ||
            (widget.subtitle?.call(item).toLowerCase().contains(q) ?? false))
          item,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final items = _filtered;

    Widget list(ScrollController? controller) => ListView.builder(
      controller: controller,
      shrinkWrap: controller == null,
      padding: EdgeInsets.only(
        bottom: 16 + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final selected = item == widget.selected;
        final subtitle = widget.subtitle?.call(item);
        return ListTile(
          title: Text(widget.label(item)),
          subtitle: subtitle == null ? null : Text(subtitle),
          selected: selected,
          trailing: selected ? Icon(Icons.check, color: cs.primary) : null,
          onTap: () => Navigator.pop(context, item),
        );
      },
    );

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        widget.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (!_searchable) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Flexible(child: list(null)),
        ],
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Nothing matches "${_query.trim()}"',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                : list(controller),
          ),
        ],
      ),
    );
  }
}

/// A read-only field that opens a picker when tapped.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
    this.onClear,
    this.errorText,
    this.helperText,
  });

  final String label;
  final IconData icon;
  final String? value;

  /// Null disables the field.
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final String? errorText;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final onClear = this.onClear;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          errorText: errorText,
          helperText: helperText,
          helperMaxLines: 2,
          enabled: onTap != null,
          suffixIcon: onClear != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  tooltip: 'Clear',
                  onPressed: onClear,
                )
              : const Icon(Icons.arrow_drop_down),
        ),
        child: value == null
            ? null
            : Text(value!, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// A [PickerField] that picks one of [items] from a [showPickerSheet] titled
/// [label]. Null [onChanged] disables it.
class SelectField<T> extends StatelessWidget {
  const SelectField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final IconData icon;
  final T? value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T>? onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    final onChanged = this.onChanged;
    return PickerField(
      label: label,
      icon: icon,
      value: value == null ? null : itemLabel(value),
      errorText: errorText,
      onTap: onChanged == null
          ? null
          : () async {
              final picked = await showPickerSheet<T>(
                context,
                title: label,
                items: items,
                label: itemLabel,
                selected: value,
              );
              if (picked != null) onChanged(picked);
            },
    );
  }
}

/// Bold inline value that opens a [showPickerSheet] titled [title] when
/// tapped. Null [onChanged] renders it as plain read-only text.
class InlineSelect<T> extends StatelessWidget {
  const InlineSelect({
    super.key,
    required this.title,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String title;
  final T value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    final text = Text(
      itemLabel(value),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    );
    if (onChanged == null) return text;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final picked = await showPickerSheet<T>(
          context,
          title: title,
          items: items,
          label: itemLabel,
          selected: value,
        );
        if (picked != null) onChanged(picked);
      },
      child: Row(
        children: [
          Flexible(child: text),
          Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
