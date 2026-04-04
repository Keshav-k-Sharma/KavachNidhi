import 'package:flutter/material.dart';
import '../widgets/wallet_card.dart';
import '../widgets/transaction_list.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wallet")),
      body: Column(
        children: const [
          WalletCard(),
          Expanded(child: TransactionList()),
        ],
      ),
    );
  }
}