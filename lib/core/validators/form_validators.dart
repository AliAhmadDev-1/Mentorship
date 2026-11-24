class FormValidators {
  const FormValidators._();

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    if (!text.contains('@') || !text.split('@').last.contains('.')) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password is required';
    if (text.length < 8) return 'Use at least 8 characters';
    if (!RegExp('[A-Z]').hasMatch(text)) return 'Add one uppercase letter';
    if (!RegExp('[0-9]').hasMatch(text)) return 'Add one number';
    return null;
  }

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Name is required';
    if (text.length < 2) return 'Use at least 2 characters';
    return null;
  }
}
