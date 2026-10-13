import 'package:flutter/material.dart';

import '../../../domain/models/code.dart';

/// Code result card, mirroring the GitHub mobile design: owner/repo header,
/// file name, and a bordered snippet box with language pill and highlighted
/// query matches.
class CodeListItem extends StatelessWidget {
  const CodeListItem({super.key, required this.item});

  final CodeSummary item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 9,
                backgroundImage: NetworkImage(item.ownerAvatarUrl),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                onBackgroundImageError: (_, _) {},
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.repoFullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.language != null && item.language!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: theme.dividerColor),
                        const SizedBox(width: 4),
                        Text(
                          item.language!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                for (final match in item.textMatches.take(2))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _CodeFragment(match: match),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Monospace snippet with yellow highlight on matched segments.
class _CodeFragment extends StatelessWidget {
  const _CodeFragment({required this.match});

  final CodeTextMatch match;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontSize: 12,
      height: 1.45,
    );
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          for (final segment in match.segments)
            TextSpan(
              text: segment.text,
              style: segment.highlighted
                  ? const TextStyle(backgroundColor: Color(0xFFFFF1A6))
                  : null,
            ),
        ],
      ),
      maxLines: 8,
      overflow: TextOverflow.ellipsis,
    );
  }
}
