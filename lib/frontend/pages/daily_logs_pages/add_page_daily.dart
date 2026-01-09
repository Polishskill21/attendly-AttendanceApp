import 'package:attendly/backend/enums/category.dart';
import 'package:attendly/backend/global/global_func.dart';
import 'package:attendly/frontend/pages/directory_pages/dir_page.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:attendly/frontend/selection_options/category_item.dart';
import 'package:attendly/backend/helpers/daily_person.dart';
import 'package:attendly/backend/dbLogic/db_insert.dart';
import 'package:attendly/backend/dbLogic/db_read.dart';
import 'package:attendly/backend/dbLogic/db_update.dart';
import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
import 'package:attendly/backend/db_exceptions.dart' as custom_db_exceptions;
import 'package:attendly/backend/db_connection_validator.dart';
import 'package:attendly/localization/app_localizations.dart';

class AddDaily extends StatefulWidget{
  final Database database;
  final DateTime? initialDate;
  final List<Map<String, dynamic>>? preselectedPersons;
  final bool isTablet;

  const AddDaily({
    super.key, 
    required this.database, 
    this.initialDate, 
    this.preselectedPersons,
    this.isTablet = false,
  });

  @override
  State<StatefulWidget> createState() => _AddDailyState();
}

class _AddDailyState extends State<AddDaily>{
  DateTime? _persistedDate;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  Category? selectedCategory;
  List<Map<String, dynamic>> selectedPersons = [];
  DateTime? selectedDate;
  late DbInsertion inserter;
  late DbSelection reader;
  late DbUpdater updater;
  late HelperAllPerson helper;

  @override
  void dispose() {
    _commentController.dispose();
    _categoryController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    reader = DbSelection(widget.database);
    updater = DbUpdater(widget.database, reader);
    inserter = DbInsertion(widget.database, reader, updater);
    helper = HelperAllPerson();
    
    // Initialize with passed date or current date
    selectedDate = widget.initialDate ?? _persistedDate ?? getScopedDate();
    _dateController.text = dateToString(selectedDate!);

    if (widget.preselectedPersons != null && widget.preselectedPersons!.isNotEmpty) {
      selectedPersons.addAll(widget.preselectedPersons!);
    }
  }

  void _resetFields(){
    final localizations = AppLocalizations.of(context);
    setState(() {
      selectedPersons.clear();
      _commentController.clear();
      _categoryController.clear();
      selectedCategory = null;
      selectedDate = widget.initialDate ?? getScopedDate();
      _dateController.text = dateToString(selectedDate!);
    });

    if (widget.preselectedPersons != null && widget.preselectedPersons!.isNotEmpty) {
      setState(() {
        selectedPersons.addAll(widget.preselectedPersons!);
      });
    }

    helper.showResetMessage(context, localizations.allFieldsReset);
  }

  Future<bool> _submitForm() async {
    final localizations = AppLocalizations.of(context);
    String description = _commentController.text.trim();
    String dateStr = _dateController.text.trim();

    // Validate required fields
    if (selectedPersons.isEmpty || selectedCategory == null || dateStr.isEmpty) {
      helper.showErrorMessage(context, localizations.personCategoryDateRequired);
      return false;
    }

    int successCount = 0;
    int failCount = 0;
    List<String> failedPersons = [];
    List<String> duplicatePersons = [];

    try {
      helper.showLoadingDialog(context, localizations.save);
      for (var person in selectedPersons) {
        try {
          // Create DailyPerson object
          final dailyPerson = DailyPerson(
            id: person['id'],
            date: dateStr,
            category: selectedCategory!,
            description: description.isEmpty ? null : description
          );

          // Database insertion
          await inserter.dailyTable(dailyPerson);
          successCount++;

        } on custom_db_exceptions.DuplicateDailyEntryException catch (_) {
          duplicatePersons.add(person['name']);
          debugPrint("failed to add ${person['name']} since is in the category");
          
        } catch (e, stackTrace) {
          failCount++;
          failedPersons.add("${person['name']}: Unexpected error - $e");
          debugPrint("Unexpected error adding ${person['name']}: $e");
          debugPrintStack(stackTrace: stackTrace);
        }
      }

      if(mounted) helper.hideLoadingDialog(context);

      if (duplicatePersons.isNotEmpty) {
        String names = duplicatePersons.join(', ');
        await helper.showInfoMessageDialog(
          context,
          localizations.personsAlreadyInCategoryOpen(duplicatePersons.length, names),
        );
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else if (failCount > 0) {
        String errorDetails = failedPersons.join('\n\n');
        helper.showErrorMessage(context, "${localizations.personsFailedToAdd(failCount, successCount)}\n\nDetails:\n$errorDetails");
      } else {
        await helper.showSubmitMessage(context, localizations.personsAddedSuccessfully(successCount));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
      return successCount > 0 && failCount == 0;
    } on custom_db_exceptions.DbConnectionException catch (e) {
      if(mounted) helper.hideLoadingDialog(context);
      debugPrint(e.toString());
      if (mounted) {
        await DbConnectionValidator.handleConnectionError(context);
      }
      return false;
    } catch (e, stackTrace) {
      if(mounted) helper.hideLoadingDialog(context);
      debugPrint('Unexpected error during form submission: $e');
      debugPrintStack(stackTrace: stackTrace);
      helper.showErrorMessage(context, e.toString(), stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? getScopedDate(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _persistedDate = picked;
        _dateController.text = DateFormat('dd.MM.yyyy').format(picked);
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
            localizations.addPersonToDailyTable,
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
            padding: EdgeInsets.fromLTRB(
              ResponsiveUtils.getContentPadding(context).left + 12,
              ResponsiveUtils.getContentPadding(context).top + 8,
              ResponsiveUtils.getContentPadding(context).right + 12,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localizations.selectPerson,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                  )
                ),
                Card(
                  elevation: ResponsiveUtils.getCardElevation(context) + 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                  ),
                  child: InkWell(
                    onTap: (widget.preselectedPersons?.isNotEmpty ?? false) ? null : () async {
                      final value = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DirectoryPage(
                            dbCon: widget.database,
                            isSelectionMode: true,
                            onPersonsSelected: (selectedPersonsData) {
                              Navigator.of(context).pop(selectedPersonsData);
                            },
                            initiallySelectedPersons: selectedPersons,
                            isTablet: isTablet,
                          ),
                        )
                      );
                      if (value != null) {
                        setState(() {
                          selectedPersons = value;
                        });
                      }
                    },
                    borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                    child: Padding(
                      padding: ResponsiveUtils.getContentPadding(context),
                      child: Row(
                        children: [
                          Icon(
                            selectedPersons.isEmpty ? Icons.person_add : Icons.group,
                            size: ResponsiveUtils.getIconSize(context, baseSize: 40),
                            color: selectedPersons.isEmpty ? Colors.grey : Colors.blue,
                          ),
                          SizedBox(width: ResponsiveUtils.getContentPadding(context).horizontal / 2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedPersons.isEmpty
                                    ? localizations.tapToSelectPersons
                                    : localizations.personsSelected(selectedPersons.length),
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                                    fontWeight: FontWeight.bold,
                                    color: selectedPersons.isEmpty ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                if (selectedPersons.isNotEmpty) ...[
                                  SizedBox(height: ResponsiveUtils.getListPadding(context).vertical / 2),
                                  Text(
                                    selectedPersons.map((p) => p['name']).join(', '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.getBodyFontSize(context) - 2,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (selectedPersons.isNotEmpty && !(widget.preselectedPersons?.isNotEmpty ?? false))
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  selectedPersons.clear();
                                });
                              },
                              icon: Icon(Icons.close, color: Colors.red, size: iconSize),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: ResponsiveUtils.getListPadding(context).vertical * 2),

                Text(localizations.selectDateTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                  )
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: _selectDate,
                    style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                    decoration: InputDecoration(
                      hintText: "YYYY-MM-dd",
                      hintStyle: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                      contentPadding: ResponsiveUtils.getContentPadding(context),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today, size: iconSize),
                        onPressed: _selectDate,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: ResponsiveUtils.getListPadding(context).vertical * 2),

                Text(localizations.selectCategoryTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                  )
                ),
                DropdownMenu<CategoryItem>(
                  controller: _categoryController,
                  expandedInsets: EdgeInsets.zero,
                  hintText: localizations.selectCategory,
                  textStyle: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                  enableFilter: true,
                  requestFocusOnTap: false,
                  onSelected: (CategoryItem? item) {
                    setState(() {
                      selectedCategory = item?.category;
                    });
                  },
                  dropdownMenuEntries: getCategoryItems(context).map<DropdownMenuEntry<CategoryItem>>((CategoryItem menu) {
                    return DropdownMenuEntry<CategoryItem>(
                      value: menu,
                      label: menu.label,
                      leadingIcon: menu.icon != null ? Icon(menu.icon, size: ResponsiveUtils.getIconSize(context)) : null,
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
                  trailingIcon: selectedCategory != null
                      ? IconButton(
                          icon: Icon(Icons.clear, size: iconSize),
                          onPressed: () {
                            setState(() {
                              selectedCategory = null;
                              _categoryController.clear();
                            });
                          },
                        )
                      : null,
                ),

                SizedBox(height: ResponsiveUtils.getListPadding(context).vertical * 2),

                Text(localizations.descriptionOptional,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveUtils.getBodyFontSize(context),
                  )
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _commentController,
                    maxLines: 1,
                    style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                    decoration: InputDecoration(
                      hintText: localizations.enterDescriptionOptional,
                      hintStyle: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                      contentPadding: ResponsiveUtils.getContentPadding(context),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.cancel, size: iconSize),
                        onPressed: () => _commentController.clear(),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: ResponsiveUtils.getButtonHeight(context)),

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
                    SizedBox(height: ResponsiveUtils.getListPadding(context).vertical * 1.5),
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
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      )
    );
  }
}