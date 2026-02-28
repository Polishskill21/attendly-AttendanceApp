import 'dart:io';
import 'package:attendly/data/local/config/database.dart';

abstract interface class IDatabaseManager {
  AppDatabase get databaseConnection;

  Future<bool> checkForYearRollover();

  Future<void> openDatabase({File? file});

  Future<void> createDatabase();

  Future<void> performYearRolloverAndOpen();

  Future<void> closeDatabase();
}