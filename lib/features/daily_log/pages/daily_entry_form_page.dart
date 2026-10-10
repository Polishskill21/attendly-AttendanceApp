import 'package:attendly/core/logging/app_logger.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/core/utils/date_utils.dart';
import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/database/database_provider.dart';
import 'package:attendly/data/database/exceptions.dart' as custom_db_exceptions;
import 'package:attendly/data/tables/enums/category.dart';
import 'package:attendly/features/daily_log/models/category_record.dart';
import 'package:attendly/features/daily_log/providers/daily_log_providers.dart';
import 'package:attendly/features/daily_log/widgets/daily_entry_fields.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:attendly/shared/dialogs/app_dialogs.dart';
import 'package:attendly/shared/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum DailyEntryFormMode { add, edit }

/// A person picked for a daily entry.
typedef SelectedPerson = ({int id, String name});

/// Adds a category for one or more people on a day, or edits the category
/// and comment of one existing entry ([record]).
class DailyEntryFormPage extends ConsumerStatefulWidget {
  final DailyEntryFormMode mode;

  /// Add mode: the day to preselect (defaults to today / the database year).
  final DateTime? initialDate;

  /// Add mode: people that are fixed for this entry (from the daily log).
  /// When empty, the people are picked with the person picker.
  final List<SelectedPerson> preselectedPersons;

  /// Edit mode: the entry to edit.
  final CategoryRecord? record;

  const DailyEntryFormPage({
    super.key,
    required this.mode,
    this.initialDate,
    this.preselectedPersons = const [],
    this.record,
  }) : assert(mode == DailyEntryFormMode.add || record != null,
            'Edit mode needs the record to edit');

  @override
  ConsumerState<DailyEntryFormPage> createState() => _DailyEntryFormPageState();
}

class _DailyEntryFormPageState extends ConsumerState<DailyEntryFormPage> {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  /// Categories that can be counted several times at once.
  static const Set<Category> _multiplierCategories = {
    Category.parent,
    Category.other,
    Category.offer,
  };

  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _multiplierController = TextEditingController(text: '1');

  Category? _category;
  List<SelectedPerson> _persons = [];
  late DateTime _date;
  int _multiplier = 1;

  bool get _isAdd => widget.mode == DailyEntryFormMode.add;
  bool get _peopleLocked => widget.preselectedPersons.isNotEmpty;
  bool get _showMultiplier => _isAdd && _multiplierCategories.contains(_category);

  @override
  void initState() {
    super.initState();
    switch (widget.mode) {
      case DailyEntryFormMode.add:
        _date = _defaultDate();
        _persons = [...widget.preselectedPersons];
      case DailyEntryFormMode.edit:
        final record = widget.record!;
        _date = DateTime.parse(record.date);
        _category = Category.values.byName(record.category);
        _commentController.text = record.comment ?? '';
    }
    _dateController.text = _dateFormat.format(_date);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _categoryController.dispose();
    _dateController.dispose();
    _multiplierController.dispose();
    super.dispose();
  }

  DateTime _defaultDate() {
    final dbYear = ref.read(databaseProvider).dbYear;
    return widget.initialDate ?? getScopedDate(dbYear: dbYear);
  }

  void _resetFields() {
    setState(() {
      _persons = [...widget.preselectedPersons];
      _commentController.clear();
      _categoryController.clear();
      _category = null;
      _multiplier = 1;
      _multiplierController.text = '1';
      _date = _defaultDate();
      _dateController.text = _dateFormat.format(_date);
    });

    AppDialogs.showSnack(context, AppLocalizations.of(context).allFieldsReset);
  }

  Future<void> _pickPersons() async {
    final value = await Navigator.of(context).pushNamed<List<DirectoryPeopleData>>(
      AppRoutes.personPicker,
      arguments: _persons.map((p) => p.id).toList(),
    );
    if (value != null && mounted) {
      setState(() {
        _persons = [for (final person in value) (id: person.id, name: person.name)];
      });
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      keyboardType: TextInputType.numberWithOptions(),
      builder: (context, child) {
        if (!Responsive.of(context).isTablet || child == null) return child ?? const SizedBox.shrink();

        final mq = MediaQuery.of(context);
        final newScale = (mq.textScaler.scale(1.0) * 1.2).clamp(1.0, 1.6);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(newScale)),
          child: Transform.scale(scale: 1.1, child: child),
        );
      },
    );

    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
        _dateController.text = _dateFormat.format(picked);
      });
    }
  }

  String? get _description {
    final text = _commentController.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _submit() => switch (widget.mode) {
        DailyEntryFormMode.add => _addEntries(),
        DailyEntryFormMode.edit => _updateEntry(),
      };

  Future<void> _addEntries() async {
    final localizations = AppLocalizations.of(context);

    if (_persons.isEmpty || _category == null) {
      AppDialogs.showError(context, localizations.personCategoryDateRequired);
      return;
    }

    // Read what the user actually sees in the field (it can be empty or 0)
    // and never submit less than 1 - a 0 would silently insert nothing while
    // still reporting success.
    int multiplier = 1;
    if (_showMultiplier) {
      final parsed = int.tryParse(_multiplierController.text.trim()) ?? 1;
      multiplier = parsed < 1 ? 1 : parsed;
      if (_multiplier != multiplier || _multiplierController.text != '$multiplier') {
        setState(() {
          _multiplier = multiplier;
          _multiplierController.text = '$multiplier';
        });
      }
    }

    final repo = ref.read(dailyRepositoryProvider);
    int successCount = 0;
    final failedPersons = <String>[];
    final duplicatePersons = <String>[];

    AppDialogs.showLoading(context, localizations.save);
    try {
      for (final person in _persons) {
        try {
          await repo.addDailyEntry(
            personId: person.id,
            date: _date,
            category: _category!,
            description: _description,
            multiplier: multiplier,
          );
          successCount++;
        } on custom_db_exceptions.DuplicateDailyEntryException {
          duplicatePersons.add(person.name);
          AppLogger.d("Daily", "Person ${person.id} already has this category, skipped");
        } on custom_db_exceptions.DatabaseNotReadyException {
          rethrow;
        } catch (e, stackTrace) {
          failedPersons.add("${person.name}: Unexpected error - $e");
          AppLogger.e("Daily", "Unexpected error adding person ${person.id}", e, stackTrace);
        }
      }
    } on custom_db_exceptions.DatabaseNotReadyException {
      if (mounted) AppDialogs.hideLoading(context);
      return;
    }

    if (!mounted) return;
    AppDialogs.hideLoading(context);

    if (duplicatePersons.isNotEmpty) {
      await AppDialogs.showInfo(
        context,
        localizations.personsAlreadyInCategoryOpen(duplicatePersons.length, duplicatePersons.join(', ')),
      );
    } else if (failedPersons.isNotEmpty) {
      AppDialogs.showError(context,
          "${localizations.personsFailedToAdd(failedPersons.length, successCount)}\n\nDetails:\n${failedPersons.join('\n\n')}");
    } else {
      await AppDialogs.showSuccess(context, localizations.personsAddedSuccessfully(successCount));
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  Future<void> _updateEntry() async {
    final localizations = AppLocalizations.of(context);
    final record = widget.record!;

    if (_category == null) {
      AppDialogs.showError(context, localizations.pleaseSelectCategory);
      return;
    }

    try {
      await ref.read(dailyRepositoryProvider).updateDailyEntry(
        recordId: record.recordId,
        date: _date,
        personId: record.personId,
        newCategory: _category!,
        newDescription: _description,
      );
      if (!mounted) return;

      await AppDialogs.showSuccess(context, localizations.recordUpdatedSuccessfully);
      if (mounted) Navigator.of(context).pop(true);
    } on custom_db_exceptions.DuplicateDailyEntryException {
      AppLogger.d("Daily", "Not adding twice to the open category");
      if (!mounted) return;
      await AppDialogs.showInfo(
        context,
        localizations.personAlreadyInCategoryOpen(record.personName ?? localizations.unknown),
      );
    } on custom_db_exceptions.DatabaseNotReadyException {
      return;
    } on custom_db_exceptions.DatabaseException catch (e) {
      if (mounted) AppDialogs.showError(context, e.toString());
    } catch (e, stackTrace) {
      if (mounted) AppDialogs.showError(context, e.toString(), stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final responsive = Responsive.of(context);
    final iconSize = responsive.iconSize();
    final padding = responsive.contentPadding;
    final gap = SizedBox(height: responsive.listPadding.vertical * 2);
    final buttonPadding = EdgeInsets.symmetric(vertical: padding.vertical / 2);

    final title = switch (widget.mode) {
      DailyEntryFormMode.add => localizations.addPersonToDailyTable,
      DailyEntryFormMode.edit => localizations.editCategory,
    };

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: TextStyle(
              fontSize: responsive.titleFontSize,
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
            bottom: padding.bottom + MediaQuery.of(context).padding.bottom,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(padding.left + 12, padding.top + 8, padding.right + 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isAdd) ...[
                  FieldLabel(localizations.selectPerson),
                  PersonSelectionCard(
                    names: _persons.map((p) => p.name).toList(),
                    onTap: _peopleLocked ? null : _pickPersons,
                    onClear: _peopleLocked ? null : () => setState(() => _persons = []),
                  ),
                  gap,
                  FieldLabel(localizations.selectDateTitle),
                  TextField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: _pickDate,
                    style: TextStyle(fontSize: responsive.bodyFontSize),
                    decoration: InputDecoration(
                      hintText: "YYYY-MM-dd",
                      hintStyle: TextStyle(fontSize: responsive.bodyFontSize),
                      contentPadding: padding,
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today, size: iconSize),
                        onPressed: _pickDate,
                      ),
                      border: OutlineInputBorder(borderRadius: responsive.cardBorderRadius),
                    ),
                  ),
                ] else
                  FieldLabel('${localizations.date}: ${_dateController.text}'),
                gap,

                FieldLabel(_isAdd ? localizations.selectCategoryTitle : '${localizations.category}:'),
                CategoryDropdown(
                  controller: _categoryController,
                  selected: _category,
                  onChanged: (category) => setState(() {
                    _category = category;
                    _multiplier = 1;
                    _multiplierController.text = '1';
                  }),
                ),

                if (_showMultiplier) ...[
                  gap,
                  FieldLabel(localizations.numberOfEntries),
                  const SizedBox(height: 8),
                  MultiplierInput(
                    controller: _multiplierController,
                    value: _multiplier,
                    onChanged: (value) => setState(() => _multiplier = value),
                  ),
                ],
                gap,

                FieldLabel(_isAdd ? localizations.descriptionOptional : localizations.commentOptional),
                TextField(
                  controller: _commentController,
                  maxLines: 1,
                  style: TextStyle(fontSize: responsive.bodyFontSize),
                  decoration: InputDecoration(
                    hintText: _isAdd ? localizations.enterDescriptionOptional : localizations.enterComment,
                    hintStyle: TextStyle(fontSize: responsive.bodyFontSize),
                    contentPadding: padding,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.cancel, size: iconSize),
                      onPressed: () => _commentController.clear(),
                    ),
                    border: OutlineInputBorder(borderRadius: responsive.cardBorderRadius),
                  ),
                ),
                SizedBox(height: responsive.buttonHeight),

                if (_isAdd) ...[
                  OutlinedButton.icon(
                    onPressed: _resetFields,
                    icon: Icon(Icons.refresh, size: responsive.iconSize(baseSize: 26)),
                    label: Text(localizations.reset, style: TextStyle(fontSize: responsive.bodyFontSize)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      padding: buttonPadding,
                    ),
                  ),
                  SizedBox(height: responsive.listPadding.vertical * 1.5),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: Icon(Icons.check, size: responsive.iconSize(baseSize: 28), color: Colors.white),
                    label: Text(localizations.submit, style: TextStyle(fontSize: responsive.bodyFontSize)),
                    style: ElevatedButton.styleFrom(padding: buttonPadding),
                  ),
                ] else
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: Icon(Icons.save, color: Colors.white, size: responsive.iconSize(baseSize: 28)),
                      label: Text(localizations.saveChanges, style: TextStyle(fontSize: responsive.bodyFontSize)),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding.horizontal,
                          vertical: padding.vertical / 2,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
