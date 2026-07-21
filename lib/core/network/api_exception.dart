class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final String? errorCode;
  final dynamic details;

  const ApiException({
    this.statusCode,
    required this.message,
    this.errorCode,
    this.details,
  });

  @override
  String toString() => message;
}
