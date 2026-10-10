import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/database/exceptions.dart' as custom_db_exceptions;
import 'package:attendly/data/tables/enums/gender.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/features/directory/providers/directory_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:attendly/shared/options/gender_option.dart';
import 'package:attendly/shared/options/migration_option.dart';
import 'package:attendly/shared/dialogs/app_dialogs.dart';
// import 'package:attendly/backend/db_connection_validator.dart';
import 'package:attendly/l10n/app_localizations.dart';

class AddPersonPage extends ConsumerStatefulWidget{

  const AddPersonPage({
    super.key, 
  });

  @override
  ConsumerState<AddPersonPage> createState() => _AddPersonPageState();
}

class _AddPersonPageState extends ConsumerState<AddPersonPage>{  
  DateTime? _lastSelectedDate;
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _migrationController = TextEditingController();
  final TextEditingController _homeCountryController = TextEditingController();
  Gender? selectedGender;
  bool? selectedMigration;

  @override 
  void initState(){
    super.initState();
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

  void _resetFields(){
    setState(() {
      _nameController.clear();
      _birthdayController.clear();
      _homeCountryController.clear();
      _genderController.clear();
      _migrationController.clear();
      selectedGender = null;
      selectedMigration = null;
    });

    AppDialogs.showSnack(context, AppLocalizations.of(context).allFieldsReset);
  }

  Future<void> _submitForm() async{
    final localizations = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    final uiBirthday = _birthdayController.text.trim();
    final homeCountry = _homeCountryController.text.trim();

    // Validate empty fields
    if (name.isEmpty || uiBirthday.isEmpty || selectedGender == null || selectedMigration == null) {
      AppDialogs.showError(context, localizations.allFieldsMustBeFilled);
      return;
    }

    if (selectedMigration == true && homeCountry.isEmpty) {
      AppDialogs.showError(context, localizations.homeCountryRequiredForMigration);
      return;
    }

    // Validate date format (dd.MM.YYYY)
    if (!_isValidDate(uiBirthday)) {
      AppDialogs.showError(context, localizations.invalidDateFormat);
      return;
    }

    final repo = ref.read(directoryRepositoryProvider);

    try {
      DateTime parsedBirthday = DateFormat("dd.MM.yyyy").parse(uiBirthday);
      //create child object and pop page
      // final child = Child(name: name, birthday: uiBirthday, gender: selectedGender!, migration: selectedMigration!, migrationBackground: homeCountry);
      await repo.addPerson(
        DirectoryPeopleCompanion.insert(
          name: name,
          birthday: parsedBirthday,
          gender: selectedGender!,
          migration: selectedMigration!,
          migrationBackground: Value(homeCountry),
        ),
      );

      await AppDialogs.showSuccess(context, localizations.formSubmittedSuccessfully);
      if (mounted) Navigator.of(context).pop(); 
      return;
    } on custom_db_exceptions.DuplicatePersonException catch (e) {
      AppDialogs.showError(context, localizations.personNamedAlreadyExists(e.name));
      return;
    } on custom_db_exceptions.DatabaseNotReadyException {
      return; // Safely abort if DB is transitioning
    // } on custom_db_exceptions.DbConnectionException catch (e) {
    //   debugPrint('Database connection error: $e');
    //   if (mounted) {
    //     await DbConnectionValidator.handleConnectionError(context);
    //   }
    //   return false;
    }
    catch (e, stackTrace) {
      AppDialogs.showError(context, e.toString(), stackTrace: stackTrace);
      return;
    }
  }

  bool _isValidDate(String date) {
    try {
      DateFormat("dd.MM.yyyy").parseStrict(date);
      return true;
    } catch (e) {
      return false;
    }
  }

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
       final currentScale = mq.textScaler.scale(1.0);
       final newScale = (currentScale * 1.2).clamp(1.0, 1.6);
       
       return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(newScale),
          ),
          child: Transform.scale(
            scale: 1.1,
            child: child,
          ),
        );
      },
    );
    
    if (picked != null) {
      String formattedDate = DateFormat('dd.MM.yyyy').format(picked);
      setState(() {
        _lastSelectedDate = picked;
        _birthdayController.text = formattedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isTablet = Responsive.of(context).isTablet;
    final iconSize = Responsive.of(context).iconSize();
    
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
      child: Scaffold(
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
          bottom: (isTablet ? 30 : 20) + MediaQuery.of(context).padding.bottom,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Responsive.of(context).contentPadding.left + 12,
            Responsive.of(context).contentPadding.top + 8,
            Responsive.of(context).contentPadding.right + 12,
            0,
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
                    suffixIcon: Icon(
                    Icons.calendar_today, 
                    size: Responsive.of(context).iconSize(),
                    ),
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
                  enableFilter: true,
                  requestFocusOnTap: false,
                  onSelected: (item) =>
                      setState(() => selectedGender = item?.value),
                  dropdownMenuEntries: getGenderOptions(context)
                      .map<DropdownMenuEntry<GenderOption>>((menu) =>
                          DropdownMenuEntry<GenderOption>(
                            value: menu,
                            label: menu.label,
                            leadingIcon:
                                Icon(menu.icon, size: isTablet ? 24 : 20),
                            style: MenuItemButton.styleFrom(
                                textStyle: TextStyle(
                                    fontSize: Responsive.of(context).bodyFontSize)),
                          ))
                      .toList(),
                  menuHeight: isTablet ? 300 : 250,
                  // width: MediaQuery.of(context).size.width -
                  //     (isTablet ? 60 : 40),
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(
                        borderRadius:
                            Responsive.of(context).cardBorderRadius),
                    contentPadding:
                        Responsive.of(context).contentPadding,
                  ),
                  trailingIcon: selectedGender != null
                      ? IconButton(
                          icon: Icon(Icons.clear, size: iconSize),
                          onPressed: () => setState(() {
                            selectedGender = null;
                            _genderController.clear();
                          }),
                        )
                      : null,
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
                  enableFilter: true,
                  requestFocusOnTap: false,
                  onSelected: (item) => setState(() {
                    selectedMigration = item?.value;
                    if (selectedMigration == false) _homeCountryController.clear();
                  }),
                  dropdownMenuEntries: getMigrationOptions(context)
                      .map<DropdownMenuEntry<MigrationOption>>((menu) =>
                          DropdownMenuEntry<MigrationOption>(
                            value: menu,
                            label: menu.label,
                            leadingIcon:
                                Icon(menu.icon, size: isTablet ? 24 : 20),
                            style: MenuItemButton.styleFrom(
                                textStyle: TextStyle(
                                    fontSize: Responsive.of(context).bodyFontSize)),
                          ))
                      .toList(),
                  menuHeight: isTablet ? 200 : 150,
                  // width: MediaQuery.of(context).size.width -
                  //     (isTablet ? 60 : 40),
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(
                        borderRadius:
                            Responsive.of(context).cardBorderRadius),
                    contentPadding:
                        Responsive.of(context).contentPadding,
                  ),
                  trailingIcon: selectedMigration != null
                      ? IconButton(
                          icon: Icon(Icons.clear, size: iconSize),
                          onPressed: () => setState(() {
                            selectedMigration = null;
                            _migrationController.clear();
                          }),
                        )
                      : null,
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
              SizedBox(height: isTablet ? 70 : 60),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _resetFields,
                    icon: Icon(Icons.refresh, size: Responsive.of(context).iconSize(baseSize: 26)),
                    label: Text(localizations.reset, style: TextStyle(fontSize: Responsive.of(context).bodyFontSize)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      padding: EdgeInsets.symmetric(vertical: Responsive.of(context).contentPadding.vertical / 2),
                    ),
                  ),
                  SizedBox(height: Responsive.of(context).isTablet ? 20 : 16),
                  ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: Icon(Icons.check, size: Responsive.of(context).iconSize(baseSize: 28), color: Colors.white),
                    label: Text(localizations.submit, style: TextStyle(fontSize: Responsive.of(context).bodyFontSize)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: Responsive.of(context).contentPadding.vertical / 2),
                    ),
                  )
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom)
            ],
          ),
        ),
      ),
      )
    );
  }
}