


// Costruisce la lista dei movimenti relativi al prodotto
import 'dart:io';

import 'package:app_inventario/components/classes.dart';
import 'package:app_inventario/main.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// timezone data + API duo
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:html' as html;

List<Widget> _buildLoanHistory(BuildContext context, Product product) {
  // Trova la lista dei prestiti dall'ancestor _ProductListPageState
  final allLoans =
      context.findAncestorStateOfType<ProductListPageState>()?.loans ?? [];

  // Filtra i prestiti che corrispondono al CAS del prodotto
  final productLoans = allLoans
      .where((loan) => loan.casCode == product.casCode)
      .toList()
    ..sort((a, b) => b.startDate.compareTo(a.startDate));
  // Ordina i prestiti dalla data più recente alla più vecchia

  if (productLoans.isEmpty) {
    return [const Text('Nessun prestito registrato.')];
  }

  // Mappa ogni prestito in un widget di testo
  return productLoans.map((loan) {
    // Se returnDate != null => restituito
    final dateStr = loan.returnDate != null
        ? '→ Restituito il ${_formatDate(loan.returnDate!)}'
        : '→ Prestato il ${_formatDate(loan.startDate)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text('${loan.person} $dateStr'),
    );
  }).toList();
}


// Formatta la data in formato dd/MM/yyyy
String _formatDate(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}



final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();



Future<void> scheduleLoanReturnNotification(Loan loan) async {
  final now = DateTime.now();
  // Se la data di scadenza è già passata, non schedulare la notifica
  if (loan.dueDate.isBefore(now)) return;

  // Pianifica la notifica (ad esempio 1 ora prima della scadenza)
  final scheduledTime =
      tz.TZDateTime.from(loan.dueDate.subtract(Duration(hours: 1)), tz.local);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    loan.hashCode, // Usa l'hash del prestito come ID univoco
    'Promemoria restituzione',
    '${loan.productName} (${loan.quantity}) prestato a ${loan.person} scadrà il ${loan.dueDate.toLocal().toString().split(' ')[0]}',
    scheduledTime,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'loan_channel',
        'Notifiche Prestiti',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    androidAllowWhileIdle: true,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}


Future<void> exportStatisticsToExcel(
    BuildContext context, List<Product> products, List<Loan> loans) async {
  final excel = Excel.createExcel();

  // Riepilogo
  final sheet = excel['Statistiche'];
  final expired = products.where((p) => p.isExpired).length;
  final nearExpiry = products.where((p) => p.isNearExpiry).length;
  final totalQty = products.fold<int>(0, (sum, p) => sum + p.quantity);
  final groups = products.map((p) => p.compatibilityGroup).toSet().join(', ');

  sheet.appendRow([
    'Totale Prodotti',
    'Quantità Totale',
    'Scaduti',
    'In Scadenza',
    'Gruppi Compatibilità'
  ]);
  sheet.appendRow([products.length, totalQty, expired, nearExpiry, groups]);

  // Prestiti
  final loanSheet = excel['Prestiti'];
  loanSheet.appendRow([
    'Prodotto',
    'CAS',
    'Persona',
    'Data Prestito',
    'Data Restituzione',
    'Stato',
  ]);

  for (final loan in loans) {
    loanSheet.appendRow([
      loan.productName,
      loan.casCode,
      loan.person,
      loan.startDate.toIso8601String().split('T').first,
      loan.returnDate?.toIso8601String().split('T').first ?? '',
      loan.isReturned ? 'Restituito' : 'Attivo',
    ]);
  }

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/statistiche_magazzino.xlsx');
  final fileBytes = excel.encode();

  if (fileBytes != null) {
    await file.writeAsBytes(fileBytes);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Statistiche esportate in Excel'),
        action: SnackBarAction(
          label: 'Condividi',
          onPressed: () {
            Share.shareXFiles(
              [XFile(file.path)],
              text: 'Statistiche magazzino chimico',
            );
          },
        ),
      ),
    );
  }
}



