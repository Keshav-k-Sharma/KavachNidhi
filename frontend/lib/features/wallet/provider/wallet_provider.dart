import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet_balance.dart';
import '../models/wallet_transaction.dart';

class WalletState {
  final WalletBalance balance;
  final List<WalletTransaction> transactions;

  WalletState({
    required this.balance,
    required this.transactions,
  });
}

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier()
      : super(WalletState(
          balance: WalletBalance(amount: 0.0, currency: "INR"),
          transactions: [],
        ));

  void addTransaction(WalletTransaction tx) {
    state = WalletState(
      balance: WalletBalance(
        amount: state.balance.amount + (tx.type == "credit" ? tx.amount : -tx.amount),
        currency: state.balance.currency,
      ),
      transactions: [...state.transactions, tx],
    );
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>(
  (ref) => WalletNotifier(),
);