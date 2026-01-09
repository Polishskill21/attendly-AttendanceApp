import 'package:attendly/backend/enums/genders.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:attendly/backend/helpers/child.dart';
import 'package:attendly/backend/db_exceptions.dart' as custom_db_exceptions;
import 'package:attendly/backend/db_connection_validator.dart';
import 'package:attendly/backend/dbLogic/db_read.dart';
import 'package:attendly/backend/dbLogic/db_update.dart';
import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
import 'package:attendly/frontend/selection_options/gender_item.dart';
import 'package:attendly/frontend/selection_options/migration_item.dart';
import 'package:attendly/frontend/person_model/person_logic_conversion.dart';
import 'package:attendly/localization/app_localizations.dart';


class EditPage extends StatefulWidget{
  final Map<String,dynamic> childToUpdate;
  final Database database;
  final bool isTablet;

  const EditPage({
    super.key, 
    required this.childToUpdate, 
    required this.database,
    this.isTablet = false,
  });

  @override
  State<StatefulWidget> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage>{  
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _migrationController = TextEditingController();
  final TextEditingController _homeCountryController = TextEditingController();
  Genders? selectedGender;
  bool? selectedMigration;
  late DbSelection reader;
  late DbUpdater updater;
  late HelperAllPerson helper;

  GenderItem? initalSelectionGenderValueDropDown;
  MigraionItem? initalSelectionMigrationValueDropDown;

  bool _hasInitializedSelections = false;


  List<dynamic> allData = [];

   @override void initState() {
    super.initState();
    reader = DbSelection(widget.database);
    updater = DbUpdater(widget.database, reader);
    helper = HelperAllPerson();
    _populateControllers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize dropdown selections only once when context is available
    if (!_hasInitializedSelections) {
      if (selectedGender != null) {
        initalSelectionGenderValueDropDown = genderMapToDropDownItem(selectedGender!, context);
        _genderController.text = initalSelectionGenderValueDropDown?.label ?? '';
      }
      if (selectedMigration != null) {
        initalSelectionMigrationValueDropDown = migrationMapToDropDownItem(selectedMigration!, context);
        _migrationController.text = initalSelectionMigrationValueDropDown?.label ?? '';
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
    try{
    _nameController.text = widget.childToUpdate['name'];
    _birthdayController.text = widget.childToUpdate['birthday'];
    _homeCountryController.text = widget.childToUpdate['migration_background'] ?? "";

    String gender = widget.childToUpdate['gender'];
    selectedGender = stringToGender(gender);

    int migration = widget.childToUpdate['migration'];
    selectedMigration = intToBool(migration);
    }
    catch(e, stackTrace){
      helper.showErrorMessage(context, e.toString(), stackTrace: stackTrace);
    }
  }

  GenderItem? genderMapToDropDownItem(Genders gender, BuildContext context){
    final items = getGenderItems(context);
    switch(gender){
      case Genders.m:
        return items[0];
      case Genders.f:
        return items[1];
      case Genders.d:
        return items[2];
    }
  }

  MigraionItem? migrationMapToDropDownItem(bool migration, BuildContext context){
    final items = getMigrationItems(context);
    if(migration){
      return items[0];
    }
    else{
      return items[1];
    }
  }

  void _submitForm() async {
    final localizations = AppLocalizations.of(context);
    String name = _nameController.text.trim();
    String birthday = _birthdayController.text.trim();
    String homeCountry = _homeCountryController.text.trim();

    // Validate empty fields
    if (name.isEmpty ||
        birthday.isEmpty ||
        selectedGender == null ||
        selectedMigration == null) {
      helper.showErrorMessage(context, localizations.allFieldsMustBeFilled);
      debugPrint(
          "$name, $birthday, $selectedGender, $selectedMigration, $homeCountry");
      return;
    }

    if (selectedMigration == true && homeCountry.isEmpty) {
      helper.showErrorMessage(
          context, localizations.homeCountryRequiredForMigration);
      return;
    }

    // Validate date format (YYYY-MM-dd)
    if (!_isValidDate(birthday)) {
      helper.showErrorMessage(context, localizations.invalidDateFormat);
      return;
    }

    try {
      //create child object and pop page
      final child = Child(
          name: name,
          birthday: birthday,
          gender: selectedGender!,
          migration: selectedMigration!,
          migrationBackground: homeCountry);

      //database update database
      await updater.updateAllPeopleTable(widget.childToUpdate['id'], child);
      
      await helper.showSubmitMessage(
          context, localizations.updatedSuccessfully);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on custom_db_exceptions.DuplicatePersonException catch (e) {
      helper.showErrorMessage(context, localizations.personNamedAlreadyExists(e.name));

    } on custom_db_exceptions.PersonNotFoundException catch (e) {
      helper.showErrorMessage(context, localizations.personWithIdNotFound(e.id));
      
    } on custom_db_exceptions.DbConnectionException catch (e) {
      debugPrint('Database connection error: $e');
      if (mounted) {
        await DbConnectionValidator.handleConnectionError(context);
      }
    } on custom_db_exceptions.DatabaseOperationException catch (e, stackTrace) {
      debugPrint('Database operation error: $e');
      helper.showErrorMessage(context, e.toString(),
          stackTrace: stackTrace);
    } catch (e, stackTrace) {

      helper.showErrorMessage(context, e.toString(),
          stackTrace: stackTrace);
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
    DateTime initialDate;
    try {
      initialDate = DateFormat('yyyy-MM-dd').parse(_birthdayController.text);
    } catch (e) {
      // Fallback to the current date if parsing fails
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
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
      String formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        _birthdayController.text = formattedDate;
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
                textStyle: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                dropdownMenuEntries: getGenderItems(context).map<DropdownMenuEntry<GenderItem>>((GenderItem menu) {
                  return DropdownMenuEntry<GenderItem>(
                    value: menu, 
                    label: menu.label, 
                    leadingIcon: Icon(menu.icon, size: ResponsiveUtils.getIconSize(context)),
                    style: MenuItemButton.styleFrom(
                      textStyle: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                    ),
                  );
                }).toList(),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(borderRadius: ResponsiveUtils.getCardBorderRadius(context)),
                  contentPadding: ResponsiveUtils.getContentPadding(context),
                ),
                trailingIcon: selectedGender != null
                    ? IconButton(
                        icon: Icon(Icons.clear, size: ResponsiveUtils.getIconSize(context)),
                        onPressed: () {
                          setState(() {
                            selectedGender = null;
                            _genderController.clear();
                            initalSelectionGenderValueDropDown = null;
                          });
                        },
                      )
                    : null,
                onSelected: (GenderItem? item) {
                  setState(() {
                    selectedGender = item?.value;
                  });
                }
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
                dropdownMenuEntries: getMigrationItems(context).map<DropdownMenuEntry<MigraionItem>>((MigraionItem menu) {
                  return DropdownMenuEntry<MigraionItem>(
                    value: menu, 
                    label: menu.label, 
                    leadingIcon: Icon(menu.icon, size: ResponsiveUtils.getIconSize(context)),
                    style: MenuItemButton.styleFrom(
                      textStyle: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                    ),
                  );
                }).toList(),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(borderRadius: ResponsiveUtils.getCardBorderRadius(context)),
                  contentPadding: ResponsiveUtils.getContentPadding(context),
                ),
                trailingIcon: selectedMigration != null
                    ? IconButton(
                        icon: Icon(Icons.clear, size: ResponsiveUtils.getIconSize(context)),
                        onPressed: () {
                          setState(() {
                            selectedMigration = null;
                            _migrationController.clear();
                            initalSelectionMigrationValueDropDown = null;
                          });
                        },
                      )
                    : null,
                onSelected: (MigraionItem? item) {
                  setState(() {
                    selectedMigration = item?.value;

                    if (selectedMigration == false) {
                      _homeCountryController.clear();
                    }
                  });
                }
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