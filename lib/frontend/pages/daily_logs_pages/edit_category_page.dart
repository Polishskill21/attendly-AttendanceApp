import 'package:attendly/backend/enums/category.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:attendly/backend/dbLogic/db_read.dart';
import 'package:attendly/backend/dbLogic/db_update.dart';
import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
import 'package:attendly/frontend/person_model/category_record.dart';
import 'package:attendly/frontend/selection_options/category_item.dart';
import 'package:attendly/backend/db_exceptions.dart' as custom_db_exceptions;
import 'package:attendly/backend/db_connection_validator.dart';
import 'package:attendly/frontend/l10n/app_localizations.dart';
import 'package:sqflite/sqflite.dart';

class EditCategoryPage extends StatefulWidget {
  final CategoryRecord record;
  final Database database;

  const EditCategoryPage({
    super.key,
    required this.record,
    required this.database,
  });

  @override
  State<StatefulWidget> createState() => _EditCategoryPageState();
}

class _EditCategoryPageState extends State<EditCategoryPage> {
  late TextEditingController _commentController;
  late TextEditingController _categoryController;
  Category? _selectedCategory;
  late DbUpdater _updater;
  late HelperAllPerson _helper;
  bool _didChangeDependencies = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.record.comment);
    _selectedCategory = Category.values.byName(widget.record.category);
    _categoryController = TextEditingController();
    
    final reader = DbSelection(widget.database);
    _updater = DbUpdater(widget.database, reader);
    _helper = HelperAllPerson();
  }

  @override
  void didChangeDependencies() {
    if (!_didChangeDependencies) {
      _categoryController.text = getCategoryItems(context).firstWhereOrNull((item) => item.category == _selectedCategory)?.label ?? '';
      _didChangeDependencies = true;
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final localizations = AppLocalizations.of(context);
    if (_selectedCategory == null) {
      _helper.showErrorMessage(context, localizations.pleaseSelectCategory);
      return;
    }

    try {
      await _updater.updateDailyTable(
        widget.record.recordId,
        widget.record.date,
        widget.record.personId,
        _selectedCategory!,
        _commentController.text.trim(),
      );

      await _helper.showSubmitMessage(context, localizations.recordUpdatedSuccessfully);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on custom_db_exceptions.DbConnectionException catch (e) {
      debugPrint('Database connection error: $e');
      if (mounted) {
        await DbConnectionValidator.handleConnectionError(context);
      }
    } on custom_db_exceptions.DatabaseException catch (e) {
      debugPrint('Database error: $e');
      _helper.showErrorMessage(context, e.toString());
    } catch (e, stackTrace) {
      debugPrint('Unexpected error during category update: $e');
      debugPrintStack(stackTrace: stackTrace);
      _helper.showErrorMessage(context, e.toString(), stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.editCategory),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${localizations.date}: ${widget.record.date}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text('${localizations.category}:', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              DropdownMenu<CategoryItem>(
                controller: _categoryController,
                expandedInsets: EdgeInsets.zero,
                hintText: localizations.selectCategory,
                initialSelection: getCategoryItems(context).firstWhereOrNull((item) => item.category == _selectedCategory),
                enableFilter: true,
                requestFocusOnTap: false,
                onSelected: (CategoryItem? item) {
                  setState(() {
                    _selectedCategory = item?.category;
                  });
                },
                dropdownMenuEntries: getCategoryItems(context).map<DropdownMenuEntry<CategoryItem>>((CategoryItem menu) {
                  return DropdownMenuEntry<CategoryItem>(
                    value: menu,
                    label: menu.label,
                    leadingIcon: menu.icon != null ? Icon(menu.icon) : null,
                  );
                }).toList(),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                ),
                trailingIcon: _selectedCategory != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _selectedCategory = null;
                            _categoryController.clear();
                          });
                        },
                      )
                    : null,
              ),
              const SizedBox(height: 20),
              Text(localizations.commentOptional, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: localizations.enterComment,
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: Text(localizations.saveChanges),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
