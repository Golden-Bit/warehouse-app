

import 'package:app_inventario/components/add_product_page.dart';
import 'package:app_inventario/components/classes.dart';
import 'package:app_inventario/components/product_detail_page.dart';
import 'package:app_inventario/main.dart';
import 'package:flutter/material.dart';

/// Card prodotto
class ProductCard extends StatelessWidget {
  final Product product;
  final void Function(Product product, Loan loan)?
      onLoan; // <-- NUOVO parametro

  const ProductCard({Key? key, required this.product, this.onLoan})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Imposta colore di sfondo in base allo stato del prodotto
    Color? bgColor;
    final colors = Theme.of(context).colorScheme;
    if (product.isExpired) {
      bgColor = colors.errorContainer;
    } else if (product.isNearExpiry) {
      bgColor = colors.primaryContainer;
    }
    return Card(
      margin: const EdgeInsets.all(8.0),
      color: bgColor,
      child: ListTile(
        title: Text(product.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CAS: ${product.casCode}'),
            Text('Quantità: ${product.quantity}'),
            Text('Compatibilità: ${product.compatibilityGroup}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            product.isExpired
                ? const Icon(Icons.error, color: Colors.red)
                : product.isNearExpiry
                    ? const Icon(Icons.warning, color: Colors.orange)
                    : const Icon(Icons.check_circle, color: Colors.green),
            PopupMenuButton<String>(
              onSelected: (value) async {
                final state =
                    context.findAncestorStateOfType<ProductListPageState>();
                if (value == 'loan') {
                  // ---- MODIFICA: Usa il callback onLoan per gestire il prestito
                  String person = '';
                  int loanQuantity = 1;
                  DateTime selectedDueDate = DateTime.now()
                      .add(Duration(days: 7)); // default: 7 giorni dopo
                  showDialog(
                    context: context,
                    builder: (_) => StatefulBuilder(
                      builder: (context, setStateDialog) {
                        return AlertDialog(
                          title: const Text('Prestito prodotto'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                    labelText: 'Destinatario'),
                                onChanged: (val) => person = val,
                              ),
                              TextField(
                                decoration: const InputDecoration(
                                    labelText: 'Quantità da prestare'),
                                keyboardType: TextInputType.number,
                                onChanged: (val) =>
                                    loanQuantity = int.tryParse(val) ?? 1,
                              ),
                              Row(
                                children: [
                                  const Text('Scadenza prestito:'),
                                  const SizedBox(width: 8),
                                  Text('${selectedDueDate.toLocal()}'
                                      .split(' ')[0]),
                                  IconButton(
                                    icon: const Icon(Icons.calendar_today),
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: selectedDueDate,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(2100),
                                      );
                                      if (picked != null) {
                                        setStateDialog(() {
                                          selectedDueDate = picked;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annulla'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (person.isNotEmpty &&
                                    loanQuantity > 0 &&
                                    loanQuantity <= product.quantity) {
                                  final loan = Loan(
                                    productName: product.name,
                                    casCode: product.casCode,
                                    person: person,
                                    startDate: DateTime.now(),
                                    dueDate: selectedDueDate,
                                    quantity: loanQuantity,
                                  );
                                  // Chiamata al callback per registrare il prestito
                                  if (onLoan != null) {
                                    onLoan!(product, loan);
                                  }
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            '${product.name} ($loanQuantity) prestato a $person')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Verifica i dati inseriti o la quantità disponibile')),
                                  );
                                }
                              },
                              child: const Text('Conferma'),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                } else if (value == 'delete') {
                  state?.removeProduct(product);
                } else if (value == 'edit') {
                  final updatedProduct = await Navigator.push<Product?>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddProductPage(productToEdit: product),
                    ),
                  );
                  if (updatedProduct != null) {
                    state?.updateProduct(product, updatedProduct);
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Modifica')),
                const PopupMenuItem(value: 'delete', child: Text('Elimina')),
                const PopupMenuItem(
                  value: 'loan',
                  child: Text('Presta'),
                ),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(
                product: product,
                loans: context
                    .findAncestorStateOfType<ProductListPageState>()!
                    .loans, // ← find and pass the loans
              ),
            ),
          );
        },
      ),
    );
  }
}