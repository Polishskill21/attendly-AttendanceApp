/// Base class for all database-related exceptions.
abstract class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => message;
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
