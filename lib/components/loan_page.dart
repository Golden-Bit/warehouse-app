

import 'package:app_inventario/components/classes.dart';
import 'package:app_inventario/components/utils.dart';
import 'package:app_inventario/main.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class LoanPage extends StatefulWidget {
  final List<Loan> loans;
  final List<Product> products;          // ← NEW
  final Function(Loan loan) onNewLoan;
  final Function(Loan loan) onReturn;
  final bool readOnly;

  const LoanPage({
    super.key,
    required this.loans,
    required this.products,             // ← NEW
    required this.onNewLoan,
    required this.onReturn,
    required this.readOnly,
  });

  @override
  State<LoanPage> createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  List<Loan> get _activeLoans =>
      widget.loans.where((l) => !l.isReturned).toList();
  List<Loan> get _returnedLoans =>
      widget.loans.where((l) => l.isReturned).toList();

void _showNewLoanDialog() {
  // ➊ lista prodotti aggiornata in tempo reale
  final productList = widget.products;

  showDialog(
    context: context,
    builder: (_) {
      // ➋ stato locale del dialog
      String? selectedCas;
      String borrower = '';
      DateTime dueDate = DateTime.now().add(const Duration(days: 7));
      int qty = 1;
      final qtyCtrl = TextEditingController(text: '1');

      return StatefulBuilder(
        builder: (ctx, setLocalState) {
          // solo prodotti con disponibilità > 0
          final available = productList.where((p) => p.quantity > 0).toList();

          return AlertDialog(
            title: const Text('Nuovo prestito'),
            content: SizedBox(
              // ➌ altezza fissa e contenuto scrollabile
              height: 320,
              width: 330,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ‣ selezione prodotto
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Prodotto'),
                      items: available.map((p) => DropdownMenuItem(
                            value: p.casCode,
                            child: Text('${p.name} (${p.casCode})'),
                          )).toList(),
                      onChanged: (v) => setLocalState(() => selectedCas = v),
                    ),
                    const SizedBox(height: 12),

                    // ‣ nome del richiedente
                    TextField(
                      decoration:
                          const InputDecoration(labelText: 'Chi prende il prodotto'),
                      onChanged: (v) => borrower = v,
                    ),
                    const SizedBox(height: 12),

                    // ‣ quantità richiesta
                    TextField(
                      controller: qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          signed: false, decimal: false),
                      decoration: const InputDecoration(labelText: 'Quantità'),
                      onChanged: (v) {
                        final parsed = int.tryParse(v) ?? 0;
                        setLocalState(() => qty = parsed);
                      },
                    ),
                    const SizedBox(height: 12),

                    // ‣ data di scadenza prestito
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Scadenza: '
                            '${dueDate.day.toString().padLeft(2, '0')}/'
                            '${dueDate.month.toString().padLeft(2, '0')}/'
                            '${dueDate.year}',
                          ),
                        ),
                        TextButton(
                          child: const Text('Cambia data'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: dueDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setLocalState(() => dueDate = picked);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                child: const Text('Registra'),
                onPressed: () {
                  final product = available
                      .firstWhereOrNull((p) => p.casCode == selectedCas);

                  // ➍ validazioni complete
                  if (product == null ||
                      borrower.trim().isEmpty ||
                      qty <= 0 ||
                      qty > product.quantity) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Dati non validi o quantità non disponibile')),
                    );
                    return;
                  }

                  // ➎ creazione prestito
                  final loan = Loan(
                    productName: product.name,
                    casCode: product.casCode,
                    person: borrower.trim(),
                    startDate: DateTime.now(),
                    dueDate: dueDate,
                    quantity: qty,
                  );

                  // ➏ aggiorna giacenza e persiste
                  setState(() => product.quantity -= qty);
                  widget.onNewLoan(loan); // salva già i magazzini
                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} prestato a $borrower')),
                  );
                },
              ),
            ],
          );
        },
      );
    },
  );
}

@override
void dispose() {
  super.dispose();
}


  List<Product> _getAllProducts() {
    final state = context.findAncestorStateOfType<ProductListPageState>();
    return state?.products ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prestiti Prodotti'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Attivi'),
            Tab(text: 'Storico'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoanList(_activeLoans, canReturn: !widget.readOnly),
          _buildLoanList(_returnedLoans),
        ],
      ),
      floatingActionButton: widget.readOnly ? null : FloatingActionButton(
        onPressed: _showNewLoanDialog,
        tooltip: 'Nuovo Prestito',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoanList(List<Loan> loans, {bool canReturn = false}) {
    if (loans.isEmpty) {
      return const Center(child: Text('Nessun prestito registrato.'));
    }

    return ListView.builder(
      itemCount: loans.length,
      itemBuilder: (_, index) {
        final loan = loans[index];
        final subtitle = loan.isReturned
            ? 'Restituito il ${_formatDate(loan.returnDate!)}'
            : 'Iniziato il ${_formatDate(loan.startDate)}';

        return ListTile(
          leading: const Icon(Icons.assignment_outlined),
          title: Text(
              '${loan.productName} → ${loan.person} (Quantità: ${loan.quantity})'),
          subtitle: Text(
            loan.isReturned
                ? 'Restituito il ${_formatDate(loan.returnDate!)}'
                : 'Iniziato il ${_formatDate(loan.startDate)} - Scadenza: ${_formatDate(loan.dueDate)}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canReturn)
                IconButton(
                  icon: const Icon(Icons.reply, color: Colors.green),
                  tooltip: 'Restituisci',
                  onPressed: () {
                    final updatedLoan = Loan(
                      productName: loan.productName,
                      casCode: loan.casCode,
                      person: loan.person,
                      startDate: loan.startDate,
                      dueDate: loan.dueDate,
                      quantity: loan.quantity,
                      returnDate: DateTime.now(), // Imposta come restituito
                    );
                                      // 2️⃣ setState per ricostruire subito la UI
                  setState(() {
                    widget.onReturn(updatedLoan);
                  });
                  },
                ),
              // Aggiungi pulsante "Rinnova" se il prestito è attivo ed è prossimo alla scadenza (entro 2 giorni)
              if (!loan.isReturned &&
                  loan.dueDate.isBefore(DateTime.now().add(Duration(days: 2))))
                IconButton(
                  icon: const Icon(Icons.update, color: Colors.orange),
                  tooltip: 'Rinnova prestito',
                  onPressed: () async {
                    final newDueDate = await showDatePicker(
                      context: context,
                      initialDate: loan.dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (newDueDate != null) {
                      // Nel rinnovo, il prestito rimane attivo, quindi non si segna come restituito
                      final renewedLoan = Loan(
                        productName: loan.productName,
                        casCode: loan.casCode,
                        person: loan.person,
                        startDate: loan.startDate,
                        dueDate: newDueDate,
                        quantity: loan.quantity,
                        returnDate: null, // Prestito rinnovato e ancora attivo
                      );
                      widget.onReturn(renewedLoan);
                      // Riprogramma la notifica per il nuovo termine
                      scheduleLoanReturnNotification(renewedLoan);
                    }
                  },
                ),
              /*IconButton(
                icon: const Icon(Icons.cancel, color: Colors.redAccent),
                tooltip: 'Annulla prestito',
                onPressed: () {
                  _confirmDeleteLoan(loan);
                },
              ),*/
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteLoan(Loan loan) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Annulla prestito'),
        content: const Text('Sei sicuro di voler annullare questo prestito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
TextButton(
  onPressed: () {
    // 1️⃣ Chiudi il dialog
    Navigator.pop(context);

    // 2️⃣ Crea un “ritorno” identico a come fa il tasto Restituisci
    final returnedLoan = Loan(
      productName: loan.productName,
      casCode: loan.casCode,
      person: loan.person,
      startDate: loan.startDate,
      dueDate: loan.dueDate,
      quantity: loan.quantity,
      returnDate: DateTime.now(), // Marca come restituito ora
    );

    // 3️⃣ Aggiorna stato UI e DB mediante il callback onReturn
    setState(() {
      widget.onReturn(returnedLoan);
    });

    // 4️⃣ Notifica all’utente
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Prestito di ${loan.productName} annullato')),
    );
  },
  child: const Text('Conferma', style: TextStyle(color: Colors.red)),
),

        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}