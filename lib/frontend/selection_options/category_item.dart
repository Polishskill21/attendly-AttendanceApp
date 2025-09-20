import 'package:attendly/backend/enums/category.dart';
import 'package:attendly/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CategoryItem{
  final int id;
  final String label;
  final Category category;
  final IconData? icon;

  CategoryItem(this.id, this.label, this.category, this.icon);
}

List<CategoryItem> getCategoryItems(BuildContext context) {
  final localizations = AppLocalizations.of(context);
  return [
    CategoryItem(1, localizations.open, Category.open, FontAwesomeIcons.clipboardUser),
    CategoryItem(2, localizations.offers, Category.offer, Icons.local_offer_outlined),
    CategoryItem(3, localizations.parent,Category.parent, Icons.person_2_outlined),
    CategoryItem(4, localizations.other, Category.other, Icons.pending_outlined)
  ];
}

// Keep the old list for backward compatibility but deprecate it
@deprecated
List<CategoryItem> categoryItems = [
  CategoryItem(1, "Open", Category.open, FontAwesomeIcons.clipboardUser),
  CategoryItem(2, "Offer", Category.offer, Icons.local_offer_outlined),
  CategoryItem(3, "Parent", Category.parent, Icons.person_2_outlined),
  CategoryItem(4, "Other", Category.other, Icons.pending_outlined)
];