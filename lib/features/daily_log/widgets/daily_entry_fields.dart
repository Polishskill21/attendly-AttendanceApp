import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/data/tables/enums/category.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:attendly/shared/options/category_option.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bold label above a form field.
class FieldLabel extends StatelessWidget {
  final String text;

  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: Responsive.of(context).bodyFontSize,
      ),
    );
  }
}

/// Card that shows the selected people and opens the person picker.
class PersonSelectionCard extends StatelessWidget {
  final List<String> names;

  /// Null when the people were preselected and cannot be changed.
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const PersonSelectionCard({
    super.key,
    required this.names,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final responsive = Responsive.of(context);
    final isEmpty = names.isEmpty;

    return Card(
      elevation: responsive.cardElevation + 2,
      shape: RoundedRectangleBorder(borderRadius: responsive.cardBorderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: responsive.cardBorderRadius,
        child: Padding(
          padding: responsive.contentPadding,
          child: Row(
            children: [
              Icon(
                isEmpty ? Icons.person_add : Icons.group,
                size: responsive.iconSize(baseSize: 40),
                color: isEmpty ? Colors.grey : Colors.blue,
              ),
              SizedBox(width: responsive.contentPadding.horizontal / 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEmpty
                        ? localizations.tapToSelectPersons
                        : localizations.personsSelected(names.length),
                      style: TextStyle(
                        fontSize: responsive.bodyFontSize,
                        fontWeight: FontWeight.bold,
                        color: isEmpty ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    if (!isEmpty) ...[
                      SizedBox(height: responsive.listPadding.vertical / 2),
                      Text(
                        names.join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: responsive.bodyFontSize - 2,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isEmpty && onClear != null)
                IconButton(
                  onPressed: onClear,
                  icon: Icon(Icons.close, color: Colors.red, size: responsive.iconSize()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category dropdown with a clear button.
class CategoryDropdown extends StatelessWidget {
  final TextEditingController controller;
  final Category? selected;
  final ValueChanged<Category?> onChanged;

  const CategoryDropdown({
    super.key,
    required this.controller,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final options = getCategoryOptions(context);

    return DropdownMenu<CategoryOption>(
      controller: controller,
      expandedInsets: EdgeInsets.zero,
      hintText: AppLocalizations.of(context).selectCategory,
      textStyle: TextStyle(fontSize: responsive.bodyFontSize),
      initialSelection: options.firstWhereOrNull((option) => option.category == selected),
      enableFilter: true,
      requestFocusOnTap: false,
      onSelected: (option) => onChanged(option?.category),
      dropdownMenuEntries: options.map((option) {
        return DropdownMenuEntry<CategoryOption>(
          value: option,
          label: option.label,
          leadingIcon: option.icon != null ? Icon(option.icon, size: responsive.iconSize()) : null,
          style: MenuItemButton.styleFrom(
            textStyle: TextStyle(fontSize: responsive.bodyFontSize),
          ),
        );
      }).toList(),
      menuHeight: responsive.isTablet ? 300 : 250,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: responsive.cardBorderRadius),
        contentPadding: responsive.contentPadding,
      ),
      trailingIcon: selected != null
          ? IconButton(
              icon: Icon(Icons.clear, size: responsive.iconSize()),
              onPressed: () {
                controller.clear();
                onChanged(null);
              },
            )
          : null,
    );
  }
}

/// "Number of entries" stepper for the categories that can be counted
/// several times at once.
class MultiplierInput extends StatelessWidget {
  final TextEditingController controller;
  final int value;
  final ValueChanged<int> onChanged;

  const MultiplierInput({
    super.key,
    required this.controller,
    required this.value,
    required this.onChanged,
  });

  /// The buttons also update the text; typing only reports the number, so
  /// the cursor stays where it is.
  void _step(int delta) {
    controller.text = (value + delta).toString();
    onChanged(value + delta);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final iconSize = responsive.iconSize();

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove, size: iconSize),
                onPressed: value > 1 ? () => _step(-1) : null,
              ),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (text) {
                    final newValue = int.tryParse(text);
                    if (newValue != null) onChanged(newValue);
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, size: iconSize),
                onPressed: () => _step(1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
