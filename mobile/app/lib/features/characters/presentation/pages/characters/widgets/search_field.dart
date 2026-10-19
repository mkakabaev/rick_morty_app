import 'package:app/l10n/l10n.dart';
import 'package:flutter/material.dart';

class CharacterSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onTapOutside;

  const CharacterSearchField({
    super.key,
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
    required this.onTapOutside,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    const searchBorder = OutlineInputBorder(borderRadius: .all(.circular(28)), borderSide: .none);

    return Padding(
      padding: const .fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: l10n.searchCharacters,
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHigh,
          prefixIcon: const Padding(padding: .only(left: 12), child: Icon(Icons.search)),
          suffixIcon: query.isEmpty
              ? null
              : Padding(
                  padding: const .only(right: 4),
                  child: IconButton(tooltip: l10n.clearSearch, onPressed: onClear, icon: const Icon(Icons.close)),
                ),
          border: searchBorder,
          enabledBorder: searchBorder,
          focusedBorder: searchBorder,
          disabledBorder: searchBorder,
          errorBorder: searchBorder,
          focusedErrorBorder: searchBorder,
        ),
        textInputAction: .search,
        textCapitalization: .none,
        keyboardType: .text,
        autocorrect: false,
        enableSuggestions: false,
        enableIMEPersonalizedLearning: false,
        spellCheckConfiguration: const .disabled(),
        smartDashesType: .disabled,
        smartQuotesType: .disabled,
        onChanged: onChanged,
        onTapOutside: (_) => onTapOutside(),
      ),
    );
  }
}
