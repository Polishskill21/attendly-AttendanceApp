import 'package:attendly/data/local/config/database.dart';
import 'package:attendly/data/local/config/exceptions/db_exceptions.dart' as custom_db_exceptions;
import 'package:attendly/data/local/tables/enums/gender.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';
import 'package:attendly/provider/directory_repo_provider.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
// import 'package:attendly/backend/db_connection_validator.dart';
import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
import 'package:attendly/frontend/selection_options/gender_item.dart';
import 'package:attendly/frontend/selection_options/migration_item.dart';
import 'package:attendly/localization/app_localizations.dart';


class EditPage extends ConsumerStatefulWidget{
  final DirectoryPeopleData personToUpdate;
  final bool isTablet;

  const EditPage({
    super.key, 
    required this.personToUpdate, 
    this.isTablet = false,
  });

  @override
  ConsumerState<EditPage> createState() => _EditPageState();
}

class _EditPageState extends ConsumerState<EditPage>{  
  DateTime? _lastSelectedDate;
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _migrationController = TextEditingController();
  final TextEditingController _homeCountryController = TextEditingController();
  final HelperAllPerson _helper = HelperAllPerson();


  Gender? selectedGender;
  bool? selectedMigration;
  GenderItem? _initialGender;
  MigraionItem? _initialMigration;
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
      _helper.showErrorMessage(context, e.toString(), stackTrace: stackTrace);
    }
  }

  GenderItem? _genderToItem(Gender gender, BuildContext context) {
    final items = getGenderItems(context);
    switch (gender) {
      case Gender.m: return items[0];
      case Gender.f: return items[1];
      case Gender.d: return items[2];
    }
  }

  MigraionItem? _migrationToItem(bool migration, BuildContext context) {
    final items = getMigrationItems(context);
    return migration ? items[0] : items[1];
  }

  void _submitForm() async {
    final localizations = AppLocalizations.of(context);
    final p = widget.personToUpdate;
    final name = _nameController.text.trim();
    final homeCountry = _homeCountryController.text.trim();
    final currentBirthday = _lastSelectedDate!;


    if (name.isEmpty || selectedGender == null || selectedMigration == null) {
      _helper.showErrorMessage(context, localizations.allFieldsMustBeFilled);
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
        debugPrint("No changes detected, skipping update.");
        if (mounted) Navigator.of(context).pop(false);
        return;
      }

      await repo.updatePerson(p.id, companion);
      
      await _helper.showSubmitMessage(context, localizations.updatedSuccessfully);
      if (mounted) Navigator.of(context).pop(true);
    } on custom_db_exceptions.DuplicatePersonException catch (e) {
      _helper.showErrorMessage(
          context, localizations.personNamedAlreadyExists(e.name));

    } on custom_db_exceptions.PersonNotFoundException catch (e) {
      _helper.showErrorMessage(
          context, localizations.personWithIdNotFound(e.id));

    } on custom_db_exceptions.DatabaseNotReadyException {
      return;
    // } on custom_db_exceptions.DbConnectionException {
    //   if (mounted) await DbConnectionValidator.handleConnectionError(context);

    } on custom_db_exceptions.DatabaseOperationException catch (e, st) {
      _helper.showErrorMessage(context, e.toString(), stackTrace: st);

    } catch (e, st) {
      _helper.showErrorMessage(context, e.toString(), stackTrace: st);
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
        if (!widget.isTablet || child == null) return child ?? const SizedBox.shrink();
        
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
    final iconSize = ResponsiveUtils.getIconSize(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.addPersonToTable,
          style: TextStyle(
            fontSize: ResponsiveUtils.getTitleFontSize(context),
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
          bottom: ResponsiveUtils.getContentPadding(context).bottom + MediaQuery.of(context).padding.bottom,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getContentPadding(context).left + 12,
            vertical: ResponsiveUtils.getContentPadding(context).top + 6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(localizations.childsName,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveUtils.getBodyFontSize(context))
              ),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _nameController,
                  style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                  decoration: InputDecoration(
                    hintText: localizations.enterChildsName,
                    hintStyle: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                    contentPadding: ResponsiveUtils.getContentPadding(context),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.cancel, size: ResponsiveUtils.getIconSize(context)),
                      onPressed: () => _nameController.clear(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                    ),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveUtils.getContentPadding(context).vertical),

              Text(localizations.childsBirthday,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveUtils.getBodyFontSize(context))
              ),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _birthdayController,
                  readOnly: true,
                  onTap: () => _selectBirthday(context),
                  style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                  decoration: InputDecoration(
                    hintText: localizations.selectBirthday,
                    hintStyle: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                    contentPadding: ResponsiveUtils.getContentPadding(context),
                    suffixIcon: Icon(Icons.calendar_today, size: ResponsiveUtils.getIconSize(context)),
                    border: OutlineInputBorder(
                      borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                    ),
                  ),
                ),
              ),

              SizedBox(height: ResponsiveUtils.getContentPadding(context).vertical),

              Text(localizations.selectGender,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveUtils.getBodyFontSize(context))
              ),
              DropdownMenu<GenderItem>(
                controller: _genderController,
                expandedInsets: EdgeInsets.zero,
                hintText: localizations.selectChildGender,
                textStyle: TextStyle(
                    fontSize: ResponsiveUtils.getBodyFontSize(context)),
                initialSelection: _initialGender,
                dropdownMenuEntries: getGenderItems(context)
                    .map<DropdownMenuEntry<GenderItem>>((menu) =>
                        DropdownMenuEntry<GenderItem>(
                          value: menu,
                          label: menu.label,
                          leadingIcon: Icon(menu.icon, size: iconSize),
                          style: MenuItemButton.styleFrom(
                              textStyle: TextStyle(
                                  fontSize: ResponsiveUtils.getBodyFontSize(
                                      context))),
                        ))
                    .toList(),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                      borderRadius:
                          ResponsiveUtils.getCardBorderRadius(context)),
                  contentPadding: ResponsiveUtils.getContentPadding(context),
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

              SizedBox(height: ResponsiveUtils.getContentPadding(context).vertical),

              Text(localizations.selectMigration,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveUtils.getBodyFontSize(context))
              ),
              DropdownMenu<MigraionItem>(
                controller: _migrationController,
                expandedInsets: EdgeInsets.zero,
                hintText: localizations.selectChildsMigrationBackground,
                textStyle: TextStyle(
                    fontSize: ResponsiveUtils.getBodyFontSize(context)),
                initialSelection: _initialMigration,
                dropdownMenuEntries: getMigrationItems(context)
                    .map<DropdownMenuEntry<MigraionItem>>((menu) =>
                        DropdownMenuEntry<MigraionItem>(
                          value: menu,
                          label: menu.label,
                          leadingIcon: Icon(menu.icon, size: iconSize),
                          style: MenuItemButton.styleFrom(
                              textStyle: TextStyle(
                                  fontSize: ResponsiveUtils.getBodyFontSize(
                                      context))),
                        ))
                    .toList(),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                      borderRadius:
                          ResponsiveUtils.getCardBorderRadius(context)),
                  contentPadding: ResponsiveUtils.getContentPadding(context),
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

              SizedBox(height: ResponsiveUtils.getContentPadding(context).vertical),

              Text(localizations.homeCountry,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveUtils.getBodyFontSize(context))
              ),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _homeCountryController,
                  style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                  decoration: InputDecoration(
                    hintText: localizations.enterChildsHomeCountry,
                    hintStyle: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                    contentPadding: ResponsiveUtils.getContentPadding(context),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.cancel, size: ResponsiveUtils.getIconSize(context)),
                      onPressed: () => _homeCountryController.clear(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: ResponsiveUtils.getContentPadding(context).vertical * 3),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: Icon(Icons.check, size: ResponsiveUtils.getIconSize(context, baseSize: 28), color: Colors.white),
                    label: Text(
                      localizations.update,
                      style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getContentPadding(context).vertical / 2),
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