import 'package:flutter/material.dart';
import 'package:attendly/localization/app_localizations.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';

class CustomExpansion extends StatefulWidget {
  final List<Map<String, dynamic>> allPeopleList;
  final bool isExpanded;
  final int index;
  final ValueChanged<bool>? onExpansionChanged;
  final VoidCallback onTap;
  final VoidCallback onDeletePress;
  final VoidCallback onEditPress;
  final List<Widget> buildChildren;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isTablet;

  const CustomExpansion({
    super.key,
    required this.allPeopleList,
    required this.index,
    required this.isExpanded,
    this.onExpansionChanged,
    required this.onTap,
    required this.onDeletePress,
    required this.onEditPress,
    required this.buildChildren,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.isTablet = false,
  });

  @override
  CustomExpansionState createState() => CustomExpansionState();
}

class CustomExpansionState extends State<CustomExpansion> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isTablet = widget.isTablet || ResponsiveUtils.isTablet(context);

    final cardColor = widget.isSelected
        ? theme.primaryColor.withAlpha(15)
        : Theme.of(context).cardTheme.color;
    final textColor = widget.isSelected
        ? theme.primaryColor
        : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    // Use ResponsiveUtils for sizing
    final idFontSize = ResponsiveUtils.getTitleFontSize(context);
    final nameFontSize = ResponsiveUtils.getTitleFontSize(context);
    final iconSize = ResponsiveUtils.getIconSize(context, baseSize: 34);
    final smallIconSize = ResponsiveUtils.getIconSize(context, baseSize: 28);
    final edgeInsets = ResponsiveUtils.getListPadding(context);
    final innerPad = ResponsiveUtils.getContentPadding(context);
    final baseElevation = ResponsiveUtils.getCardElevation(context);
    final cardElevation = widget.isSelected ? baseElevation + 1 : baseElevation;
    final radius = ResponsiveUtils.getCardBorderRadius(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: edgeInsets.vertical / 2),
      child: Card(
        key: ValueKey(widget.allPeopleList[widget.index]['id']),
        color: cardColor,
        elevation: cardElevation,
        shadowColor: widget.isSelected
            ? theme.primaryColor.withValues(alpha:0.4)
            : Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: widget.isSelected
              ? BorderSide(color: theme.primaryColor, width: isTablet ? 2.0 : 1.5)
              : BorderSide(color: Colors.grey.shade200, width: isTablet ? 1.5 : 1),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: widget.onTap,
              borderRadius: radius,
              child: Padding(
              padding: innerPad,
                child: Row(
                  children: [
                    Text(
                      widget.allPeopleList[widget.index]["id"].toString(),
                      style: TextStyle(
                        fontSize: idFontSize,
                        color: textColor,
                        fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                    SizedBox(width: innerPad.horizontal / 2),
                    Expanded(
                      child: Text(
                        widget.allPeopleList[widget.index]["name"].toString(),
                        style: TextStyle(
                          fontSize: nameFontSize,
                          color: textColor,
                          fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: smallIconSize,
                      ),
                      onPressed: () {
                        widget.onExpansionChanged?.call(!widget.isExpanded);
                      },
                    ),
                    if (widget.isSelectionMode)
                      widget.isSelected
                          ? Icon(Icons.check_circle, color: theme.primaryColor, size: iconSize)
                          : Icon(Icons.radio_button_unchecked, color: Colors.grey, size: iconSize)
                    else ...[
                      IconButton(
                        onPressed: () {
                          debugPrint("Editing ${widget.index}");
                          widget.onEditPress();
                        },
                        icon: Icon(Icons.edit, 
                        color: Colors.blueGrey, size: smallIconSize),
                        iconSize: smallIconSize,
                      ),
                      IconButton(
                        onPressed: widget.onDeletePress,
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
                      child: Padding(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.buildChildren.isNotEmpty
                              ? widget.buildChildren
                              : [
                                  Text(
                                    localizations.noData,
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.getBodyFontSize(context),
                                    ),
                                  )
                                ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: widget.isExpanded
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