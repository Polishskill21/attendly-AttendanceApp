/// Base class for all database-related exceptions.
abstract class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => message;
}

class DatabaseNotReadyException implements Exception {
  const DatabaseNotReadyException();
  @override
  String toString() => "Database is currently transitioning or not open.";
}

/// Thrown when an operation is attempted on a person that does not exist.
class PersonNotFoundException extends DatabaseException {
  final int id;
  PersonNotFoundException(this.id) : super("Person with ID $id not found.");
}

/// Thrown when attempting to create a person that already exists.
class DuplicatePersonException extends DatabaseException {
  final String name;
  DuplicatePersonException(this.name) : super("A person named '$name' already exists.");
}

/// Thrown when attempting to create a daily entry that already exists for a person.
class DuplicateDailyEntryException extends DatabaseException {
  DuplicateDailyEntryException() : super("This person already has a daily entry of this type.");
}

/// Thrown when a specific daily entry record cannot be found for deletion or update.
class EntryNotFoundException extends DatabaseException {
  final int recordID;
  final int personID;
  final DateTime date;
  EntryNotFoundException(this.recordID, this.personID, this.date) : super("Daily entry with Record ID: $recordID, Person ID: $personID and date: ${date.toString()} could not found.");
}

/// Thrown when a general database operation fails.
class DatabaseOperationException extends DatabaseException {
  final Exception? originalException;
  final StackTrace? stackTrace;

  DatabaseOperationException(super.message, {this.originalException, this.stackTrace});

  @override
  String toString() {
    if (originalException != null) {
      return "Database Operation Failed: $message\n--- Original Exception ---\n$originalException";
    }
    return "Database Operation Failed: $message";
  }
}

class DbConnectionException extends DatabaseException {
  DbConnectionException(super.message);
  
  @override
  String toString() => 'Database Connection Error: $message';
}

class DatabaseFailedInit extends DatabaseException {
  DatabaseFailedInit(super.message);

  @override
  String toString() => 'Error: $message';
}