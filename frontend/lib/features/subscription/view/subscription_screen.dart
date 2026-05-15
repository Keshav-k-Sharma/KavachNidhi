import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/subscription_provider.dart';
import '../../../shared/widgets/plan_card.dart';
import '../../../shared/models/subscription_plan.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Your Plan"),
        backgroundColor: const Color(0xFF1A4FBA), // Shield Blue
      ),
      body: ListView.builder(
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          return PlanCard(
            plan: plan,
            onSelect: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfirmationScreen(plan: plan),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ConfirmationScreen extends StatelessWidget {
  final SubscriptionPlan plan;
  const ConfirmationScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Subscription")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("You selected: ${plan.name}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF4A800), // Nidhi Gold
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Subscription confirmed!")),
                );
                Navigator.pop(context);
              },
              child: const Text("Confirm"),
            ),
          ],
        ),
      ),
    );
  }
}