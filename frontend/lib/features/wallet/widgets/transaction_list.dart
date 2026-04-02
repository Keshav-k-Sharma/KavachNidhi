import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/wallet_provider.dart';

class TransactionList extends ConsumerWidget {
  const TransactionList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(walletProvider).transactions;

    if (transactions.isEmpty) {
      return const Center(child: Text("No transactions yet"));
    }

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return ListTile(
          leading: Icon(
            tx.type == "credit" ? Icons.arrow_downward : Icons.arrow_upward,
            color: tx.type == "credit" ? Colors.green : Colors.red,
          ),
          title: Text(tx.description),
          subtitle: Text(tx.date.toIso8601String()),
          trailing: Text("${tx.amount}"),
        );
      },
    );
  }
}