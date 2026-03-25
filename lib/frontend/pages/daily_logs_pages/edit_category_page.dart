import 'package:attendly/data/local/config/db_exceptions.dart' as custom_db_exceptions;
import 'package:attendly/data/local/tables/enums/category.dart';
import 'package:attendly/data/repo/daily_repository.dart';
import 'package:attendly/frontend/utils/responsive_utils.dart';
import 'package:attendly/provider/daily_repo_provider.dart';
import 'package:flutter/material.dart';
import 'package:attendly/frontend/pages/directory_pages/message_helper.dart';
import 'package:attendly/frontend/person_model/category_record.dart';
import 'package:attendly/frontend/selection_options/category_item.dart';
import 'package:attendly/localization/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditCategoryPage extends ConsumerStatefulWidget {
  final CategoryRecord record;
  final bool isTablet;

  const EditCategoryPage({
    super.key,
    required this.record,
    this.isTablet = false,
  });

  @override
  ConsumerState<EditCategoryPage> createState() => _EditCategoryPageState();
}

class _EditCategoryPageState extends ConsumerState<EditCategoryPage> {
  late TextEditingController _commentController;
  late TextEditingController _categoryController;
  Category? _selectedCategory;

  late DailyRepository _repo;
  final HelperAllPerson _helper = HelperAllPerson();
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
      debugPrint("Not adding twice to the open cat");
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
    final iconSize = ResponsiveUtils.getIconSize(context);
    DateTime parsedDate = DateTime.parse(widget.record.date);
    String formattedDisplayDate = DateFormat('dd.MM.yyyy').format(parsedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.editCategory,
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
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveUtils.getListPadding(context).vertical,
          horizontal: ResponsiveUtils.getListPadding(context).horizontal,
        ),
        child: Padding(
          padding: ResponsiveUtils.getContentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${localizations.date}: $formattedDisplayDate',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getBodyFontSize(context),
                ),
              ),
              SizedBox(height: ResponsiveUtils.getListPadding(context).vertical * 2),
              Text(
                '${localizations.category}:', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getBodyFontSize(context),
                ),
              ),
              SizedBox(height: ResponsiveUtils.getListPadding(context).vertical / 2),
              DropdownMenu<CategoryItem>(
                controller: _categoryController,
                expandedInsets: EdgeInsets.zero,
                hintText: localizations.selectCategory,
                textStyle: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                initialSelection: getCategoryItems(context)
                    .firstWhereOrNull((item) => item.category == _selectedCategory),
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
                    leadingIcon: menu.icon != null ? Icon(menu.icon, size: ResponsiveUtils.getIconSize(context)) : null,
                    style: MenuItemButton.styleFrom(
                      textStyle: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                    ),
                  );
                }).toList(),
                menuHeight: ResponsiveUtils.isTablet(context) ? 300 : 250,
                width: MediaQuery.of(context).size.width - (ResponsiveUtils.isTablet(context) ? 48 : 32),
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(borderRadius: ResponsiveUtils.getCardBorderRadius(context)),
                  contentPadding: ResponsiveUtils.getContentPadding(context),
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
              SizedBox(height: ResponsiveUtils.getListPadding(context).vertical * 2),
              Text(
                localizations.commentOptional, 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getBodyFontSize(context),
                ),
              ),
              SizedBox(height: ResponsiveUtils.getListPadding(context).vertical / 2),
              TextField(
                controller: _commentController,
                maxLines: 1,
                style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveUtils.getCardBorderRadius(context),
                  ),
                  contentPadding: ResponsiveUtils.getContentPadding(context),
                  hintText: localizations.enterComment,
                  hintStyle: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                ),
              ),
              SizedBox(height: ResponsiveUtils.getListPadding(context).vertical * 3),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _submitChanges,
                  icon: Icon(Icons.save, color: Colors.white, size: ResponsiveUtils.getIconSize(context, baseSize: 28)),
                  label: Text(
                    localizations.saveChanges,
                    style: TextStyle(fontSize: ResponsiveUtils.getBodyFontSize(context)),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getContentPadding(context).horizontal,
                      vertical: ResponsiveUtils.getContentPadding(context).vertical / 2,
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