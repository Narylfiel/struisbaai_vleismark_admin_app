/// Central place for turning raw exceptions into user-friendly messages.
/// Use [friendlyMessage] whenever displaying an error to the user (SnackBar, dialog, _error state).
class ErrorHandler {
  ErrorHandler._();

  /// Returns a short, user-friendly message for a given error.
  /// Handles network, auth, and common server errors; avoids showing raw exception text.
  static String friendlyMessage(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection refused')) {
      return 'No internet connection. Showing cached data where available.';
    }
    if (msg.contains('timeoutexception')) {
      return 'Connection timed out. Please try again.';
    }
    if (msg.contains('401') || msg.contains('unauthorized')) {
      return 'Session expired. Please log in again.';
    }
    if (msg.contains('404')) {
      return 'Data not found.';
    }
    if (msg.contains('500') || msg.contains('server error')) {
      return 'Server error. Please try again later.';
    }
    return 'Something went wrong. Please try again.';
  }
}
