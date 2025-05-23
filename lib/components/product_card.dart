import 'package:app_inventario/components/add_product_page.dart';
import 'package:app_inventario/components/classes.dart';
import 'package:app_inventario/components/product_detail_page.dart';
import 'package:app_inventario/main.dart';
import 'package:flutter/material.dart';

/// Card prodotto
class ProductCard extends StatelessWidget {
  /// Dato del prodotto da mostrare
  final Product product;

  /// Callback chiamata quando l’admin registra un prestito
  /// (è `null` se l’utente non è admin → nessuna azione di modifica)
  final void Function(Product product, Loan loan)? onLoan;

  /// Flag che indica se l’utente corrente è amministratore
  final bool isAdmin;

  const ProductCard({
    Key? key,
    required this.product,
    this.onLoan,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /*──────────────────── Colore di sfondo dinamico ────────────────────*/
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
        /*────────────────────── Parte sinistra ───────────────────────*/
        title: Text(product.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CAS: ${product.casCode}'),
            Text('Quantità: ${product.quantity}'),
            Text('Compatibilità: ${product.compatibilityGroup}'),
          ],
        ),

        /*──────────── Colonna destra: stato + (eventuale) menù ────────────*/
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            product.isExpired
                ? const Icon(Icons.error, color: Colors.red)
                : product.isNearExpiry
                    ? const Icon(Icons.warning, color: Colors.orange)
                    : const Icon(Icons.check_circle, color: Colors.green),

            // ▸ Il PopupMenu (“3 puntini”) viene creato solo se admin
            if (isAdmin) _buildAdminMenu(context),
          ],
        ),

        /*─────────────────── Tap → pagina dettagli (sempre) ─────────────────*/
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(
                product: product,
                loans: context
                    .findAncestorStateOfType<ProductListPageState>()!
                    .loans,
              ),
            ),
          );
        },
      ),
    );
  }

  /*────────────────────────── Menù admin ──────────────────────────*/
  Widget _buildAdminMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        final state = context.findAncestorStateOfType<ProductListPageState>();

        switch (value) {
          /*───────────── Prestito ─────────────*/
          case 'loan':
            _showLoanDialog(context);
            break;

          /*──────────── Modifica ──────────────*/
          case 'edit':
            final updated = await Navigator.push<Product?>(
              context,
              MaterialPageRoute(
                builder: (_) => AddProductPage(productToEdit: product),
              ),
            );
            if (updated != null) state?.updateProduct(product, updated);
            break;

          /*──────────── Eliminazione ──────────*/
          case 'delete':
            state?.removeProduct(product);
            break;
        }
      },

      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit',   child: Text('Modifica')),
        PopupMenuItem(value: 'delete', child: Text('Elimina')),
        PopupMenuItem(value: 'loan',   child: Text('Presta')),
      ],
    );
  }

  /*──────────────────── Dialog di prestito ─────────────────────*/
  void _showLoanDialog(BuildContext context) {
    if (onLoan == null) return; // ulteriore sicurezza

    String person = '';
    int qty = 1;
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDlg) {
          return AlertDialog(
            title: const Text('Prestito prodotto'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration:
                      const InputDecoration(labelText: 'Destinatario'),
                  onChanged: (v) => person = v,
                ),
                TextField(
                  decoration:
                      const InputDecoration(labelText: 'Quantità da prestare'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => qty = int.tryParse(v) ?? 1,
                ),
                Row(
                  children: [
                    const Text('Scadenza:'),
                    const SizedBox(width: 8),
                    Text('${dueDate.toLocal()}'.split(' ')[0]),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDlg(() => dueDate = picked);
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
                  if (person.isEmpty ||
                      qty <= 0 ||
                      qty > product.quantity) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Controlla destinatario e quantità disponibile')),
                    );
                    return;
                  }

                  final loan = Loan(
                    productName: product.name,
                    casCode: product.casCode,
                    person: person,
                    startDate: DateTime.now(),
                    dueDate: dueDate,
                    quantity: qty,
                  );
                  onLoan!(product, loan);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('${product.name} ($qty) prestato a $person')),
                  );
                },
                child: const Text('Conferma'),
              ),
            ],
          );
        },
      ),
    );
  }
}
