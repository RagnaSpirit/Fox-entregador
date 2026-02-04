import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/util/dimensions.dart';

class ScorePerformanceScreen extends StatelessWidget {
  const ScorePerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Score & Desempenho'),
        backgroundColor: const Color(0xFFFFD400),
        foregroundColor: Colors.black,
      ),
      body: GetBuilder<ProfileController>(
        builder: (controller) {
          final profile = controller.profileModel;
          return Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile?.fName ?? ''} ${profile?.lName ?? ''}'.trim(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFD400)),
                    const SizedBox(width: 6),
                    Text(
                      '${profile?.avgRating?.toStringAsFixed(1) ?? '0.0'} / 5.0',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ScoreMetric(
                  label: 'Entregas concluídas',
                  value: '${profile?.orderCount ?? 0}',
                ),
                _ScoreMetric(
                  label: 'Dias na plataforma',
                  value: '${profile?.memberSinceDays ?? 0}',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScoreMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ScoreMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
