

import 'dart:convert';
import 'dart:io';

import 'package:app_inventario/components/classes.dart';
import 'package:app_inventario/components/utils.dart';
import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class StatisticsPage extends StatelessWidget {
  final List<Product> products;
  final List<Loan> loans;

  const StatisticsPage({
    super.key,
    required this.products,
    required this.loans,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiche Magazzino'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Esporta Statistiche',
            onPressed: () async {
              try {
                // 1) Intestazioni CSV
                const header =
                    'Totale Prodotti,Quantità Totale,Scaduti,In Scadenza,Gruppi Compatibilità\n';

                // 2) Calcolo valori
                final expiredCount = products.where((p) => p.isExpired).length;
                final nearExpiryCount =
                    products.where((p) => p.isNearExpiry).length;
                final totalQty =
                    products.fold<int>(0, (sum, p) => sum + p.quantity);
                final groups = products
                    .map((p) => p.compatibilityGroup)
                    .toSet()
                    .join('; ');

                // 3) Riga dati (virgolette intorno a "groups" in caso contenga virgole)
                final row = '${products.length},'
                    '$totalQty,'
                    '$expiredCount,'
                    '$nearExpiryCount,'
                    '"$groups"';

                final csvContent = header + row;

                if (kIsWeb) {
                  // — Web: Blob + download
                  final bytes = utf8.encode(csvContent);
                  final blob = html.Blob([bytes], 'text/csv');
                  final url = html.Url.createObjectUrlFromBlob(blob);
                  final anchor = html.AnchorElement(href: url)
                    ..style.display = 'none'
                    ..download = 'statistiche_magazzino.csv';
                  html.document.body!.append(anchor);
                  anchor.click();
                  anchor.remove();
                  html.Url.revokeObjectUrl(url);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download CSV avviato')),
                  );
                } else {
                  // — Mobile/Desktop: salva + condividi
                  final dir = await getApplicationDocumentsDirectory();
                  final path = '${dir.path}/statistiche_magazzino.csv';
                  final file = File(path);
                  await file.writeAsString(csvContent);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Statistiche esportate in CSV'),
                      action: SnackBarAction(
                        label: 'Condividi',
                        onPressed: () {
                          Share.shareXFiles(
                            [XFile(path)],
                            text: 'Statistiche Magazzino Chimico',
                          );
                        },
                      ),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Errore esportazione CSV: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            _buildCompatibilityPieChart(products),
            const SizedBox(height: 24),
            _buildQuantityBarChart(products),
            const SizedBox(height: 24),
            _buildUpcomingExpiries(products),
            _buildLoanStats(loans),
          ],
        ),
      ),
    );
  }

  Widget _buildCompatibilityPieChart(List<Product> products) {
    final Map<String, int> groupCounts = {};

    for (var product in products) {
      final group = product.compatibilityGroup;
      groupCounts[group] = (groupCounts[group] ?? 0) + 1;
    }

    final total = groupCounts.values.fold<int>(0, (sum, count) => sum + count);
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.brown,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              '📊 Gruppi di Compatibilità',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: groupCounts.entries.mapIndexed((i, entry) {
                    final percent =
                        (entry.value / total * 100).toStringAsFixed(1);
                    return PieChartSectionData(
                      color: colors[i % colors.length],
                      value: entry.value.toDouble(),
                      title: '${entry.key}\n$percent%',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityBarChart(List<Product> products) {
    // Prendi i top 5 prodotti per quantità
    final topProducts = products.where((p) => p.quantity > 0).toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    final top = topProducts.take(5).toList();
    final maxQty = top.isNotEmpty
        ? top.map((p) => p.quantity).reduce((a, b) => a > b ? a : b)
        : 1;
    final yInterval = (maxQty / 5).ceil().clamp(1, maxQty);
    final barGroups = top.asMap().entries.map((entry) {
      final index = entry.key;
      final product = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: product.quantity.toDouble(),
            color: AppColors.primary.withOpacity(0.60),
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📦 Quantità per prodotto',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  borderData: FlBorderData(show: false),
                  // Calcolo intervallo Y dinamico: massimo diviso 5 (min 1)

                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: yInterval.toDouble(),
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          // solo numeri interi
                          if (value % yInterval == 0) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < top.length) {
                            final name = top[index].name;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                name.length > 10
                                    ? '${name.substring(0, 10)}...'
                                    : name,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                  ),

                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingExpiries(List<Product> products) {
    final upcoming = products.where((p) => !p.isExpired).toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⏱️ Scadenze più vicine',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (upcoming.isEmpty) const Text('Nessuna scadenza imminente'),
            for (final p in upcoming.take(5))
              Text(
                '${p.name} – ${p.expiryDate.toLocal().toString().split(' ')[0]}',
              ),
          ],
        ),
      ),
    );
  }
}


Widget _buildLoanStats(List<Loan> loans) {
  final active = loans.where((l) => !l.isReturned).length;
  final returned = loans.where((l) => l.isReturned).length;

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📋 Prestiti prodotti',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                sections: [
                  PieChartSectionData(
                    color: Colors.orange,
                    value: active.toDouble(),
                    title: 'Attivi\n$active',
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: Colors.green,
                    value: returned.toDouble(),
                    title: 'Restituiti\n$returned',
                    radius: 60,
                    titleStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}