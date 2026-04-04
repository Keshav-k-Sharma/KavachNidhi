class WalletTransaction {
  final String id;
  final String type; // "credit" or "debit"
  final double amount;
  final DateTime date;
  final String description;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
  });
}