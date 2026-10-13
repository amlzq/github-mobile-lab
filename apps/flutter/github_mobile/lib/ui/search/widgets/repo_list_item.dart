import 'package:flutter/material.dart';

import '../../../domain/models/repository.dart';
import '../../../utils/formatting.dart';
import '../../core/widgets/language_color.dart';

/// Repository result row, mirroring the GitHub mobile design:
/// owner header, bold name, description, stars + language.
class RepoListItem extends StatelessWidget {
  const RepoListItem({super.key, required this.repository});

  final RepositorySummary repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtle = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundImage: NetworkImage(repository.ownerAvatarUrl),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                onBackgroundImageError: (_, _) {},
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  repository.ownerLogin,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: subtle),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            repository.fullName.split('/').last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (repository.description != null &&
              repository.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              repository.description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: Color(0xFFE2B93B)),
              const SizedBox(width: 4),
              Text(
                formatCompactCount(repository.stargazersCount),
                style: theme.textTheme.bodySmall?.copyWith(color: subtle),
              ),
              if (repository.language != null) ...[
                const SizedBox(width: 16),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: languageColor(repository.language),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  repository.language!,
                  style: theme.textTheme.bodySmall?.copyWith(color: subtle),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
