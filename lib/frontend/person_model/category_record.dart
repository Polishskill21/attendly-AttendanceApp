class CategoryRecord {
  final int recordId;
  final int personId;
  final String? personName; // Added for convenience
  final String date;
  final String category;
  final String? comment;

  CategoryRecord({
    required this.recordId,
    required this.personId,
    this.personName,
    required this.date,
    required this.category,
    this.comment,
  });

  // Factory constructor to create a CategoryRecord from a map
  factory CategoryRecord.fromMap(Map<String, dynamic> map) {
    return CategoryRecord(
      recordId: map['record_id'],
      personId: map['id'],
      personName: map['name'], 
      date: map['dates'],
      category: map['category'],
      comment: map['description'],
    );
  }
}

