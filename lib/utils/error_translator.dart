class ErrorTranslator {
  static String translate(dynamic error) {
    String message = error.toString().toLowerCase();
    
    if (message.contains('user-not-found')) {
      return "We couldn't find an account with that email. Want to sign up instead?";
    } else if (message.contains('wrong-password') || message.contains('invalid-credential')) {
      return "That password doesn't look right. Give it another shot!";
    } else if (message.contains('email-already-in-use')) {
      return "This email is already registered. Try signing in!";
    } else if (message.contains('network-request-failed')) {
      return "Looks like you're offline. Check your internet connection!";
    } else if (message.contains('weak-password')) {
      return "That password is a bit too easy to guess. Try making it at least 6 characters!";
    } else if (message.contains('missing-email')) {
      return "Please enter your email address first.";
    } else if (message.contains('invalid-email')) {
      return "That doesn't look like a valid email. Check for typos!";
    } else if (message.contains('too-many-requests')) {
      return "Slow down! You've tried too many times. Wait a moment and try again.";
    }

    // Default friendly message if we don't recognize the code
    return "Oops! Something went wrong. Please try again in a moment.";
  }
}
