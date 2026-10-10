import 'package:attendly/data/tables/enums/category.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CategoryOption{
  final int id;
  final String label;
  final Category category;
  final IconData? icon;

  CategoryOption(this.id, this.label, this.category, this.icon);
}

List<CategoryOption> getCategoryOptions(BuildContext context) {
  final localizations = AppLocalizations.of(context);
  return [
    CategoryOption(1, localizations.open, Category.open, FontAwesomeIcons.clipboardUser.data),
    CategoryOption(2, localizations.offers, Category.offer, Icons.local_offer_outlined),
    CategoryOption(3, localizations.parent,Category.parent, Icons.person_2_outlined),
    CategoryOption(4, localizations.other, Category.other, Icons.pending_outlined)
  ];
}
