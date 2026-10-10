import 'package:attendly/core/logging/app_logger.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/tables/enums/gender.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A person in the directory list: name, edit/delete (or a check mark in
/// selection mode), and the details when expanded.
class PersonTile extends StatelessWidget {
  final DirectoryPeopleData person;
  final bool isExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final VoidCallback onTap;
  final VoidCallback onDeletePress;
  final VoidCallback onEditPress;
  final bool isSelected;
  final bool isSelectionMode;

  const PersonTile({
    super.key,
    required this.person,
    required this.isExpanded,
    this.onExpansionChanged,
    required this.onTap,
    required this.onDeletePress,
    required this.onEditPress,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  static int _ageOn(DateTime today, DateTime birthDate) {
    var age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age > 0 ? age : 0;
  }

  List<Widget> _buildDetails(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final responsive = Responsive.of(context);
    final birthday = DateFormat('dd.MM.yyyy').format(person.birthday);
    final age = _ageOn(DateTime.now(), person.birthday);
    final style = TextStyle(
      fontSize: responsive.isTablet ? 22.0 * responsive.textScaleFactor : 20.0,
    );

    return [
      Text("• ${localizations.birthday}: $birthday ($age)", style: style),
      Text("• ${localizations.gender}: ${person.gender.localizedName(localizations)}", style: style),
      Text(
        "• ${localizations.migration}: ${person.migration ? localizations.trueValue : localizations.falseValue}",
        style: style,
      ),
      if (person.migration)
        Text("• ${localizations.country}: ${person.migrationBackground ?? 'N/A'}", style: style),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive.of(context);
    final isTablet = responsive.isTablet;

    final cardColor = isSelected
        ? theme.primaryColor.withAlpha(15)
        : theme.cardTheme.color;
    final textColor = isSelected
        ? theme.primaryColor
        : theme.textTheme.bodyLarge?.color ?? Colors.black;

    final iconSize = responsive.iconSize(baseSize: 34);
    final smallIconSize = responsive.iconSize(baseSize: 28);
    final innerPad = responsive.contentPadding;
    final baseElevation = responsive.cardElevation;
    final radius = responsive.cardBorderRadius;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: responsive.listPadding.vertical / 2),
      child: Card(
        key: ValueKey(person.id),
        color: cardColor,
        elevation: isSelected ? baseElevation + 1 : baseElevation,
        shadowColor: isSelected
            ? theme.primaryColor.withValues(alpha:0.4)
            : Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: isSelected
              ? BorderSide(color: theme.primaryColor, width: isTablet ? 2.0 : 1.5)
              : BorderSide(color: Colors.grey.shade200, width: isTablet ? 1.5 : 1),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(
                padding: innerPad,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        person.name,
                        style: TextStyle(
                          fontSize: responsive.titleFontSize,
                          color: textColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: smallIconSize,
                      ),
                      onPressed: () => onExpansionChanged?.call(!isExpanded),
                    ),
                    if (isSelectionMode)
                      isSelected
                          ? Icon(Icons.check_circle, color: theme.primaryColor, size: iconSize)
                          : Icon(Icons.radio_button_unchecked, color: Colors.grey, size: iconSize)
                    else ...[
                      IconButton(
                        onPressed: () {
                          AppLogger.d("UI", "Editing person ${person.id}");
                          onEditPress();
                        },
                        icon: Icon(Icons.edit,
                            color: Colors.blueGrey, size: smallIconSize),
                        iconSize: smallIconSize,
                      ),
                      IconButton(
                        onPressed: onDeletePress,
                        icon: Icon(Icons.delete,
                            color: Colors.redAccent,
                            size: smallIconSize),
                        iconSize: smallIconSize,
                      ),
                    ]
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: Container(),
              secondChild: Padding(
                padding: EdgeInsets.fromLTRB(innerPad.left, 0, innerPad.right, innerPad.bottom),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildDetails(context),
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}
