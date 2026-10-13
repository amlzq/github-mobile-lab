import 'package:flutter/material.dart';

import '../../../domain/models/issue.dart';
import '../../../utils/formatting.dart';
import '../../core/widgets/language_color.dart';

/// Issue / Pull Request result row: state icon, `owner/repo #n` header with
/// relative time, title, label chips and a comment count chip.
class IssueListItem extends StatelessWidget {
  const IssueListItem({super.key, required this.item});

  final IssueSummary item;

  Color get _stateColor {
    if (item.state == 'open') return const Color(0xFF1A7F37);
    // Closed issues render purple, closed/merged PRs red on GitHub.
    return item.isPullRequest
        ? const Color(0xFFCF222E)
        : const Color(0xFF8250DF);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtle = theme.colorScheme.onSurfaceVariant;
    final repository = item.repoFullName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(
              item.isPullRequest ? Icons.call_merge : Icons.adjust,
              size: 18,
              color: _stateColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        repository == null || repository.isEmpty
                            ? '#${item.number}'
                            : '$repository #${item.number}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtle,
                        ),
                      ),
                    ),
                    if (item.createdAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        timeAgo(item.createdAt!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge,
                ),
                if (item.labels.isNotEmpty || item.commentsCount > 0) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final label in item.labels) _LabelChip(label: label),
                      if (item.commentsCount > 0)
                        _CommentChip(count: item.commentsCount),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.label});

  final IssueLabel label;

  @override
  Widget build(BuildContext context) {
    final background = colorFromHex(label.colorHex);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.name,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: contrastOn(background),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CommentChip extends StatelessWidget {
  const _CommentChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtle = theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mode_comment_outlined, size: 13, color: subtle),
          const SizedBox(width: 4),
          Text('$count', style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
