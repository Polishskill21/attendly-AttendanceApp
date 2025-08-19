import 'package:attendly/backend/enums/category.dart';
import 'package:attendly/backend/global/global_func.dart';
import 'package:attendly/frontend/pages/directory_pages/dir_page.dart';
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
import 'package:attendly/frontend/l10n/app_localizations.dart';

class AddDaily extends StatefulWidget{
  final Database database;
  final DateTime? initialDate;
  final List<Map<String, dynamic>>? preselectedPersons;

  const AddDaily({super.key, required this.database, this.initialDate, this.preselectedPersons});

  @override
  State<StatefulWidget> createState() => _AddDailyState();
}

class _AddDailyState extends State<AddDaily>{
  final TextEditingController _descriptionController = TextEditingController();
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
    _descriptionController.dispose();
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
    selectedDate = widget.initialDate ?? getCurrentDate();
    _dateController.text = dateToString(selectedDate!);

    if (widget.preselectedPersons != null && widget.preselectedPersons!.isNotEmpty) {
      selectedPersons.addAll(widget.preselectedPersons!);
    }
  }

  void _resetFields(){
    final localizations = AppLocalizations.of(context);
    setState(() {
      selectedPersons.clear();
      _descriptionController.clear();
      _categoryController.clear();
      selectedCategory = null;
      selectedDate = widget.initialDate ?? getCurrentDate();
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
    String description = _descriptionController.text.trim();
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
          failCount++;
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
        helper.showErrorMessage(context, localizations.personsAlreadyInCategoryOpen(duplicatePersons.length, names));
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
      initialDate: selectedDate ?? getCurrentDate(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      keyboardType: TextInputType.numberWithOptions()
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _dateController.text = dateToString(picked);
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
          title: Text(localizations.addPersonToDailyTable),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: 20 + MediaQuery.of(context).padding.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Person Selection Card
                Text(localizations.selectPerson, style: const TextStyle(fontWeight: FontWeight.bold)),
                Card(
                  elevation: 4,
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
                          ),
                        )
                      );
                      if (value != null) {
                        setState(() {
                          selectedPersons = value;
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            selectedPersons.isEmpty ? Icons.person_add : Icons.group,
                            size: 40,
                            color: selectedPersons.isEmpty ? Colors.grey : Colors.blue,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedPersons.isEmpty 
                                    ? localizations.tapToSelectPersons 
                                    : localizations.personsSelected(selectedPersons.length),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: selectedPersons.isEmpty ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                if (selectedPersons.isNotEmpty) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    selectedPersons.map((p) => p['name']).join(', '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600])
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
                              icon: Icon(Icons.close, color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Date Input Field
                Text(localizations.selectDateTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: _selectDate,
                    decoration: InputDecoration(
                      hintText: "YYYY-MM-dd",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _selectDate,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Category Dropdown
                Text(localizations.selectCategoryTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                DropdownMenu<CategoryItem>(
                  controller: _categoryController,
                  expandedInsets: EdgeInsets.zero,
                  hintText: localizations.selectCategory,
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
                      leadingIcon: menu.icon != null ? Icon(menu.icon) : null
                    );
                  }).toList(),
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                  ),
                  trailingIcon: selectedCategory != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              selectedCategory = null;
                              _categoryController.clear();
                            });
                          },
                        )
                      : null,
                ),

                const SizedBox(height: 20),

                // Description Input Field (Optional)
                Text(localizations.descriptionOptional, style: const TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: localizations.enterDescriptionOptional,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.cancel),
                        onPressed: () => _descriptionController.clear(),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon( 
                      onPressed: _resetFields, 
                      icon: const Icon(Icons.refresh, size: 25),
                      label: Text(localizations.reset, style: const TextStyle(fontSize: 20)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _submitForm(),
                      icon: const Icon(Icons.check, size: 25, color: Colors.white),
                      label: Text(localizations.submit, style: const TextStyle(fontSize: 20)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
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