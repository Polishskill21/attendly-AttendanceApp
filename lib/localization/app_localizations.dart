import 'package:flutter/material.dart';

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get settings;
  String get darkMode;
  String get language;
  String get english;
  String get german;
  String get appWillRestart;
  String get enableDisableDarkTheme;
  String get selectApplicationLanguage;
  String get darkModeOn;
  String get darkModeOff;
  String get languageSetTo;
  String get appRestartRequired;
  String get debugInformation;
  String getAppsVerision(String verion);
  String get databasePath;
  String get connectionStatus;
  String get connected;
  String get disconnected;
  String get notAvailable;
  String get directory;
  String get dailyLogs;
  String get weeklyReport;
  String get yearStats;
  String get changeDatabase;
  String get noDatabaseOpen;
  String get invalidFileType;
  String get pleaseSelectValidDbFile;
  String get databaseSwitchFailed;
  String get attendly;
  
  // New strings for UI elements
  String get allPeople;
  String get dailyPerson;
  String get addPerson;
  String get name;
  String get birthday;
  String get gender;
  String get migration;
  String get migrationBackground;
  String get homeCountry;
  String get male;
  String get female;
  String get diverse;
  String get yes;
  String get no;
  String get cancel;
  String get delete;
  String get save;
  String get edit;
  String get confirmDeletion;
  String get confirmDelete;
  String get unknownError;
  String get enterName;
  String get enterBirthday;
  String get selectGender;
  String get selectMigration;
  String get enterHomeCountry;
  String get selectChildGender;
  String get selectChildMigration;
  String get personAdded;
  String get personUpdated;
  String get personDeleted;
  String get errorOccurred;
  String get fillAllFields;
  String get invalidDate;
  String get selectDate;
  String get today;
  String get yesterday;
  String get total;
  String get offers;
  String get open;
  String get genderTotal;
  String get migrationGender;
  String get offersGender;
  String get ageGroups;
  String get under10;
  String get age10to13;
  String get age14to17;
  String get age18to24;
  String get over24;
  String get unknown;

  // For all_person_page
  String get searchForName;
  String get noPersonFound;
  String get selectAPerson;
  String confirmSelection(int count);
  String deletePersonTitle(String name);
  String get areYouSureYouWantToDelete;
  String personDeletedFromDb(String name, int id);
  String get unexpectedErrorContactCreator;
  String get contactTheCreator;
  String get unexpectedErrorProvideInfo;
  String get errorDialogContent;
  String personHasNRecords(int count);

  // For add_page.dart
  String get addPersonToTable;
  String get childsName;
  String get enterChildsName;
  String get childsBirthday;
  String get selectBirthday;
  String get selectChildsMigrationBackground;
  String get enterChildsHomeCountry;
  String get reset;
  String get submit;
  String get allFieldsMustBeFilled;
  String get invalidDateFormat;
  String get formSubmittedSuccessfully;
  String get allFieldsReset;
  String get homeCountryRequiredForMigration;

  // For custom_expansion_widget.dart
  String get editing;
  String get noData;

  // For helper messages
  String get operationSuccessful;
  String get operationFailed;

  // Missing strings for year_stats_page.dart
  String get yearlyStats;
  String get noDataForThisYear;
  String get ageGroupsTitle;
  String get openGender;
  String get offersGenderTitle;
  String get genderTotalTitle;
  String get migrationBackgroundGender;

  // Missing strings for edit_page.dart
  String get update;
  String get updatedSuccessfully;
  String get updateNotSuccessful;

  // Missing strings for helper_all_person.dart
  String get country;

  // Missing string for custom_drawer.dart
  String get currentDatabase;

  // Missing string for splash_screen.dart
  String get initializing;

  // Missing strings for category items
  String get parent;
  String get other;

  // For edit_category_page.dart
  String get editCategory;
  String get pleaseSelectCategory;
  String get date;
  String get category;
  String get selectCategory;
  String get recordUpdatedSuccessfully;
  String get failedToUpdateRecord;
  String get commentOptional;
  String get enterComment;
  String get saveChanges;

  // For daily_person_page.dart
  String get deleteRecord;
  String confirmDeleteCategory(String category, String name, String date);
  String get recordDeleted;
  String get failedToDeleteRecord;
  String get noEntriesForThisDay;
  String get id;
  String get addCategory;
  String get filterOptions;
  String get searchByName;
  String get filterByCategory;

  // For add_page_daily.dart
  String get addPersonToDailyTable;
  String get selectPerson;
  String get tapToSelectPersons;
  String personsSelected(int count);
  String get selectDateTitle;
  String get selectCategoryTitle;
  String get descriptionOptional;
  String get enterDescriptionOptional;
  String get personCategoryDateRequired;
  String personsFailedToAdd(int failCount, int successCount);
  String personsAddedSuccessfully(int successCount);
  String personAlreadyInCategoryOpen(String name);
  String personsAlreadyInCategoryOpen(int count, String names);

  // For year_stats_page.dart
  String summaryForWeeks(int weekCount);
  String get categoryAbbreviation;
  String get average;

  // For weekly_report_page.dart
  String get selectAWeek;
  String selectAWeekWithCount(int count);
  String get noWeeklyEntriesFound;
  String get showWeeksWithDataTooltip;
  String get selectWeekHelpText;
  String get noDataForThisWeek;
  String get weeksWithData;
  String get excludeFromYearReport;
  String get includeInYearReport;
  String get migrationBgAbbreviation;
  String get totalVisitors;

  // For debug menu
  String get debugSettings;
  String get settingsJsonContents;
  String get copyToClipboard;
  String get settingsCopiedToClipboard;
  String get settingsFileNotFound;
  String get errorReadingSettingsFile;
  String get debugMenuDescription;

  // Database connection handling
  String get databaseConnectionLost;
  String get databaseConnectionErrorMessage;
  String get ok;

  // Missing getters for splash screen
  String get retry;
  String get createNew;
  String get failedToCreateNewDatabase;

  // Chart dialog localizations
  String get statistics;
  String get close;
  String get noDataToDisplayInChart;

  // Year change handling
  String get yearChangeDetected;
  String get yearChangeMessage;
  String get createNewDatabase;
  String get continueCurrent;
  String get later;
  String get newYearAvailable;
  String get tapToCreateNewYearDatabase;

  String get saveDatabaseAs;
  String get databaseSavedSuccessfully;
  String get returnToMainDatabase;
  String get loading;

  String get withAbbreviation;
  String get withoutAbbreviation;
  String confirmBulkDelete(int count);
  String peopleEntriesDeleted(int count);

  // For settings page recalibration
  String get confirmAction;
  String get recalibrateConfirm;
  String get proceed;
  String get recalibrating;
  String get recalibrationSuccess;
  String get recalibrationFailed;
  String get recalibrateData;
  String get recalibrateDataDesc;
  String get databaseNotConnected;

  // New getters for exception localization
  String personWithIdNotFound(int id);
  String personNamedAlreadyExists(String name);

  // For db_list_page.dart
  String get selectDatabase;
  String errorLoadingFiles(String error);
  String get noDbFilesFound;
  String get currentlyLoaded;

  // For settings errors
  String get settingsErrorTitle;
  String get settingsErrorDirectory;
  String get settingsErrorFile;
  String settingsErrorKey(String key);

  String get help;
  String get openUserManual;
  String get externalPdfAppHint;
  String get failedToOpenPdf;
}