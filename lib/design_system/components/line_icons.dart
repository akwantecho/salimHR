import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum LineIconType {
  search,
  bell,
  calendar,
  chat,
  chart,
  heart,
  bookmark,
  home,
  arrowBack,
  trash,
  check,
  history,
  plus,
  copy,
  refresh,
  send,
  mic,
}

class DSLineIcon extends StatelessWidget {
  final LineIconType type;
  final Color color;
  final double size;

  const DSLineIcon({
    super.key,
    required this.type,
    required this.color,
    this.size = 22,
  });

  String _path(LineIconType type) {
    switch (type) {
      case LineIconType.search:
        return 'assets/icons/heroicons/search.svg';
      case LineIconType.bell:
        return 'assets/icons/heroicons/bell.svg';
      case LineIconType.calendar:
        return 'assets/icons/heroicons/calendar.svg';
      case LineIconType.chat:
        return 'assets/icons/heroicons/chat.svg';
      case LineIconType.chart:
        return 'assets/icons/heroicons/chart.svg';
      case LineIconType.heart:
        return 'assets/icons/heroicons/heart.svg';
      case LineIconType.bookmark:
        return 'assets/icons/heroicons/bookmark.svg';
      case LineIconType.home:
        return 'assets/icons/heroicons/home.svg';
      case LineIconType.arrowBack:
        return 'assets/icons/heroicons/arrow-back.svg';
      case LineIconType.trash:
        return 'assets/icons/heroicons/trash.svg';
      case LineIconType.check:
        return 'assets/icons/heroicons/check.svg';
      case LineIconType.history:
        return 'assets/icons/heroicons/history.svg';
      case LineIconType.plus:
        return 'assets/icons/heroicons/plus.svg';
      case LineIconType.copy:
        return 'assets/icons/heroicons/copy.svg';
      case LineIconType.refresh:
        return 'assets/icons/heroicons/refresh.svg';
      case LineIconType.send:
        return 'assets/icons/heroicons/send.svg';
      case LineIconType.mic:
        return 'assets/icons/heroicons/mic.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBack = type == LineIconType.arrowBack;
    // Back arrows read larger and must mirror with the text direction so they
    // point the correct way in RTL. Handled here so every back button is fixed.
    final effectiveSize = isBack ? size + 8 : size;

    return SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: SvgPicture.asset(
        _path(type),
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        width: effectiveSize,
        height: effectiveSize,
        fit: BoxFit.contain,
        matchTextDirection: isBack,
      ),
    );
  }
}
