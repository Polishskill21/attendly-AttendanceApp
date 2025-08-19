import 'package:attendly/backend/enums/genders.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:attendly/backend/helpers/child.dart';
import 'package:attendly/backend/dbLogic/db_read.dart';
import 'package:attendly/backend/dbLogic/db_insert.dart';
import 'package:attendly/backend/dbLogic/db_update.dart';
import 'package:attendly/backend/db_exceptions.dart' as custom_db_exceptions;
import 'package:attendly/backend/db_connection_validator.dart';
import 'package:attendly/frontend/selection_options/gender_item.dart';
import 'package:attendly/frontend/selection_options/migration_item.dart';
import 'package:attendly/frontend/l10n/app_localizations.dart';
import 'message_helper.dart';

class AddPage extends StatefulWidget{
  final Database database;
  const AddPage({super.key, required this.database});

  @override
  State<StatefulWidget> createState() => _AddPageState();

}

class _AddPageState extends State<AddPage>{  
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _migrationController = TextEditingController();
  final TextEditingController _homeCountryController = TextEditingController();
  Genders? selectedGender;
  bool? selectedMigration;
  late DbInsertion inserter;
  late DbSelection reader;
  late DbUpdater updater;
  late HelperAllPerson helper;

  List<dynamic> allData = [];

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

    helper.showResetMessage(context, AppLocalizations.of(context).allFieldsReset);
  }

  @override 
  void initState(){
    super.initState();
    reader = DbSelection(widget.database);
    updater = DbUpdater(widget.database, reader);
    inserter = DbInsertion(widget.database, reader, updater);
    helper = HelperAllPerson();
  }

  Future<bool> _submitForm() async{
    final localizations = AppLocalizations.of(context);
    String name = _nameController.text.trim();
    String birthday = _birthdayController.text.trim();
    String homeCountry = _homeCountryController.text.trim();

    // Validate empty fields
    if (name.isEmpty || birthday.isEmpty || selectedGender == null || selectedMigration == null) {
      helper.showErrorMessage(context, localizations.allFieldsMustBeFilled);
      return false;
    }

    if (selectedMigration == true && homeCountry.isEmpty) {
      helper.showErrorMessage(context, localizations.homeCountryRequiredForMigration);
      return false;
    }

    // Validate date format (YYYY-MM-dd)
    if (!_isValidDate(birthday)) {
      helper.showErrorMessage(context, localizations.invalidDateFormat);
      return false;
    }

    try {
      //create child object and pop page
      final child = Child(name: name, birthday: birthday, gender: selectedGender!, migration: selectedMigration!, migrationBackground: homeCountry);

      //database insertion
      await inserter.allPeopleTable(child);

      await helper.showSubmitMessage(context, localizations.formSubmittedSuccessfully);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return true;
    } on custom_db_exceptions.DbConnectionException catch (e) {
      debugPrint('Database connection error: $e');
      if (mounted) {
        await DbConnectionValidator.handleConnectionError(context);
      }
      return false;
    } on custom_db_exceptions.DuplicatePersonException catch (e) {
      helper.showErrorMessage(context, localizations.personNamedAlreadyExists(e.name));
      return false;
    } catch (e, stackTrace) {
      debugPrint('Unexpected error during form submission: $e');
      helper.showErrorMessage(context, e.toString(), stackTrace: stackTrace);
      return false;
    }
  }

  bool _isValidDate(String date) {
    try {
      DateFormat("yyyy-MM-dd").parseStrict(date);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendar,
      initialDatePickerMode: DatePickerMode.year,
      keyboardType: TextInputType.numberWithOptions()
    );
    if (picked != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        _birthdayController.text = formattedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(localizations.addPersonToTable),
         leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: 20 + MediaQuery.of(context).padding.bottom,
        ),
        child: Padding(
          // was EdgeInsets.symmetric(...)
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Input Field
              Text(localizations.childsName, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: localizations.enterChildsName,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.cancel),
                      onPressed: () => _nameController.clear(),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              
              SizedBox(height: 20),

              // Birthday Input Field
              Text(localizations.childsBirthday, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _birthdayController,
                  readOnly: true,
                  onTap: () => _selectBirthday(context),
                  decoration: InputDecoration(
                    hintText: localizations.selectBirthday,
                    suffixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Gender Dropdown
              Text(localizations.selectGender, style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownMenu<GenderItem>(
                controller: _genderController,
                expandedInsets: EdgeInsets.zero,
                hintText: localizations.selectChildGender,
                enableFilter: true,
                requestFocusOnTap: false,
                onSelected: (GenderItem? item) {
                  setState(() {
                    selectedGender = item?.value;
                  });
                },
                dropdownMenuEntries: getGenderItems(context).map<DropdownMenuEntry<GenderItem>>((GenderItem menu) {
                  return DropdownMenuEntry<GenderItem>(value: menu, label: menu.label, leadingIcon: Icon(menu.icon));
                }).toList(),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                ),
                trailingIcon: selectedGender != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            selectedGender = null;
                            _genderController.clear();
                          });
                        },
                      )
                    : null,
              ),

              SizedBox(height: 20),

              // Migration Dropdown
              Text(localizations.selectMigration, style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownMenu<MigraionItem>(
                controller: _migrationController,
                expandedInsets: EdgeInsets.zero,
                hintText: localizations.selectChildsMigrationBackground,
                enableFilter: true,
                requestFocusOnTap: false,
                onSelected: (MigraionItem? item) {
                  setState(() {
                    selectedMigration = item?.value;
                  });
                },
                dropdownMenuEntries: getMigrationItems(context).map<DropdownMenuEntry<MigraionItem>>((MigraionItem menu) {
                  return DropdownMenuEntry<MigraionItem>(value: menu, label: menu.label, leadingIcon: Icon(menu.icon));
                }).toList(),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                ),
                trailingIcon: selectedMigration != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            selectedMigration = null;
                            _migrationController.clear();
                          });
                        },
                      )
                    : null,
              ),

              SizedBox(height: 20),

              // Home Country Input Field
              Text(localizations.homeCountry, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _homeCountryController,
                  decoration: InputDecoration(
                    hintText: localizations.enterChildsHomeCountry,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.cancel),
                      onPressed: () => _homeCountryController.clear(),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(height: 60),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon( 
                    onPressed: _resetFields, 
                    icon: Icon(Icons.refresh, size: 25),
                    label: Text(localizations.reset, style: TextStyle(fontSize: 20)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _submitForm(), 
                    icon: Icon(Icons.check, size: 25, color: Colors.white),
                    label: Text(localizations.submit, style: TextStyle(fontSize: 20)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  )
                ],
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom), // final safe gap
            ],
          ),
        ),
      ),
      )
    );
  }
}