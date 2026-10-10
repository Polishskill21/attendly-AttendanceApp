import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/database/exceptions.dart' as custom_db_exceptions;
import 'package:attendly/data/tables/enums/category.dart';
import 'package:attendly/features/daily_log/data/daily_repository.dart';
import 'package:attendly/shared/navigation/app_routes.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/core/utils/date_utils.dart';
import 'package:attendly/features/daily_log/providers/daily_log_providers.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:attendly/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendly/shared/options/category_option.dart';
import 'package:attendly/shared/dialogs/app_dialogs.dart';
import 'package:attendly/l10n/app_localizations.dart';


class AddDailyEntryPage extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final List<Map<String, dynamic>>? preselectedPersons;

  const AddDailyEntryPage({
    super.key, 
    this.initialDate, 
    this.preselectedPersons,
  });

  @override
  ConsumerState<AddDailyEntryPage> createState() => _AddDailyEntryPageState();
}

class _AddDailyEntryPageState extends ConsumerState<AddDailyEntryPage>{
  DateTime? _persistedDate;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final AppDialogs helper = AppDialogs();

  late DailyRepository _repo;

  Category? selectedCategory;
  List<Map<String, dynamic>> selectedPersons = [];
  DateTime? selectedDate;
  int _multiplier = 1;
  final TextEditingController _controller = TextEditingController();

  static const Set<Category> _multiplierCategories = {
    Category.parent,
    Category.other,
    Category.offer,
  };

  bool get _showMultiplier =>
      selectedCategory != null && _multiplierCategories.contains(selectedCategory);

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
    final dbYear = ref.read(databaseProvider).dbYear;
    
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
    final dbYear = ref.read(databaseProvider).dbYear;
    setState(() {
      selectedPersons.clear();
      _commentController.clear();
      _categoryController.clear();
      selectedCategory = null;
      _multiplier = 1;
      _controller.text = '1';
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

    // Read what the user actually sees in the field (it can be empty or 0)
    // and never submit less than 1 - a 0 would silently insert nothing while
    // still reporting success.
    int currentMultiplier = 1;
    if (_showMultiplier) {
      final parsed = int.tryParse(_controller.text.trim()) ?? 1;
      currentMultiplier = parsed < 1 ? 1 : parsed;
      if (_multiplier != currentMultiplier || _controller.text != '$currentMultiplier') {
        setState(() {
          _multiplier = currentMultiplier;
          _controller.text = '$currentMultiplier';
        });
      }
    }

    try {
      helper.showLoadingDialog(context, localizations.save);

      for (var person in selectedPersons) {
        try {
          // Create DailyLogTab object
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
          AppLogger.d("Daily", "Person ${person['id']} already has this category, skipped");
          
        } catch (e, stackTrace) {
          failCount++;
          failedPersons.add("${person['name']}: Unexpected error - $e");
          AppLogger.e("Daily", "Unexpected error adding person ${person['id']}", e, stackTrace);
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
      helper.showErrorMessage(context, e.toString(), stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _selectDate() async {
    final dbYear = ref.read(databaseProvider).dbYear;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? getScopedDate(dbYear: dbYear),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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
    final isTablet = Responsive.of(context).isTablet;
    final iconSize = Responsive.of(context).iconSize();
    
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            localizations.addPersonToDailyTable,
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
            padding: EdgeInsets.fromLTRB(
              Responsive.of(context).contentPadding.left + 12,
              Responsive.of(context).contentPadding.top + 8,
              Responsive.of(context).contentPadding.right + 12,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localizations.selectPerson,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.of(context).bodyFontSize,
                  )
                ),
                Card(
                  elevation: Responsive.of(context).cardElevation + 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: Responsive.of(context).cardBorderRadius,
                  ),
                  child: InkWell(
                    onTap: (widget.preselectedPersons?.isNotEmpty ?? false) ? null : () async {
                      
                      final value = await Navigator.of(context).pushNamed<List<DirectoryPeopleData>>(
                        AppRoutes.personPicker,
                        arguments: selectedPersons.map((p) => p['id'] as int).toList(),
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
                    borderRadius: Responsive.of(context).cardBorderRadius,
                    child: Padding(
                      padding: Responsive.of(context).contentPadding,
                      child: Row(
                        children: [
                          Icon(
                            selectedPersons.isEmpty ? Icons.person_add : Icons.group,
                            size: Responsive.of(context).iconSize(baseSize: 40),
                            color: selectedPersons.isEmpty ? Colors.grey : Colors.blue,
                          ),
                          SizedBox(width: Responsive.of(context).contentPadding.horizontal / 2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedPersons.isEmpty
                                    ? localizations.tapToSelectPersons
                                    : localizations.personsSelected(selectedPersons.length),
                                  style: TextStyle(
                                    fontSize: Responsive.of(context).bodyFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: selectedPersons.isEmpty ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                                if (selectedPersons.isNotEmpty) ...[
                                  SizedBox(height: Responsive.of(context).listPadding.vertical / 2),
                                  Text(
                                    selectedPersons.map((p) => p['name']).join(', '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: Responsive.of(context).bodyFontSize - 2,
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

                SizedBox(height: Responsive.of(context).listPadding.vertical * 2),

                Text(localizations.selectDateTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.of(context).bodyFontSize,
                  )
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: _selectDate,
                    style: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                    decoration: InputDecoration(
                      hintText: "YYYY-MM-dd",
                      hintStyle: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                      contentPadding: Responsive.of(context).contentPadding,
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today, size: iconSize),
                        onPressed: _selectDate,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: Responsive.of(context).cardBorderRadius,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: Responsive.of(context).listPadding.vertical * 2),

                Text(localizations.selectCategoryTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.of(context).bodyFontSize,
                  )
                ),
                DropdownMenu<CategoryOption>(
                  controller: _categoryController,
                  expandedInsets: EdgeInsets.zero,
                  hintText: localizations.selectCategory,
                  textStyle: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                  enableFilter: true,
                  requestFocusOnTap: false,
                  onSelected: (CategoryOption? item) {
                    setState(() {
                      selectedCategory = item?.category;
                      _multiplier = 1;
                      _controller.text = '1';
                    });
                  },
                  dropdownMenuEntries: getCategoryOptions(context).map<DropdownMenuEntry<CategoryOption>>((CategoryOption menu) {
                    return DropdownMenuEntry<CategoryOption>(
                      value: menu,
                      label: menu.label,
                      leadingIcon: menu.icon != null ? Icon(menu.icon, size: Responsive.of(context).iconSize()) : null,
                      style: MenuItemButton.styleFrom(
                        textStyle: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                      ),
                    );
                  }).toList(),
                  menuHeight: isTablet ? 300 : 250,
                  // width: MediaQuery.of(context).size.width - (isTablet ? 60 : 40),
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(borderRadius: Responsive.of(context).cardBorderRadius),
                    contentPadding: Responsive.of(context).contentPadding,
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

                if (_showMultiplier) ...[
                  SizedBox(height: Responsive.of(context).listPadding.vertical * 2),
                  Text(
                    localizations.numberOfEntries,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.of(context).bodyFontSize,
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
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                style: TextStyle(
                                  fontSize: Responsive.of(context).bodyFontSize,
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

                SizedBox(height: Responsive.of(context).listPadding.vertical * 2),

                Text(localizations.descriptionOptional,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.of(context).bodyFontSize,
                  )
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _commentController,
                    maxLines: 1,
                    style: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                    decoration: InputDecoration(
                      hintText: localizations.enterDescriptionOptional,
                      hintStyle: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                      contentPadding: Responsive.of(context).contentPadding,
                      suffixIcon: IconButton(
                        icon: Icon(Icons.cancel, size: iconSize),
                        onPressed: () => _commentController.clear(),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: Responsive.of(context).cardBorderRadius,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: Responsive.of(context).buttonHeight),

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
                    SizedBox(height: Responsive.of(context).listPadding.vertical * 1.5),
                    ElevatedButton.icon(
                      onPressed: () => _submitForm(),
                      icon: Icon(Icons.check, size: Responsive.of(context).iconSize(baseSize: 28), color: Colors.white),
                      label: Text(localizations.submit, style: TextStyle(fontSize: Responsive.of(context).bodyFontSize)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: Responsive.of(context).contentPadding.vertical / 2),
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