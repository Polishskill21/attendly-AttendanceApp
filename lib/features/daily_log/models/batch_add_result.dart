class BatchAddResult {
  final int successCount;
  final int failCount;
  final List<String> duplicateNames;
  final List<String> errorMessages;

  BatchAddResult({
    required this.successCount,
    required this.failCount,
    required this.duplicateNames,
    required this.errorMessages,
  });

  bool get hasErrors => errorMessages.isNotEmpty;
  bool get hasDuplicates => duplicateNames.isNotEmpty;
  bool get allFailed => successCount == 0 && (failCount > 0 || hasDuplicates);
}