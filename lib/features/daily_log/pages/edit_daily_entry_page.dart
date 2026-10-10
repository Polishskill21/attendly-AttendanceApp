import 'package:attendly/data/database/exceptions.dart' as custom_db_exceptions;
import 'package:attendly/data/tables/enums/category.dart';
import 'package:attendly/features/daily_log/data/daily_repository.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/features/daily_log/providers/daily_log_providers.dart';
import 'package:attendly/core/logging/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:attendly/shared/dialogs/app_dialogs.dart';
import 'package:attendly/features/daily_log/models/category_record.dart';
import 'package:attendly/shared/options/category_option.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditDailyEntryPage extends ConsumerStatefulWidget {
  final CategoryRecord record;

  const EditDailyEntryPage({
    super.key,
    required this.record,
  });

  @override
  ConsumerState<EditDailyEntryPage> createState() => _EditDailyEntryPageState();
}

class _EditDailyEntryPageState extends ConsumerState<EditDailyEntryPage> {
  late TextEditingController _commentController;
  late TextEditingController _categoryController;
  Category? _selectedCategory;

  late DailyRepository _repo;
  final AppDialogs _helper = AppDialogs();
  bool _didChangeDependencies = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.record.comment);
    _selectedCategory = Category.values.byName(widget.record.category);
    _categoryController = TextEditingController();

    _repo = ref.read(dailyRepositoryProvider);
  }

  @override
  void didChangeDependencies() {
    if (!_didChangeDependencies) {
      _categoryController.text = getCategoryOptions(context).firstWhereOrNull((item) => item.category == _selectedCategory)?.label ?? '';
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

  Future<void> _submitChanges() async {
    final localizations = AppLocalizations.of(context);
    if (_selectedCategory == null) {
      _helper.showErrorMessage(context, localizations.pleaseSelectCategory);
      return;
    }

    try {
      await _repo.updateDailyEntry(
        recordId: widget.record.recordId,
        date: DateTime.parse(widget.record.date),
        personId: widget.record.personId,
        newCategory: _selectedCategory!,
        newDescription: _commentController.text.trim().isEmpty 
            ? null 
            : _commentController.text.trim(),
      );

      await _helper.showSubmitMessage(context, localizations.recordUpdatedSuccessfully);
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on custom_db_exceptions.DuplicateDailyEntryException {
      AppLogger.d("Daily", "Not adding twice to the open category");
      await _helper.showInfoMessageDialog(
          context,
          localizations.personAlreadyInCategoryOpen(widget.record.personName ?? localizations.unknown),
        );
    } on custom_db_exceptions.DatabaseNotReadyException {
      return;
    // }on custom_db_exceptions.DbConnectionException catch (e) {
    //   debugPrint('Database connection error: $e');
    //   if (mounted) {
    //     await DbConnectionValidator.handleConnectionError(context);
    //   }
    } on custom_db_exceptions.DatabaseException catch (e) {
      _helper.showErrorMessage(context, e.toString());
    } catch (e, stackTrace) {
      _helper.showErrorMessage(context, e.toString(), stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final iconSize = Responsive.of(context).iconSize();
    DateTime parsedDate = DateTime.parse(widget.record.date);
    String formattedDisplayDate = DateFormat('dd.MM.yyyy').format(parsedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.editCategory,
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
        padding: EdgeInsets.symmetric(
          vertical: Responsive.of(context).listPadding.vertical,
          horizontal: Responsive.of(context).listPadding.horizontal,
        ),
        child: Padding(
          padding: Responsive.of(context).contentPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${localizations.date}: $formattedDisplayDate',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.of(context).bodyFontSize,
                ),
              ),
              SizedBox(height: Responsive.of(context).listPadding.vertical * 2),
              Text(
                '${localizations.category}:', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.of(context).bodyFontSize,
                ),
              ),
              SizedBox(height: Responsive.of(context).listPadding.vertical / 2),
              DropdownMenu<CategoryOption>(
                controller: _categoryController,
                expandedInsets: EdgeInsets.zero,
                hintText: localizations.selectCategory,
                textStyle: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                initialSelection: getCategoryOptions(context)
                    .firstWhereOrNull((item) => item.category == _selectedCategory),
                enableFilter: true,
                requestFocusOnTap: false,
                onSelected: (CategoryOption? item) {
                  setState(() {
                    _selectedCategory = item?.category;
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
                menuHeight: Responsive.of(context).isTablet ? 300 : 250,
                // width: MediaQuery.of(context).size.width - (Responsive.of(context).isTablet ? 48 : 32),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(borderRadius: Responsive.of(context).cardBorderRadius),
                  contentPadding: Responsive.of(context).contentPadding,
                ),
                trailingIcon: _selectedCategory != null
                    ? IconButton(
                        icon: Icon(Icons.clear, size: iconSize),
                        onPressed: () {
                          setState(() {
                            _selectedCategory = null;
                            _categoryController.clear();
                          });
                        },
                      )
                    : null,
              ),
              SizedBox(height: Responsive.of(context).listPadding.vertical * 2),
              Text(
                localizations.commentOptional, 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.of(context).bodyFontSize,
                ),
              ),
              SizedBox(height: Responsive.of(context).listPadding.vertical / 2),
              TextField(
                controller: _commentController,
                maxLines: 1,
                style: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: Responsive.of(context).cardBorderRadius,
                  ),
                  contentPadding: Responsive.of(context).contentPadding,
                  hintText: localizations.enterComment,
                  hintStyle: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                ),
              ),
              SizedBox(height: Responsive.of(context).listPadding.vertical * 3),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _submitChanges,
                  icon: Icon(Icons.save, color: Colors.white, size: Responsive.of(context).iconSize(baseSize: 28)),
                  label: Text(
                    localizations.saveChanges,
                    style: TextStyle(fontSize: Responsive.of(context).bodyFontSize),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.of(context).contentPadding.horizontal,
                      vertical: Responsive.of(context).contentPadding.vertical / 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}