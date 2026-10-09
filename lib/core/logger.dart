/// Stub — simple print-based logger.
/// Will be replaced with a structured logger in a later task.
class AppLogger {
  const AppLogger(this._tag);
  final String _tag;

  void info(String message) => print('[$_tag] INFO: $message');
  void warn(String message) => print('[$_tag] WARN: $message');
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    print('[$_tag] ERROR: $message');
    if (error != null) print('  $error');
    if (stackTrace != null) print('  $stackTrace');
  }
}
