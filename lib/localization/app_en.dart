import 'app_localizations.dart';

class AppLocalizationsEn extends AppLocalizations {
  @override
  String get settings => 'Settings';

  @override
  String get homeCountryRequiredForMigration => 'Migration home country need to be filled out when migration is set to true';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get german => 'German';

  @override
  String get appWillRestart => 'The app will restart to apply the new language.';

  @override
  String get enableDisableDarkTheme => 'Enable or disable dark theme';

  @override
  String get selectApplicationLanguage => 'Select the application language';

  @override
  String get darkModeOn => 'Dark mode is on';

  @override
  String get darkModeOff => 'Dark mode is off';

  @override
  String get languageSetTo => 'Language set to';

  @override
  String get appRestartRequired => 'App restart may be required';

  @override
  String get debugInformation => 'Debug Information';

  @override
  String get databasePath => 'Database Path';

  @override
  String get connectionStatus => 'Connection Status';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get notAvailable => 'Not available';

  @override
  String get directory => 'Directory';

  @override
  String get dailyLogs => 'Daily Logs';

  @override
  String get weeklyReport => 'Weekly Report';

  @override
  String get yearStats => 'Year Stats';

  @override
  String get changeDatabase => 'Change Database';

  @override
  String get noDatabaseOpen => 'No database open';

  @override
  String get invalidFileType => 'Invalid file type';

  @override
  String get pleaseSelectValidDbFile => 'Please select a valid .db file';

  @override
  String get databaseSwitchFailed => 'Database opening/switch failed';

  @override
  String get attendly => 'Attendly';
  
  @override
  String get allPeople => 'All People';

  @override
  String get dailyPerson => 'Daily Person';

  @override
  String get addPerson => 'Add Person';

  @override
  String get name => 'Name';

  @override
  String get birthday => 'Birthday';

  @override
  String get gender => 'Gender';

  @override
  String get migration => 'Migration';

  @override
  String get migrationBackground => 'Migration Background';

  @override
  String get homeCountry => 'Home Country';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get diverse => 'Diverse';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get confirmDeletion => 'Confirm Deletion';

  @override
  String get confirmDelete => 'Are you sure you want to delete this person?';

  @override
  String get unknownError => 'Unknown Error';

  @override
  String get enterName => 'Enter name';

  @override
  String get enterBirthday => 'Enter birthday';

  @override
  String get selectGender => 'Select gender';

  @override
  String get selectMigration => 'Select migration status';

  @override
  String get enterHomeCountry => 'Enter home country';

  @override
  String get selectChildGender => 'Select person\'s gender';

  @override
  String get selectChildMigration => 'Select person\'s migration background';

  @override
  String get personAdded => 'Person added successfully';

  @override
  String get personUpdated => 'Person updated successfully';

  @override
  String get personDeleted => 'Person deleted successfully';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get fillAllFields => 'Please fill all required fields';

  @override
  String get invalidDate => 'Invalid date format';

  @override
  String get selectDate => 'Select date';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get total => 'Total';

  @override
  String get offers => 'Offers';

  @override
  String get open => 'Open';

  @override
  String get genderTotal => 'Gender Total';

  @override
  String get migrationGender => 'Migration Gender';

  @override
  String get offersGender => 'Offers Gender';

  @override
  String get ageGroups => 'Age Groups';

  @override
  String get under10 => 'Under 10';

  @override
  String get age10to13 => '10-13 years';

  @override
  String get age14to17 => '14-17 years';

  @override
  String get age18to24 => '18-24 years';

  @override
  String get over24 => 'Over 24 years';

  @override
  String get unknown => 'Unknown';

  // For all_person_page
  @override
  String get searchForName => 'Search for name';

  @override
  String get noPersonFound => 'No person found';

  @override
  String get selectAPerson => 'Select a person';

  @override
  String confirmSelection(int count) => 'Confirm Selection ($count)';

  @override
  String deletePersonTitle(String name) => 'Delete Person \n$name';

  @override
  String get areYouSureYouWantToDelete => 'Are you sure you want to delete this person?';

  @override
  String personDeletedFromDb(String name, int id) => "Person '$name' with ID '$id' has been deleted from the Db.";

  @override
  String get unexpectedErrorContactCreator => 'An unexpected error occurred.';

  @override
  String get contactTheCreator => 'Contact The Creator';

  @override
  String get unexpectedErrorProvideInfo => 'An unexpected error occurred. Please provide the following information to the developer:';

  @override
  String get errorDialogContent => 'An unexpected error occurred. Please contact the developer with the details below.';

  @override
  String personHasNRecords(int count) => 'This person has $count daily records. Deleting will remove all associated data.';

  // For add_page.dart
  @override
  String get addPersonToTable => 'Add Person to Table';

  @override
  String get childsName => "Person's Name";

  @override
  String get enterChildsName => "Enter Person's name";

  @override
  String get childsBirthday => "Person's Birthday";

  @override
  String get selectBirthday => 'Select birthday';

  @override
  String get selectChildsMigrationBackground => "Select the person's migration background";

  @override
  String get enterChildsHomeCountry => "Enter person's home country";

  @override
  String get reset => 'Reset';

  @override
  String get submit => 'Submit';

  @override
  String get allFieldsMustBeFilled => 'All fields must be filled out';

  @override
  String get invalidDateFormat => 'Invalid date format. Use YYYY-MM-dd';

  @override
  String get formSubmittedSuccessfully => 'Form submitted successfully!';

  @override
  String get allFieldsReset => 'All Fields have been reset';

  // For custom_expansion_widget.dart
  @override
  String get editing => 'Editing';

  @override
  String get noData => 'No data';

  // For helper messages
  @override
  String get operationSuccessful => 'Operation completed successfully';

  @override
  String get operationFailed => 'Operation failed';

  // Missing strings for year_stats_page.dart
  @override
  String get yearlyStats => 'Yearly Stats';

  @override
  String get noDataForThisYear => 'No data for this year';

  @override
  String get ageGroupsTitle => 'Work contacts by age group';

  @override
  String get openGender => 'Visitors by gender'; // Open area gender

  @override
  String get offersGenderTitle => 'Offers by gender';

  @override
  String get genderTotalTitle => 'Total work contacts';

  @override
  String get migrationBackgroundGender =>  'Visitors with migration background\nby gender';

  // Missing strings for edit_page.dart
  @override
  String get update => 'Update';

  @override
  String get updatedSuccessfully => 'Updated successfully!';

  @override
  String get updateNotSuccessful => 'The update was not successful';

  // Missing strings for helper_all_person.dart
  @override
  String get country => 'Country';

  // Missing string for custom_drawer.dart
  @override
  String get currentDatabase => 'Current Database';

  // Missing string for splash_screen.dart
  @override
  String get initializing => 'Initializing...';

  // Missing strings for category items
  @override
  String get parent => 'Parent';

  @override
  String get other => 'Other';

  // For edit_category_page.dart
  @override
  String get editCategory => 'Edit Category';
  @override
  String get pleaseSelectCategory => 'Please select a category.';
  @override
  String get date => 'Date';
  @override
  String get category => 'Category';
  @override
  String get selectCategory => 'Select the Category';
  @override
  String get recordUpdatedSuccessfully => 'Record updated successfully.';
  @override
  String get failedToUpdateRecord => 'Failed to update record.';
  @override
  String get commentOptional => 'Comment (Optional):';
  @override
  String get enterComment => 'Enter a comment';
  @override
  String get saveChanges => 'Save Changes';

  // For daily_person_page.dart
  @override
  String get deleteRecord => 'Delete Record?';
  @override
  String confirmDeleteCategory(String category, String name, String date) => 'Are you sure you want to delete the category "$category" for $name on $date?';
  @override
  String get recordDeleted => 'Record deleted.';
  @override
  String get failedToDeleteRecord => 'Failed to delete record.';
  @override
  String get noEntriesForThisDay => 'No entries for this day';
  @override
  String get id => 'ID';
  @override
  String get addCategory => 'Add Category';
  @override
  String get filterOptions => 'Filter options';
  @override
  String get searchByName => 'Search by Name';
  @override
  String get filterByCategory => 'Filter by Category';

  // For add_page_daily.dart
  @override
  String get addPersonToDailyTable => 'Add Person to Daily Table';
  @override
  String get selectPerson => 'Select Person';
  @override
  String get tapToSelectPersons => 'Tap to select person(s)';
  @override
  String personsSelected(int count) => '$count person(s) selected';
  @override
  String get selectDateTitle => 'Date';
  @override
  String get selectCategoryTitle => 'Select Category';
  @override
  String get descriptionOptional => 'Description (Optional)';
  @override
  String get enterDescriptionOptional => 'Enter description (optional)';
  @override
  String get personCategoryDateRequired => 'Person, Category and Date must be selected';
  @override
  String personsFailedToAdd(int failCount, int successCount) => '$failCount person(s) failed to be added. $successCount succeeded.';
  @override
  String personsAddedSuccessfully(int successCount) => '$successCount person(s) added to daily table successfully!';
  @override
  String personAlreadyInCategoryOpen(String name) => '$name is already in the "Open" category for this day and cannot be added again.';
  @override
  String personsAlreadyInCategoryOpen(int count, String names) => '$count person(s) could not be added because they are already in the "Open" category for this day:\n\n$names';

  // For year_stats_page.dart
  @override
  String summaryForWeeks(int weekCount) => 'Summary for $weekCount weeks';
  @override
  String get categoryAbbreviation => 'Cat.';
  @override
  String get average => 'Avg.';

  // For weekly_report_page.dart
  @override
  String get selectAWeek => 'Select a week';
  @override
  String selectAWeekWithCount(int count) => 'Select a week ($count)';
  @override
  String get noWeeklyEntriesFound => 'No weekly entries found.';
  @override
  String get showWeeksWithDataTooltip => 'Show weeks with data';
  @override
  String get selectWeekHelpText => 'Select the start of the week (Monday)';
  @override
  String get noDataForThisWeek => 'No data for this week';
  @override
  String get weeksWithData => 'Weeks with Data';
  @override
  String get excludeFromYearReport => 'Exclude from year report';
  @override
  String get includeInYearReport => 'Include in year report';
  @override
  String get migrationBgAbbreviation => 'Migration Bg.';
  @override
  String get totalVisitors => 'Total Visitors';

  // For debug menu
  @override
  String get debugSettings => 'Debug Settings';
  @override
  String get settingsJsonContents => 'Settings.json Contents';
  @override
  String get copyToClipboard => 'Copy to clipboard';
  @override
  String get settingsCopiedToClipboard => 'Settings copied to clipboard';
  @override
  String get settingsFileNotFound => 'Settings file does not exist';
  @override
  String get errorReadingSettingsFile => 'Error reading settings file';
  @override
  String get debugMenuDescription => 'This shows the current contents of the app\'s settings.json file.';

  // Database connection handling
  @override
  String get databaseConnectionLost => 'Database Connection Lost';
  
  @override
  String get databaseConnectionErrorMessage => 'The database connection has been lost. This might happen if the database file was moved or deleted. You will be redirected to reconnect.';
  
  @override
  String get ok => 'OK';

  @override
  String get retry => 'Retry';
  @override
  String get createNew => 'Create New';
  @override
  String get failedToCreateNewDatabase => 'Failed to create new database';

  // Chart dialog localizations
  @override
  String get statistics => 'Statistics';
  @override
  String get close => 'Close';
  @override
  String get noDataToDisplayInChart => 'No data to display in chart';

  // Year change handling
  @override
  String get yearChangeDetected => 'Year Change Detected';
  @override
  String get yearChangeMessage => 'A new year has started. Would you like to create a new database for this year or continue with the current one?';
  @override
  String get createNewDatabase => 'Create New Database';
  @override
  String get continueCurrent => 'Continue Current';
  @override
  String get later => 'Later';
  @override
  String get newYearAvailable => 'New Database for new year available';
  @override
  String get tapToCreateNewYearDatabase => 'Tap to create new year database';

  @override
  String get saveDatabaseAs => 'Save Database As...';
  @override
  String get databaseSavedSuccessfully => 'Database saved successfully.';
  @override
  String get returnToMainDatabase => 'Return to Main Database';
  @override
  String get loading => 'Loading...';

  @override
  String get withAbbreviation => 'w.';

  @override
  String get withoutAbbreviation => 'wo.';

  @override
  String confirmBulkDelete(int count) => 'Are you sure you want to delete all entries for $count selected people on this day?';

  @override
  String peopleEntriesDeleted(int count) => "$count people's entries deleted.";

  // For settings page recalibration
  @override
  String get confirmAction => 'Confirm Action';
  @override
  String get recalibrateConfirm => 'This will delete all weekly report data and rebuild it from daily logs. This can fix inconsistencies but may take a moment. Are you sure?';
  @override
  String get proceed => 'Proceed';
  @override
  String get recalibrating => 'Recalibrating data...';
  @override
  String get recalibrationSuccess => 'Data recalibrated successfully!';
  @override
  String get recalibrationFailed => 'Recalibration failed';
  @override
  String get recalibrateData => 'Recalibrate Weekly Data';
  @override
  String get recalibrateDataDesc => 'Recalculates all weekly totals from daily logs to fix discrepancies.';
  @override
  String get databaseNotConnected => 'Database not connected. Cannot perform this action.';

  @override
  String personWithIdNotFound(int id) => 'Error: A person with ID $id could not be found in the database.';

  @override
  String personNamedAlreadyExists(String name) => 'A person named "$name" already exists. Please choose a different name.';

  @override
  String get selectDatabase => 'Select a Database';
  @override
  String errorLoadingFiles(String error) => 'Error loading files: $error';
  @override
  String get noDbFilesFound => 'No .db files found in the \'Documents/MyAppDatabases\' directory.';
  @override
  String get currentlyLoaded => 'Currently loaded';

  @override
  String get settingsErrorTitle => 'Critical Settings Error';
  @override
  String get settingsErrorDirectory => 'Could not access the application storage directory. Please check app permissions.';
  @override
  String get settingsErrorFile => 'The settings file is missing or corrupted. Please try reinstalling the application.';
  @override
  String settingsErrorKey(String key) => 'A critical setting ("$key") is missing from the settings file. Please try reinstalling the application.';

  // missing keys for help page
  @override
  String get help => 'Help';

  @override
  String get openUserManual => 'Open User Manual';

  @override
  String get externalPdfAppHint => 'Opens with an external PDF app (e.g., Google PDF Viewer).';

  @override
  String get failedToOpenPdf => 'Failed to open PDF.';

  @override
  String getAppsVerision(String version) => "Version number $version";
}
