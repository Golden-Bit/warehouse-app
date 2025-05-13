import 'dart:io';

import 'package:app_inventario/components/classes.dart';
import 'package:app_inventario/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'package:app_inventario/databases_manager/database_service.dart';
import 'dart:html' as html;       // per web
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Classe di dettaglio prodotto come StatefulWidget
class ProductDetailPage extends StatefulWidget {
  final Product product;
  final List<Loan> loans;

  const ProductDetailPage({
    Key? key,
    required this.product,
    required this.loans,
  }) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}
class _ProductDetailPageState extends State<ProductDetailPage> {
  // Funzione per formattare una data nel formato dd/MM/yyyy
  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  // Costruisce la lista dei movimenti (prestiti) relativi al prodotto
  List<Widget> _buildLoanHistory(BuildContext context, Product product) {
    final allLoans =
        context.findAncestorStateOfType<ProductListPageState>()?.loans ?? [];
    final productLoans = allLoans
        .where((loan) => loan.casCode == product.casCode)
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    if (productLoans.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Nessun prestito registrato.'),
        )
      ];
    }

    return productLoans.map((loan) {
      final start = _formatDate(loan.startDate);
      final due = _formatDate(loan.dueDate);
      final status = loan.isReturned
          ? 'Restituito il ${_formatDate(loan.returnDate!)}'
          : 'Da restituire entro $due';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          '${loan.person} → ${loan.quantity} pz preso il $start, $status',
          style: const TextStyle(fontSize: 14),
        ),
      );
    }).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {});
  }

Future<void> _viewPdf() async {
  if (widget.product.sdsFileId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nessuna scheda disponibile')),
    );
    return;
  }

  final token = await AuthSession.token;
  // recupera il documento
  final docs = await DatabaseService()
    .fetchCollectionData(
      '${AuthSession.username}-database',
      'files',
      token!
    );
  final fileDoc = docs.firstWhere((d) => d['fileId'] == widget.product.sdsFileId);

  final String b64 = fileDoc['data'];
  final bytes = base64Decode(b64);

  if (kIsWeb) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  } else {
    // salva temporaneamente e apri con url_launcher
    final dir = (await getTemporaryDirectory()).path;
    final file = File('$dir/${fileDoc['filename']}');
    await file.writeAsBytes(bytes);
    launchUrl(Uri.file(file.path), mode: LaunchMode.externalApplication);
  }
}


  @override
  Widget build(BuildContext context) {
    String expiryDate = "${widget.product.expiryDate.toLocal()}".split(' ')[0];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Aggiorna movimenti',
            onPressed: () {
              setState(() {
                // Richiama setState per aggiornare i dati. La logica di aggiornamento potrà essere ampliata in base alle esigenze.
              });
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ✨ Card riassuntiva
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.product.name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('CAS: ${widget.product.casCode}'),
                  Text('Scadenza: $expiryDate'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (widget.product.isExpired)
                        Icon(Icons.error,
                            color: Theme.of(context).colorScheme.error)
                      else if (widget.product.isNearExpiry)
                        Icon(Icons.warning, color: Colors.orange)
                      else
                        Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        widget.product.isExpired
                            ? '❌ Scaduto'
                            : widget.product.isNearExpiry
                                ? '⚠️ In scadenza'
                                : '✅ Valido',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.product.isExpired
                              ? Theme.of(context).colorScheme.error
                              : widget.product.isNearExpiry
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Quantità: ${widget.product.quantity}'),
                  Text('Compatibilità: ${widget.product.compatibilityGroup}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 📄 Bottone PDF
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Visualizza Scheda di Sicurezza (PDF)'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
            onPressed: _viewPdf,
          ),

          const SizedBox(height: 24),

// 📑 Titolo movimenti
          const Text(
            '📑 Movimenti del prodotto',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Divider(),

// 🔄 Lista dinamica dei prestiti filtrata da widget.loans
          Builder(builder: (_) {
            final productLoans = widget.loans
                .where((l) => l.casCode == widget.product.casCode)
                .toList();
            if (productLoans.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Nessun prestito registrato.'),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: productLoans.length,
              itemBuilder: (_, i) {
                final loan = productLoans[i];
                return ListTile(
                  leading: Icon(
                    loan.isReturned
                        ? Icons.assignment_turned_in
                        : Icons.assignment,
                    color: loan.isReturned ? Colors.green : Colors.orange,
                  ),
                  title: Text('${loan.person} (${loan.quantity} pz)'),
                  subtitle: Text(
                    loan.isReturned
                        ? 'Restituito il ${_formatDate(loan.returnDate!)}'
                        : 'Prestato il ${_formatDate(loan.startDate)}\nScadenza: ${_formatDate(loan.dueDate)}',
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

