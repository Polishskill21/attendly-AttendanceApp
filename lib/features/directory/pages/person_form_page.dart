import 'package:attendly/core/logging/app_logger.dart';
import 'package:attendly/core/responsive/responsive.dart';
import 'package:attendly/data/database/app_database.dart';
import 'package:attendly/data/database/exceptions.dart' as custom_db_exceptions;
import 'package:attendly/data/tables/enums/gender.dart';
import 'package:attendly/features/directory/providers/directory_providers.dart';
import 'package:attendly/features/directory/widgets/person_form_fields.dart';
import 'package:attendly/l10n/app_localizations.dart';
import 'package:attendly/shared/dialogs/app_dialogs.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum PersonFormMode { add, edit }

/// Adds a person to the directory, or edits [person].
class PersonFormPage extends ConsumerStatefulWidget {
  final PersonFormMode mode;

  /// The person to edit; required in [PersonFormMode.edit].
  final DirectoryPeopleData? person;

  const PersonFormPage({super.key, required this.mode, this.person})
      : assert(mode == PersonFormMode.add || person != null,
            'Edit mode needs the person to edit');

  @override
  ConsumerState<PersonFormPage> createState() => _PersonFormPageState();
}

class _PersonFormPageState extends ConsumerState<PersonFormPage> {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _migrationController = TextEditingController();
  final TextEditingController _homeCountryController = TextEditingController();

  DateTime? _birthday;
  Gender? _gender;
  bool? _migration;

  @override
  void initState() {
    super.initState();
    final person = widget.person;
    if (widget.mode == PersonFormMode.edit && person != null) {
      _nameController.text = person.name;
      _homeCountryController.text = person.migrationBackground ?? '';
      _birthdayController.text = _dateFormat.format(person.birthday);
      _birthday = person.birthday;
      _gender = person.gender;
      _migration = person.migration;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthdayController.dispose();
    _genderController.dispose();
    _migrationController.dispose();
    _homeCountryController.dispose();
    super.dispose();
  }

  void _resetFields() {
    setState(() {
      _nameController.clear();
      _birthdayController.clear();
      _homeCountryController.clear();
      _genderController.clear();
      _migrationController.clear();
      _birthday = null;
      _gender = null;
      _migration = null;
    });

    AppDialogs.showSnack(context, AppLocalizations.of(context).allFieldsReset);
  }

  Future<void> _pickBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendar,
      initialDatePickerMode: DatePickerMode.year,
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

    if (picked != null) {
      setState(() {
        _birthday = picked;
        _birthdayController.text = _dateFormat.format(picked);
      });
    }
  }

  /// Returns the validation message, or null when the form can be saved.
  /// Same rules as before: adding also checks the home country and the date.
  String? _validate(AppLocalizations localizations) {
    final name = _nameController.text.trim();
    switch (widget.mode) {
      case PersonFormMode.add:
        final birthdayText = _birthdayController.text.trim();
        if (name.isEmpty || birthdayText.isEmpty || _gender == null || _migration == null) {
          return localizations.allFieldsMustBeFilled;
        }
        if (_migration == true && _homeCountryController.text.trim().isEmpty) {
          return localizations.homeCountryRequiredForMigration;
        }
        try {
          _dateFormat.parseStrict(birthdayText);
        } catch (_) {
          return localizations.invalidDateFormat;
        }
        return null;
      case PersonFormMode.edit:
        if (name.isEmpty || _gender == null || _migration == null) {
          return localizations.allFieldsMustBeFilled;
        }
        return null;
    }
  }

  Future<void> _submit() async {
    final localizations = AppLocalizations.of(context);
    final error = _validate(localizations);
    if (error != null) {
      AppDialogs.showError(context, error);
      return;
    }

    try {
      switch (widget.mode) {
        case PersonFormMode.add:
          await _insert();
          if (!mounted) return;
          await AppDialogs.showSuccess(context, localizations.formSubmittedSuccessfully);
          if (mounted) Navigator.of(context).pop();
        case PersonFormMode.edit:
          final changed = await _update();
          if (!mounted) return;
          if (!changed) {
            Navigator.of(context).pop(false);
            return;
          }
          await AppDialogs.showSuccess(context, localizations.updatedSuccessfully);
          if (mounted) Navigator.of(context).pop(true);
      }
    } on custom_db_exceptions.DuplicatePersonException catch (e) {
      if (mounted) AppDialogs.showError(context, localizations.personNamedAlreadyExists(e.name));
    } on custom_db_exceptions.PersonNotFoundException catch (e) {
      if (mounted) AppDialogs.showError(context, localizations.personWithIdNotFound(e.id));
    } on custom_db_exceptions.DatabaseNotReadyException {
      return; // Safely abort if DB is transitioning
    } catch (e, stackTrace) {
      if (mounted) AppDialogs.showError(context, e.toString(), stackTrace: stackTrace);
    }
  }

  Future<void> _insert() {
    return ref.read(directoryRepositoryProvider).addPerson(
      DirectoryPeopleCompanion.insert(
        name: _nameController.text.trim(),
        birthday: _dateFormat.parse(_birthdayController.text.trim()),
        gender: _gender!,
        migration: _migration!,
        migrationBackground: Value(_homeCountryController.text.trim()),
      ),
    );
  }

  /// Writes only the changed fields. Returns false when nothing changed.
  Future<bool> _update() async {
    final p = widget.person!;
    final name = _nameController.text.trim();
    final homeCountry = _homeCountryController.text.trim();
    final birthday = _birthday!;

    DirectoryPeopleCompanion companion = const DirectoryPeopleCompanion();
    if (name != p.name) {
      companion = companion.copyWith(name: Value(name));
    }
    if (birthday.year != p.birthday.year ||
        birthday.month != p.birthday.month ||
        birthday.day != p.birthday.day) {
      companion = companion.copyWith(birthday: Value(birthday));
    }
    if (_gender != p.gender) {
      companion = companion.copyWith(gender: Value(_gender!));
    }
    if (_migration != p.migration) {
      companion = companion.copyWith(migration: Value(_migration!));
    }
    if (homeCountry != (p.migrationBackground ?? '')) {
      companion = companion.copyWith(migrationBackground: Value(homeCountry));
    }

    final hasChanges = companion.name.present ||
        companion.birthday.present ||
        companion.gender.present ||
        companion.migration.present ||
        companion.migrationBackground.present;

    if (!hasChanges) {
      AppLogger.d("Directory", "No changes detected, skipping update.");
      return false;
    }

    await ref.read(directoryRepositoryProvider).updatePerson(p.id, companion);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final responsive = Responsive.of(context);
    final isTablet = responsive.isTablet;
    final padding = responsive.contentPadding;
    final buttonPadding = EdgeInsets.symmetric(vertical: padding.vertical / 2);

    final title = switch (widget.mode) {
      PersonFormMode.add => localizations.addPersonToTable,
      PersonFormMode.edit => localizations.editPerson,
    };
    final submitLabel = switch (widget.mode) {
      PersonFormMode.add => localizations.submit,
      PersonFormMode.edit => localizations.update,
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
            icon: Icon(Icons.arrow_back, size: responsive.iconSize()),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: (isTablet ? 30 : 20) + MediaQuery.of(context).padding.bottom,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              padding.left + 12,
              padding.top + 8,
              padding.right + 12,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PersonFormFields(
                  nameController: _nameController,
                  birthdayController: _birthdayController,
                  genderController: _genderController,
                  migrationController: _migrationController,
                  homeCountryController: _homeCountryController,
                  gender: _gender,
                  migration: _migration,
                  onGenderChanged: (gender) => setState(() => _gender = gender),
                  onMigrationChanged: (migration) => setState(() => _migration = migration),
                  onPickBirthday: _pickBirthday,
                ),
                SizedBox(height: isTablet ? 70 : 60),
                if (widget.mode == PersonFormMode.add) ...[
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
                  SizedBox(height: isTablet ? 20 : 16),
                ],
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: Icon(Icons.check, size: responsive.iconSize(baseSize: 28), color: Colors.white),
                  label: Text(submitLabel, style: TextStyle(fontSize: responsive.bodyFontSize)),
                  style: ElevatedButton.styleFrom(padding: buttonPadding),
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
