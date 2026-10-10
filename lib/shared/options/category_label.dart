import 'package:attendly/data/tables/enums/category.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

String localizedCategoryLabel(BuildContext context, String rawCategory) {
  final l = AppLocalizations.of(context);
  try {
    final cat = Category.values.byName(rawCategory);
    switch (cat) {
      case Category.open:
        return l.open;
      case Category.offer:
        return l.offers;
      case Category.parent:
        return l.parent;
      case Category.other:
        return l.other;
    }
  } catch (_) {
    return rawCategory;
  }
}
