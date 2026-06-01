import 'package:flutter/widgets.dart';

import '../ds_provider.dart';
import '../tokens/typography.dart';

export '../tokens/typography.dart' show DSTextRole;

class DSText extends StatelessWidget {
  final String data;
  final DSTextRole role;
  final Color? color;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow overflow;
  final TextDirection? textDirection;

  const DSText(
    this.data, {
    super.key,
    this.role = DSTextRole.body,
    this.color,
    this.align,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    final ds = DSProvider.of(context);
    final baseStyle = ds.typography.resolve(role);
    return Text(
      data,
      locale: ds.locale,
      textDirection: textDirection ?? ds.textDirection,
      maxLines: maxLines,
      overflow: maxLines == null ? null : overflow,
      textAlign: align,
      style: baseStyle.copyWith(
        color: color ?? baseStyle.color,
      ),
    );
  }
}
