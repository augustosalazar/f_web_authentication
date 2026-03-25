class RobleException implements Exception {
  final String message;
  final int? statusCode;

  RobleException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
