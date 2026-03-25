class EmailValidator {
  static final RegExp _localPartPattern =
      RegExp(r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+$");
  static final RegExp _domainLabelPattern = RegExp(r'^[A-Za-z0-9-]+$');
  static final RegExp _tldPattern = RegExp(r'^[A-Za-z]{2,63}$');

  static bool isValid(String value) {
    final email = value.trim().toLowerCase();

    if (email.isEmpty || email.length > 254 || email.contains(' ')) {
      return false;
    }

    final List<String> parts = email.split('@');
    if (parts.length != 2) {
      return false;
    }

    final String localPart = parts[0];
    final String domain = parts[1];

    if (localPart.isEmpty ||
        domain.isEmpty ||
        localPart.length > 64 ||
        localPart.startsWith('.') ||
        localPart.endsWith('.') ||
        localPart.contains('..') ||
        !_localPartPattern.hasMatch(localPart)) {
      return false;
    }

    if (domain.startsWith('.') ||
        domain.endsWith('.') ||
        domain.contains('..')) {
      return false;
    }

    final List<String> labels = domain.split('.');
    if (labels.length < 2) {
      return false;
    }

    for (final String label in labels) {
      if (label.isEmpty ||
          label.length > 63 ||
          label.startsWith('-') ||
          label.endsWith('-') ||
          !_domainLabelPattern.hasMatch(label)) {
        return false;
      }
    }

    return _tldPattern.hasMatch(labels.last);
  }
}
