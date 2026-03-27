import 'package:attendly/backend/global/global_func.dart';
import 'package:attendly/data/local/config/database.dart';
import 'package:attendly/data/local/config/db_exceptions.dart' as custom_db_exceptions;
import 'package:attendly/data/local/tables/enums/category.dart';
import 'package:attendly/data/repo/daily_repository.dart';
import 'package:attendly/frontend/pages/directory_pages/dir_page.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';
import 'package:attendly/provider/daily_repo_provider.dart';
import 'package:attendly/provider/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:attendly/frontend/selection_options/category_item.dart';
import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
import 'package:attendly/localization/app_localizations.dart';

class AddDaily extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final List<Map<String, dynamic>>? preselectedPersons;
  final bool isTablet;

  const AddDaily({
    super.key, 
    this.initialDate, 
    this.preselectedPersons,
    this.isTablet = false,
  });

  @override
  ConsumerState<AddDaily> createState() => _AddDailyState();
}

class _AddDailyState extends ConsumerState<AddDaily>{
  DateTime? _persistedDate;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final HelperAllPerson helper = HelperAllPerson();

  late DailyRepository _repo;

  Category? selectedCategory;
  List<Map<String, dynamic>> selectedPersons = [];
  DateTime? selectedDate;
  int _multiplier = 1;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    _categoryController.dispose();
    _dateController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _repo = ref.read(dailyRepositoryProvider);
    final dbYear = ref.read(databaseManagerProvider).dbYear;
    
    // Initialize with passed date or current date
    selectedDate = widget.initialDate ?? _persistedDate ?? getScopedDate(dbYear: dbYear);
    _dateController.text = DateFormat('dd.MM.yyyy').format(selectedDate!);
    _controller.text = _multiplier.toString();

    if (widget.preselectedPersons != null && widget.preselectedPersons!.isNotEmpty) {
      selectedPersons.addAll(widget.preselectedPersons!);
    }
  }

  void _resetFields(){
    final localizations = AppLocalizations.of(context);
    final dbYear = ref.read(databaseManagerProvider).dbYear;
    setState(() {
      selectedPersons.clear();
      _commentController.clear();
      _categoryController.clear();
      selectedCategory = null;
      selectedDate = widget.initialDate ?? getScopedDate(dbYear: dbYear);
      _dateController.text = DateFormat('dd.MM.yyyy').format(selectedDate!);
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

    // Validate required fields
    if (selectedPersons.isEmpty || selectedCategory == null || selectedDate == null) {
      helper.showErrorMessage(context, localizations.personCategoryDateRequired);
      return false;
    }

    int successCount = 0;
    int failCount = 0;
    List<String> failedPersons = [];
    List<String> duplicatePersons = [];

    int currentMultiplier = (selectedCategory == Category.parent || selectedCategory == Category.other) ? _multiplier : 1;

    try {
      helper.showLoadingDialog(context, localizations.save);

      for (var person in selectedPersons) {
        try {
          // Create DailyPerson object
          await _repo.addDailyEntry(
            personId: person['id'],
            date: selectedDate!,
            category: selectedCategory!,
            description: description.isEmpty ? null : description,
            multiplier: currentMultiplier,
          );

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
        // if (mounted) {
        //   Navigator.of(context).pop(true);
        // }
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
    } on custom_db_exceptions.DatabaseNotReadyException {
      if(mounted) helper.hideLoadingDialog(context);
      return false;
    // } on custom_db_exceptions.DbConnectionException catch (e) {
    //   if(mounted) helper.hideLoadingDialog(context);
    //   debugPrint(e.toString());
    //   if (mounted) {
    //     await DbConnectionValidator.handleConnectionError(context);
    //   }
    //   return false;
    } catch (e, stackTrace) {
      if(mounted) helper.hideLoadingDialog(context);
      debugPrint('Unexpected error during form submission: $e');
      debugPrintStack(stackTrace: stackTrace);
      helper.showErrorMessage(context, e.toString(), stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _selectDate() async {
    final dbYear = ref.read(databaseManagerProvider).dbYear;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? getScopedDate(dbYear: dbYear),
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
                      
                      final value = await Navigator.of(context).push<List<DirectoryPeopleData>>(
                        MaterialPageRoute(
                          builder: (context) => DirectoryPage(
                            isSelectionMode: true,
                            
                            initiallySelectedIds: selectedPersons.map((p) => p['id'] as int).toList(),
                            
                            onPersonsSelected: (selectedPersonsData) {
                              Navigator.of(context).pop(selectedPersonsData);
                            },
                            isTablet: isTablet,
                          ),
                        )
                      );
                      
                      if (value != null) {
                        setState(() {
                          selectedPersons = value.map((person) => {
                            'id': person.id,
                            'name': person.name,
                          }).toList();
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
                      _multiplier = 1;
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
                  // width: MediaQuery.of(context).size.width - (isTablet ? 60 : 40),
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

                if (selectedCategory == Category.parent || selectedCategory == Category.other) ...[
                  SizedBox(height: ResponsiveUtils.getListPadding(context).vertical * 2),
                  Text(
                    localizations.numberOfEntries,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveUtils.getBodyFontSize(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
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
                              onPressed: _multiplier > 1
                                  ? () {
                                      setState(() {
                                        _multiplier--;
                                        _controller.text = _multiplier.toString();
                                      });
                                    }
                                  : null,
                            ),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: _controller,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getBodyFontSize(context),
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                ),
                                onChanged: (value) {
                                  final int? newValue = int.tryParse(value);
                                  if (newValue != null) {
                                    setState(() {
                                      _multiplier = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, size: iconSize),
                              onPressed: () {
                                setState(() {
                                  _multiplier++;
                                  _controller.text = _multiplier.toString();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

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