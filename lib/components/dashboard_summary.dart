


import 'package:app_inventario/components/classes.dart';
import 'package:flutter/material.dart';

class DashboardSummary extends StatelessWidget {
  final List<Product> products;

  const DashboardSummary({Key? key, required this.products}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = products.length;
    final totalQuantity = products.fold<int>(0, (sum, p) => sum + p.quantity);
    final expired = products.where((p) => p.isExpired).length;
    final nearExpiry = products.where((p) => p.isNearExpiry).length;
    final groups = products.map((p) => p.compatibilityGroup).toSet();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Wrap(
            runSpacing: 8,
            spacing: 16,
            children: [
              _infoBox('Totale', '$total prodotti'),
              _infoBox('Quantità totale', '$totalQuantity'),
              _infoBox('Scaduti', '$expired', color: Colors.red),
              _infoBox('In scadenza', '$nearExpiry', color: Colors.orange),
              _infoBox('Gruppi', groups.join(', ')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBox(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color?.withOpacity(0.60) ?? Colors.blue.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                fontSize: 14,
                color: color ?? Colors.black87,
              )),
        ],
      ),
    );
  }
}

