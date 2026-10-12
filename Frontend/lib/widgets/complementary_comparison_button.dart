import 'package:flutter/material.dart';
import 'package:project/complementary_comparison_page.dart';

class ComplementaryComparisonButton extends StatelessWidget {
  final String productId;
  final String productName;
  final String category;
  final List<String> skinTypes;
  final String interfaceAsiss;

  const ComplementaryComparisonButton({
    Key? key,
    required this.productId,
    required this.productName,
    required this.category,
    required this.skinTypes,
    required this.interfaceAsiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComplementaryComparisonPage(
                productId: productId,
                productName: productName,
                category: category,
                skinTypes: skinTypes,
                interfaceAsiss: interfaceAsiss,
              ),
            ),
          );
        },
        icon: const Icon(Icons.compare_arrows, size: 20),
        label: const Text(
          'Compare Complementary Products',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
