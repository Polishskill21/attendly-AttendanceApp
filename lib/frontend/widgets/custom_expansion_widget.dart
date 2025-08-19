import 'package:flutter/material.dart';
import 'package:attendly/frontend/l10n/app_localizations.dart';

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
  });

  @override
  CustomExpansionState createState() => CustomExpansionState();
}

class CustomExpansionState extends State<CustomExpansion> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cardColor = widget.isSelected
        ? theme.primaryColor.withAlpha(15)
        : Theme.of(context).cardTheme.color;
    final textColor = widget.isSelected
        ? theme.primaryColor
        : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
      child: Card(
        key: ValueKey(widget.allPeopleList[widget.index]['id']),
        color: cardColor,
        elevation: widget.isSelected ? 4 : 2,
        shadowColor: widget.isSelected
            ? theme.primaryColor.withOpacity(0.4)
            : Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: widget.isSelected
              ? BorderSide(color: theme.primaryColor, width: 1.5)
              : BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Text(
                      widget.allPeopleList[widget.index]["id"].toString(),
                      style: TextStyle(
                        fontSize: 25,
                        color: textColor,
                        fontWeight:
                            widget.isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.allPeopleList[widget.index]["name"].toString(),
                        style: TextStyle(
                          fontSize: 22,
                          color: textColor,
                          fontWeight: widget.isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(widget.isExpanded
                          ? Icons.expand_less
                          : Icons.expand_more),
                      onPressed: () {
                        widget.onExpansionChanged?.call(!widget.isExpanded);
                      },
                    ),
                    if (widget.isSelectionMode)
                      widget.isSelected
                          ? Icon(Icons.check_circle,
                              color: theme.primaryColor, size: 28)
                          : const Icon(Icons.radio_button_unchecked,
                              color: Colors.grey, size: 28)
                    else ...[
                      IconButton(
                        onPressed: () {
                          debugPrint("Editing ${widget.index}");
                          widget.onEditPress();
                        },
                        icon: const Icon(
                          Icons.edit, color: Colors.blueGrey
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onDeletePress,
                        icon: const Icon(
                          Icons.delete, color: Colors.redAccent
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: Container(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: widget.buildChildren.isNotEmpty
                              ? widget.buildChildren
                              : [Text(localizations.noData)],
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