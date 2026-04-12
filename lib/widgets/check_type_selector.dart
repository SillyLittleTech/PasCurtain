import 'package:flutter/material.dart';

import '../models/breach_result.dart';

/// A toggle widget for switching between password and email check modes.
class CheckTypeSelector extends StatelessWidget {
  const CheckTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final CheckType selected;
  final ValueChanged<CheckType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SegmentedButton<CheckType>(
      segments: const [
        ButtonSegment(
          value: CheckType.password,
          icon: Icon(Icons.lock_outline),
          label: Text('Password'),
        ),
        ButtonSegment(
          value: CheckType.email,
          icon: Icon(Icons.email_outlined),
          label: Text('Email'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (set) => onChanged(set.first),
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
