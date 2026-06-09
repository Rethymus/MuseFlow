import 'package:flutter/material.dart';
import 'package:museflow/features/onboarding/domain/genre_option.dart';

/// Genre selection step for the onboarding wizard.
///
/// Displays a grid of genre cards from the built-in [GenreOption] list.
/// The user taps a card to select a genre, which highlights the border.
class GenreStepPage extends StatefulWidget {
  const GenreStepPage({super.key, required this.onSelected});

  /// Called when a genre card is tapped.
  /// Passes the selected [GenreOption.id].
  final ValueChanged<String> onSelected;

  @override
  State<GenreStepPage> createState() => _GenreStepPageState();
}

class _GenreStepPageState extends State<GenreStepPage>
    with AutomaticKeepAliveClientMixin {
  String? _selectedGenreId;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final genres = GenreOption.builtIn;

    if (genres.isEmpty) {
      return Center(
        child: Text(
          '暂无模板',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: genres.length,
      itemBuilder: (context, index) {
        final genre = genres[index];
        final isSelected = _selectedGenreId == genre.id;
        return _GenreCard(
          genre: genre,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedGenreId = genre.id;
            });
            widget.onSelected(genre.id);
          },
        );
      },
    );
  }
}

/// A single genre card in the selection grid.
///
/// Shows icon, title, description, channel and tag badges.
/// Border highlights when selected.
class _GenreCard extends StatelessWidget {
  const _GenreCard({
    required this.genre,
    required this.isSelected,
    required this.onTap,
  });

  final GenreOption genre;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and title row
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  child: Icon(
                    genre.icon,
                    size: 16,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    genre.title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Description
            Expanded(
              child: Text(
                genre.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // Tags row
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: [
                _PassiveTag(label: genre.channel),
                ...genre.tags.map((tag) => _PassiveTag(label: tag)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A small non-interactive tag badge, matching the _PassiveTag pattern.
class _PassiveTag extends StatelessWidget {
  const _PassiveTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
