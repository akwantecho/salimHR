import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// Simple inline translator without a full localization setup.
String tr(BuildContext context, {required String ar, required String en}) {
  final app = AppScope.of(context);
  return app.locale.languageCode == 'en' ? en : ar;
}
