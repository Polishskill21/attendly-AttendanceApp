import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/data/tables/enums/gender.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:attendly/shared/options/gender_option.dart';
import 'package:attendly/shared/options/migration_option.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// Name, birthday, gender, migration and home country fields of the person
/// form. The page owns the controllers and the selected values.
class PersonFormFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController birthdayController;
  final TextEditingController genderController;
  final TextEditingController migrationController;
  final TextEditingController homeCountryController;
  final Gender? gender;
  final bool? migration;
  final ValueChanged<Gender?> onGenderChanged;
  final ValueChanged<bool?> onMigrationChanged;
  final VoidCallback onPickBirthday;

  const PersonFormFields({
    super.key,
    required this.nameController,
    required this.birthdayController,
    required this.genderController,
    required this.migrationController,
    required this.homeCountryController,
    required this.gender,
    required this.migration,
    required this.onGenderChanged,
    required this.onMigrationChanged,
    required this.onPickBirthday,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final responsive = Responsive.of(context);
    final isTablet = responsive.isTablet;
    final iconSize = responsive.iconSize();
    final bodySize = responsive.bodyFontSize;
    final gap = SizedBox(height: responsive.contentPadding.vertical);

    final labelStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: bodySize);
    final border = OutlineInputBorder(borderRadius: responsive.cardBorderRadius);
    final menuTextStyle = MenuItemButton.styleFrom(textStyle: TextStyle(fontSize: bodySize));
    final genderOptions = getGenderOptions(context);
    final migrationOptions = getMigrationOptions(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.childsName, style: labelStyle),
        SizedBox(
          width: double.infinity,
          child: TextField(
            controller: nameController,
            style: TextStyle(fontSize: bodySize),
            decoration: InputDecoration(
              hintText: localizations.enterChildsName,
              hintStyle: TextStyle(fontSize: bodySize),
              contentPadding: responsive.contentPadding,
              suffixIcon: IconButton(
                icon: Icon(Icons.cancel, size: iconSize),
                onPressed: () => nameController.clear(),
              ),
              border: border,
            ),
          ),
        ),
        gap,

        Text(localizations.childsBirthday, style: labelStyle),
        SizedBox(
          width: double.infinity,
          child: TextField(
            controller: birthdayController,
            readOnly: true,
            onTap: onPickBirthday,
            style: TextStyle(fontSize: bodySize),
            decoration: InputDecoration(
              hintText: localizations.selectBirthday,
              hintStyle: TextStyle(fontSize: bodySize),
              contentPadding: responsive.contentPadding,
              suffixIcon: Icon(Icons.calendar_today, size: iconSize),
              border: border,
            ),
          ),
        ),
        gap,

        Text(localizations.selectGender, style: labelStyle),
        DropdownMenu<GenderOption>(
          controller: genderController,
          expandedInsets: EdgeInsets.zero,
          hintText: localizations.selectChildGender,
          textStyle: TextStyle(fontSize: bodySize),
          initialSelection: genderOptions.firstWhereOrNull((o) => o.value == gender),
          enableFilter: true,
          requestFocusOnTap: false,
          onSelected: (option) => onGenderChanged(option?.value),
          dropdownMenuEntries: genderOptions
              .map((option) => DropdownMenuEntry<GenderOption>(
                    value: option,
                    label: option.label,
                    leadingIcon: Icon(option.icon, size: isTablet ? 24 : 20),
                    style: menuTextStyle,
                  ))
              .toList(),
          menuHeight: isTablet ? 300 : 250,
          inputDecorationTheme: InputDecorationTheme(
            border: border,
            contentPadding: responsive.contentPadding,
          ),
          trailingIcon: gender != null
              ? IconButton(
                  icon: Icon(Icons.clear, size: iconSize),
                  onPressed: () {
                    genderController.clear();
                    onGenderChanged(null);
                  },
                )
              : null,
        ),
        gap,

        Text(localizations.selectMigration, style: labelStyle),
        DropdownMenu<MigrationOption>(
          controller: migrationController,
          expandedInsets: EdgeInsets.zero,
          hintText: localizations.selectChildsMigrationBackground,
          textStyle: TextStyle(fontSize: bodySize),
          initialSelection: migrationOptions.firstWhereOrNull((o) => o.value == migration),
          enableFilter: true,
          requestFocusOnTap: false,
          onSelected: (option) {
            if (option?.value == false) homeCountryController.clear();
            onMigrationChanged(option?.value);
          },
          dropdownMenuEntries: migrationOptions
              .map((option) => DropdownMenuEntry<MigrationOption>(
                    value: option,
                    label: option.label,
                    leadingIcon: Icon(option.icon, size: isTablet ? 24 : 20),
                    style: menuTextStyle,
                  ))
              .toList(),
          menuHeight: isTablet ? 200 : 150,
          inputDecorationTheme: InputDecorationTheme(
            border: border,
            contentPadding: responsive.contentPadding,
          ),
          trailingIcon: migration != null
              ? IconButton(
                  icon: Icon(Icons.clear, size: iconSize),
                  onPressed: () {
                    migrationController.clear();
                    onMigrationChanged(null);
                  },
                )
              : null,
        ),
        gap,

        Text(localizations.homeCountry, style: labelStyle),
        SizedBox(
          width: double.infinity,
          child: TextField(
            controller: homeCountryController,
            style: TextStyle(fontSize: bodySize),
            decoration: InputDecoration(
              hintText: localizations.enterChildsHomeCountry,
              hintStyle: TextStyle(fontSize: bodySize),
              contentPadding: responsive.contentPadding,
              suffixIcon: IconButton(
                icon: Icon(Icons.cancel, size: iconSize),
                onPressed: () => homeCountryController.clear(),
              ),
              border: border,
            ),
          ),
        ),
      ],
    );
  }
}
