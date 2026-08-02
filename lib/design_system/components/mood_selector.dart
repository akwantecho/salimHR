import 'package:flutter/widgets.dart';

import '../ds_provider.dart';
import '../primitives/ds_text.dart';

class MoodOption {
  final String emoji;
  final String label;
  final Color color;

  const MoodOption({
    required this.emoji,
    required this.label,
    required this.color,
  });
}

class MoodSelector extends StatelessWidget {
  final List<MoodOption> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const MoodSelector({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < options.length; i++) ...[
            if (i > 0) SizedBox(width: ds.spacing.sm),
            _MoodChip(
              option: options[i],
              isSelected: i == selectedIndex,
              onTap: () => onChanged(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  final MoodOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final circleSize = ds.spacing.xl + ds.spacing.md;
    final Color bg = isSelected
        ? option.color.withValues(alpha: 0.28)
        : ds.colors.surface;
    final Color border = option.color.withValues(alpha: 0.55);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: ds.animation.normal,
        curve: ds.animation.curve,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: ds.spacing.md,
          vertical: ds.spacing.sm,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(ds.radii.large),
          border: Border.all(
            color: isSelected ? border : ds.colors.border,
          ),
          boxShadow: isSelected ? ds.shadows.level2 : ds.shadows.level1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: option.color,
                shape: BoxShape.circle,
                boxShadow: ds.shadows.level1,
              ),
              alignment: Alignment.center,
              child: Text(
                option.emoji,
                style: TextStyle(
                  fontSize: ds.typography.headline.fontSize ?? 24,
                  height: 1,
                ),
              ),
            ),
            SizedBox(width: ds.spacing.sm),
            DSText(
              option.label,
              role: DSTextRole.title,
              color: ds.colors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
