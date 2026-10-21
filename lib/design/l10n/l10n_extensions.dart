import 'package:flutter/widgets.dart';
import 'package:lingua/gen/l10n/app_localizations.dart';

extension L10nX on BuildContext {
  /// Shortcut: `context.l10n.welcome` thay vì `AppLocalizations.of(context)!.welcome`.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
