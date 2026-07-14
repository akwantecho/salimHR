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
  user,
  chevronForward,
  lock,
  envelope,
  logout,
  globe,
  info,
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
      case LineIconType.user:
        return 'assets/icons/heroicons/user.svg';
      case LineIconType.chevronForward:
        return 'assets/icons/heroicons/chevron-forward.svg';
      case LineIconType.lock:
        return 'assets/icons/heroicons/lock.svg';
      case LineIconType.envelope:
        return 'assets/icons/heroicons/envelope.svg';
      case LineIconType.logout:
        return 'assets/icons/heroicons/logout.svg';
      case LineIconType.globe:
        return 'assets/icons/heroicons/globe.svg';
      case LineIconType.info:
        return 'assets/icons/heroicons/info.svg';
    }
  }

  /// Icons whose meaning is tied to reading direction and must mirror in RTL
  /// (a "back" chevron points the opposite way in Arabic).
  static const _directional = {
    LineIconType.arrowBack,
    LineIconType.chevronForward,
  };

  @override
  Widget build(BuildContext context) {
    Widget icon = SvgPicture.asset(
      _path(type),
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    final isRtl =
        (Directionality.maybeOf(context) ?? TextDirection.ltr) ==
            TextDirection.rtl;
    if (isRtl && _directional.contains(type)) {
      icon = Transform.flip(flipX: true, child: icon);
    }

    return SizedBox(width: size, height: size, child: icon);
  }
}
