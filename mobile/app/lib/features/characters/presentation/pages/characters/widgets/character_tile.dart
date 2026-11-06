import 'package:flutter/material.dart';

import '../../../../domain/entities/character.dart';
import '../../../shared/character_portrait.dart';

class CharacterTile extends StatelessWidget {
  final Character character;
  final RegExp? highlight;
  final bool isOffline;
  final void Function(Character) onTap;

  const CharacterTile({
    super.key,
    required this.character,
    required this.highlight,
    required this.isOffline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: SizedBox(
        width: 56,
        height: 56,
        child: ClipOval(
          child: CharacterPortrait(url: character.imageUrl, style: .small, isOffline: isOffline),
        ),
      ),
      title: _HighlightedName(name: character.name, highlight: highlight),
      subtitle: Text(
        '${character.status} · ${character.species}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      onTap: () => onTap(character),
    );
  }
}

class _HighlightedName extends StatelessWidget {
  final String name;
  final RegExp? highlight;

  const _HighlightedName({required this.name, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleMedium;
    final pattern = highlight;
    if (pattern == null) {
      return Text(name, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final highlightStyle = const TextStyle(color: Colors.orange, fontWeight: FontWeight.w700);
    final spans = <InlineSpan>[];
    name.splitMapJoin(
      pattern,
      onMatch: (match) {
        final matched = match.group(0);
        if (matched != null && matched.isNotEmpty) {
          spans.add(TextSpan(text: matched, style: highlightStyle));
        }
        return '';
      },
      onNonMatch: (text) {
        if (text.isNotEmpty) {
          spans.add(TextSpan(text: text));
        }
        return '';
      },
    );

    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
