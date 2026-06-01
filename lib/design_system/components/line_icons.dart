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
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.asset(
        _path(type),
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
