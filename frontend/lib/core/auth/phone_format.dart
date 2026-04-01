/// Converts a 10-digit Indian mobile (digits only) to E.164 (+91…).
String indiaMobileToE164(String tenDigits) {
  final String d = tenDigits.trim();
  return '+91$d';
}
