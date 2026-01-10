import 'package:attendly/backend/enums/genders.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:attendly/frontend/selection_options/gender_item.dart';
import 'package:attendly/frontend/selection_options/migration_item.dart';
import 'package:attendly/backend/helpers/child.dart';
import 'package:attendly/backend/dbLogic/db_read.dart';
import 'package:attendly/backend/dbLogic/db_insert.dart';
import 'package:attendly/backend/dbLogic/db_update.dart';
import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
import 'package:attendly/backend/db_exceptions.dart' as custom_db_exceptions;
import 'package:attendly/backend/db_connection_validator.dart';
import 'package:attendly/localization/app_localizations.dart';

class AddPage extends StatefulWidget{
  final Database database;
  final bool isTablet;

  const AddPage({
    super.key, 
    required this.database,
    this.isTablet = false,
  });

  @override
  State<StatefulWidget> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage>{  
  DateTime? _lastSelectedDate;

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
    String uiBirthday = _birthdayController.text.trim();
    String homeCountry = _homeCountryController.text.trim();

    // Validate empty fields
    if (name.isEmpty || uiBirthday.isEmpty || selectedGender == null || selectedMigration == null) {
      helper.showErrorMessage(context, localizations.allFieldsMustBeFilled);
      return false;
    }

    if (selectedMigration == true && homeCountry.isEmpty) {
      helper.showErrorMessage(context, localizations.homeCountryRequiredForMigration);
      return false;
    }

    // Validate date format (YYYY-MM-dd)
    if (!_isValidDate(uiBirthday)) {
      helper.showErrorMessage(context, localizations.invalidDateFormat);
      return false;
    }



    try {
      //create child object and pop page
      final child = Child(name: name, birthday: uiBirthday, gender: selectedGender!, migration: selectedMigration!, migrationBackground: homeCountry);

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
        if (!widget.isTablet || child == null) return child ?? const SizedBox.shrink();

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
    final isTablet = widget.isTablet || ResponsiveUtils.isTablet(context);
    final iconSize = ResponsiveUtils.getIconSize(context);
    
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
      child: Scaffold(
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
          bottom: (isTablet ? 30 : 20) + MediaQuery.of(context).padding.bottom,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            ResponsiveUtils.getContentPadding(context).left + 12,
            ResponsiveUtils.getContentPadding(context).top + 8,
            ResponsiveUtils.getContentPadding(context).right + 12,
            0,
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
                    suffixIcon: Icon(
                    Icons.calendar_today, 
                    size: ResponsiveUtils.getIconSize(context),
                    ),
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
                textStyle: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                enableFilter: true,
                requestFocusOnTap: false,
                onSelected: (GenderItem? item) {
                  setState(() {
                    selectedGender = item?.value;
                  });
                },
                dropdownMenuEntries: getGenderItems(context).map<DropdownMenuEntry<GenderItem>>((GenderItem menu) {
                  return DropdownMenuEntry<GenderItem>(
                    value: menu,
                    label: menu.label,
                    leadingIcon: Icon(menu.icon, size: isTablet ? 24 : 20),
                    style: MenuItemButton.styleFrom(
                      textStyle: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                    ),
                  );
                }).toList(),
                menuHeight: isTablet ? 300 : 250,
                width: MediaQuery.of(context).size.width - (isTablet ? 60 : 40),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(borderRadius: ResponsiveUtils.getCardBorderRadius(context)),
                  contentPadding: ResponsiveUtils.getContentPadding(context),
                ),
                trailingIcon: selectedGender != null
                    ? IconButton(
                        icon: Icon(Icons.clear, size: iconSize),
                        onPressed: () {
                          setState(() {
                            selectedGender = null;
                            _genderController.clear();
                          });
                        },
                      )
                    : null,
              ),

              SizedBox(height: ResponsiveUtils.getContentPadding(context).vertical),

              Text(localizations.selectMigration, 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: ResponsiveUtils.getBodyFontSize(context))
              ),
              DropdownMenu<MigraionItem>(
                controller: _migrationController,
                expandedInsets: EdgeInsets.zero,
                hintText: localizations.selectChildsMigrationBackground,
                textStyle: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                enableFilter: true,
                requestFocusOnTap: false,
                onSelected: (MigraionItem? item) {
                  setState(() {
                    selectedMigration = item?.value;
                  });
                },
                dropdownMenuEntries: getMigrationItems(context).map<DropdownMenuEntry<MigraionItem>>((MigraionItem menu) {
                  return DropdownMenuEntry<MigraionItem>(
                    value: menu,
                    label: menu.label,
                    leadingIcon: Icon(menu.icon, size: isTablet ? 24 : 20),
                    style: MenuItemButton.styleFrom(
                      textStyle: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                    ),
                  );
                }).toList(),
                menuHeight: isTablet ? 200 : 150,
                width: MediaQuery.of(context).size.width - (isTablet ? 60 : 40),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(borderRadius: ResponsiveUtils.getCardBorderRadius(context)),
                  contentPadding: ResponsiveUtils.getContentPadding(context),
                ),
                trailingIcon: selectedMigration != null
                    ? IconButton(
                        icon: Icon(Icons.clear, size: iconSize),
                        onPressed: () {
                          setState(() {
                            selectedMigration = null;
                            _migrationController.clear();
                          });
                        },
                      )
                    : null,
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
              SizedBox(height: isTablet ? 70 : 60),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _resetFields,
                    icon: Icon(Icons.refresh, size: ResponsiveUtils.getIconSize(context, baseSize: 26)),
                    label: Text(localizations.reset, style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context))),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getContentPadding(context).vertical / 2),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.isTablet(context) ? 20 : 16),
                  ElevatedButton.icon(
                    onPressed: () => _submitForm(),
                    icon: Icon(Icons.check, size: ResponsiveUtils.getIconSize(context, baseSize: 28), color: Colors.white),
                    label: Text(localizations.submit, style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context))),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: ResponsiveUtils.getContentPadding(context).vertical / 2),
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