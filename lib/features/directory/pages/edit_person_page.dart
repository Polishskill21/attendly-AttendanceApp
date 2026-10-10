import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/database/exceptions.dart' as custom_db_exceptions;
import 'package:attendly/data/tables/enums/gender.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/features/directory/providers/directory_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:attendly/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
// import 'package:attendly/backend/db_connection_validator.dart';
import 'package:attendly/shared/dialogs/app_dialogs.dart';
import 'package:attendly/shared/options/gender_option.dart';
import 'package:attendly/shared/options/migration_option.dart';
import 'package:attendly/l10n/app_localizations.dart';


class EditPersonPage extends ConsumerStatefulWidget{
  final DirectoryPeopleData personToUpdate;

  const EditPersonPage({
    super.key, 
    required this.personToUpdate, 
  });

  @override
  ConsumerState<EditPersonPage> createState() => _EditPersonPageState();
}

class _EditPersonPageState extends ConsumerState<EditPersonPage>{  
  DateTime? _lastSelectedDate;
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _migrationController = TextEditingController();
  final TextEditingController _homeCountryController = TextEditingController();


  Gender? selectedGender;
  bool? selectedMigration;
  GenderOption? _initialGender;
  MigrationOption? _initialMigration;
  bool _hasInitializedSelections = false;


  @override 
  void initState() {
    super.initState();
    _populateControllers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize dropdown selections only once when context is available
    if (!_hasInitializedSelections) {
      if (selectedGender != null) {
        _initialGender = _genderToItem(selectedGender!, context);
        _genderController.text = _initialGender?.label ?? '';
      }
      if (selectedMigration != null) {
        _initialMigration = _migrationToItem(selectedMigration!, context);
        _migrationController.text = _initialMigration?.label ?? '';
      }
      _hasInitializedSelections = true;
    }
  }

  @override
  void dispose() {
    _genderController.dispose();
    _birthdayController.dispose();
    _homeCountryController.dispose();
    _migrationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _populateControllers() {
    final p = widget.personToUpdate;

    try{
      _nameController.text = p.name;
      _homeCountryController.text = p.migrationBackground ?? '';

      _birthdayController.text = DateFormat('dd.MM.yyyy').format(p.birthday);
      _lastSelectedDate = p.birthday;

      selectedGender = p.gender;

      selectedMigration = p.migration;
    }
    catch(e, stackTrace){
      AppDialogs.showError(context, e.toString(), stackTrace: stackTrace);
    }
  }

  GenderOption? _genderToItem(Gender gender, BuildContext context) {
    final items = getGenderOptions(context);
    switch (gender) {
      case Gender.m: return items[0];
      case Gender.f: return items[1];
      case Gender.d: return items[2];
    }
  }

  MigrationOption? _migrationToItem(bool migration, BuildContext context) {
    final items = getMigrationOptions(context);
    return migration ? items[0] : items[1];
  }

  void _submitForm() async {
    final localizations = AppLocalizations.of(context);
    final p = widget.personToUpdate;
    final name = _nameController.text.trim();
    final homeCountry = _homeCountryController.text.trim();
    final currentBirthday = _lastSelectedDate!;


    if (name.isEmpty || selectedGender == null || selectedMigration == null) {
      AppDialogs.showError(context, localizations.allFieldsMustBeFilled);
      return;
    }

    final repo = ref.read(directoryRepositoryProvider);

    try {
      DirectoryPeopleCompanion companion = const DirectoryPeopleCompanion();

      // Compare directly against typed fields — no Map lookups
      if (name != p.name) {
        companion = companion.copyWith(name: Value(name));
      }
      if (currentBirthday.year != p.birthday.year ||
          currentBirthday.month != p.birthday.month ||
          currentBirthday.day != p.birthday.day) {
        companion = companion.copyWith(birthday: Value(currentBirthday));
      }
      if (selectedGender != p.gender) {
        companion = companion.copyWith(gender: Value(selectedGender!));
      }
      if (selectedMigration != p.migration) {
        companion = companion.copyWith(migration: Value(selectedMigration!));
      }
      if (homeCountry != (p.migrationBackground ?? '')) {
        companion = companion.copyWith(migrationBackground: Value(homeCountry));
      }

      final hasChanges = companion.name.present ||
          companion.birthday.present ||
          companion.gender.present ||
          companion.migration.present ||
          companion.migrationBackground.present;

      if (!hasChanges) {
        AppLogger.d("Directory", "No changes detected, skipping update.");
        if (mounted) Navigator.of(context).pop(false);
        return;
      }

      await repo.updatePerson(p.id, companion);
      
      await AppDialogs.showSuccess(context, localizations.updatedSuccessfully);
      if (mounted) Navigator.of(context).pop(true);
    } on custom_db_exceptions.DuplicatePersonException catch (e) {
      AppDialogs.showError(
          context, localizations.personNamedAlreadyExists(e.name));

    } on custom_db_exceptions.PersonNotFoundException catch (e) {
      AppDialogs.showError(
          context, localizations.personWithIdNotFound(e.id));

    } on custom_db_exceptions.DatabaseNotReadyException {
      return;
    // } on custom_db_exceptions.DbConnectionException {
    //   if (mounted) await DbConnectionValidator.handleConnectionError(context);

    } on custom_db_exceptions.DatabaseOperationException catch (e, st) {
      AppDialogs.showError(context, e.toString(), stackTrace: st);

    } catch (e, st) {
      AppDialogs.showError(context, e.toString(), stackTrace: st);
    }
  }

  // bool _isValidDate(String date) {
  //   try {
  //     DateFormat("dd.MM.yyyy").parseStrict(date);
  //     return true;
  //   } catch (e) {
  //     return false;
  //   }
  // }

  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lastSelectedDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendar,
      initialDatePickerMode: DatePickerMode.year,
      keyboardType: TextInputType.numberWithOptions(),
      builder: (context, child) {
        if (!Responsive.of(context).isTablet || child == null) return child ?? const SizedBox.shrink();
        
        final mq = MediaQuery.of(context);
        final newScale = (mq.textScaler.scale(1.0) * 1.2).clamp(1.0, 1.6);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(newScale)),
          child: Transform.scale(scale: 1.1, child: child),
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _lastSelectedDate = picked;
        _birthdayController.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final iconSize = Responsive.of(context).iconSize();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.addPersonToTable,
          style: TextStyle(
            fontSize: Responsive.of(context).titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: iconSize),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: Responsive.of(context).contentPadding.bottom + MediaQuery.of(context).padding.bottom,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.of(context).contentPadding.left + 12,
            vertical: Responsive.of(context).contentPadding.top + 6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(localizations.childsName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: Responsive.of(context).bodyFontSize)
              ),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _nameController,
                  style: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                  decoration: InputDecoration(
                    hintText: localizations.enterChildsName,
                    hintStyle: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                    contentPadding: Responsive.of(context).contentPadding,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.cancel, size: Responsive.of(context).iconSize()),
                      onPressed: () => _nameController.clear(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: Responsive.of(context).cardBorderRadius,
                    ),
                  ),
                ),
              ),
              SizedBox(height: Responsive.of(context).contentPadding.vertical),

              Text(localizations.childsBirthday,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: Responsive.of(context).bodyFontSize)
              ),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _birthdayController,
                  readOnly: true,
                  onTap: () => _selectBirthday(context),
                  style: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                  decoration: InputDecoration(
                    hintText: localizations.selectBirthday,
                    hintStyle: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                    contentPadding: Responsive.of(context).contentPadding,
                    suffixIcon: Icon(Icons.calendar_today, size: Responsive.of(context).iconSize()),
                    border: OutlineInputBorder(
                      borderRadius: Responsive.of(context).cardBorderRadius,
                    ),
                  ),
                ),
              ),

              SizedBox(height: Responsive.of(context).contentPadding.vertical),

              Text(localizations.selectGender,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: Responsive.of(context).bodyFontSize)
              ),
              DropdownMenu<GenderOption>(
                controller: _genderController,
                expandedInsets: EdgeInsets.zero,
                hintText: localizations.selectChildGender,
                textStyle: TextStyle(
                    fontSize: Responsive.of(context).bodyFontSize),
                initialSelection: _initialGender,
                dropdownMenuEntries: getGenderOptions(context)
                    .map<DropdownMenuEntry<GenderOption>>((menu) =>
                        DropdownMenuEntry<GenderOption>(
                          value: menu,
                          label: menu.label,
                          leadingIcon: Icon(menu.icon, size: iconSize),
                          style: MenuItemButton.styleFrom(
                              textStyle: TextStyle(
                                  fontSize: Responsive.of(context).bodyFontSize)),
                        ))
                    .toList(),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                      borderRadius:
                          Responsive.of(context).cardBorderRadius),
                  contentPadding: Responsive.of(context).contentPadding,
                ),
                trailingIcon: selectedGender != null
                    ? IconButton(
                        icon: Icon(Icons.clear, size: iconSize),
                        onPressed: () => setState(() {
                          selectedGender = null;
                          _genderController.clear();
                          _initialGender = null;
                        }),
                      )
                    : null,
                onSelected: (item) =>
                    setState(() => selectedGender = item?.value),
              ),

              SizedBox(height: Responsive.of(context).contentPadding.vertical),

              Text(localizations.selectMigration,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: Responsive.of(context).bodyFontSize)
              ),
              DropdownMenu<MigrationOption>(
                controller: _migrationController,
                expandedInsets: EdgeInsets.zero,
                hintText: localizations.selectChildsMigrationBackground,
                textStyle: TextStyle(
                    fontSize: Responsive.of(context).bodyFontSize),
                initialSelection: _initialMigration,
                dropdownMenuEntries: getMigrationOptions(context)
                    .map<DropdownMenuEntry<MigrationOption>>((menu) =>
                        DropdownMenuEntry<MigrationOption>(
                          value: menu,
                          label: menu.label,
                          leadingIcon: Icon(menu.icon, size: iconSize),
                          style: MenuItemButton.styleFrom(
                              textStyle: TextStyle(
                                  fontSize: Responsive.of(context).bodyFontSize)),
                        ))
                    .toList(),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                      borderRadius:
                          Responsive.of(context).cardBorderRadius),
                  contentPadding: Responsive.of(context).contentPadding,
                ),
                trailingIcon: selectedMigration != null
                    ? IconButton(
                        icon: Icon(Icons.clear, size: iconSize),
                        onPressed: () => setState(() {
                          selectedMigration = null;
                          _migrationController.clear();
                          _initialMigration = null;
                        }),
                      )
                    : null,
                onSelected: (item) => setState(() {
                  selectedMigration = item?.value;
                  if (selectedMigration == false) _homeCountryController.clear();
                }),
              ),

              SizedBox(height: Responsive.of(context).contentPadding.vertical),

              Text(localizations.homeCountry,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: Responsive.of(context).bodyFontSize)
              ),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _homeCountryController,
                  style: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                  decoration: InputDecoration(
                    hintText: localizations.enterChildsHomeCountry,
                    hintStyle: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                    contentPadding: Responsive.of(context).contentPadding,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.cancel, size: Responsive.of(context).iconSize()),
                      onPressed: () => _homeCountryController.clear(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: Responsive.of(context).cardBorderRadius,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: Responsive.of(context).contentPadding.vertical * 3),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: Icon(Icons.check, size: Responsive.of(context).iconSize(baseSize: 28), color: Colors.white),
                    label: Text(
                      localizations.update,
                      style: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: Responsive.of(context).contentPadding.vertical / 2),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}