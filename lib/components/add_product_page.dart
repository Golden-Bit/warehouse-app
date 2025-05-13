import 'dart:io';

import 'package:app_inventario/components/classes.dart';
import 'package:app_inventario/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
// in cima al file, con gli altri import
import 'package:path/path.dart' as p;   // per ricavare il nome del file :contentReference[oaicite:0]{index=0}
import 'dart:convert';                        // per base64Encode
import 'package:app_inventario/databases_manager/database_service.dart';
import 'package:uuid/uuid.dart'; 

/// Schermata aggiunta/modifica prodotto
class AddProductPage extends StatefulWidget {
  final Product? productToEdit;

  const AddProductPage({Key? key, this.productToEdit}) : super(key: key);

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  bool _isUploadingPdf = false;      // mostra la “rotella” durante il pick
String? _pickedFileName;           // nome leggibile del PDF
String? _pickedFileId;        // ← memorizza l’_id restituito da Mongo

  Future<bool> _onWillPop() async {
    final current = Product(
      casCode:            _casController.text,
      name:               _nameController.text,
      // ora usiamo fileId anziché path
      sdsPath:            '',
      sdsFileId:          _pickedFileId,
      expiryDate:         _expiryDate,
      quantity:           int.tryParse(_quantityController.text) ?? 0,
      compatibilityGroup: _selectedGroup ?? 'Non specificato',
    );

    final isModified = widget.productToEdit == null ||
        current.name != widget.productToEdit!.name ||
        current.casCode != widget.productToEdit!.casCode ||
        current.sdsPath != widget.productToEdit!.sdsPath ||
        current.sdsFileId != widget.productToEdit!.sdsFileId ||
        current.expiryDate != widget.productToEdit!.expiryDate ||
        current.quantity != widget.productToEdit!.quantity ||
        current.compatibilityGroup != widget.productToEdit!.compatibilityGroup;

    if (!isModified) return true;

    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // non chiudibile toccando fuori
      builder: (_) => AlertDialog(
        // angoli più arrotondati
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 12,
        backgroundColor: theme.colorScheme.surface,
        // padding personalizzati
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        title: Text(
          'Modifiche non salvate',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Sei sicuro di voler tornare indietro? Le modifiche andranno perse.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: const Text('Conferma'),
          ),
        ],
      ),
    );

    return confirm ?? false;
  }

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _casController = TextEditingController();
  final _quantityController = TextEditingController();
  String? _pickedFilePath;
  DateTime _expiryDate = DateTime.now();
  String? _selectedGroup;

  final List<String> _compatibilityOptions = [
    'Acido',
    'Base',
    'Infiammabile',
    'Ossidante',
    'Non specificato',
  ];

@override
void initState() {
  super.initState();
  if (widget.productToEdit != null) {
    _nameController.text      = widget.productToEdit!.name;
    _casController.text       = widget.productToEdit!.casCode;
    _quantityController.text  = widget.productToEdit!.quantity.toString();
    _expiryDate               = widget.productToEdit!.expiryDate;
    _pickedFilePath           = widget.productToEdit!.sdsPath;
    _pickedFileName           = p.basename(_pickedFilePath!);   // NEW
    _selectedGroup            = widget.productToEdit!.compatibilityGroup;
  }
}


  void _submit() {
      if (_formKey.currentState!.validate() &&
      _pickedFilePath != null &&
      _pickedFileName != null) {
      final product = Product(
        casCode: _casController.text,
        name: _nameController.text,
        // Memorizziamo il nostro fileId custom anziché il path
        sdsPath: '',
        sdsFileId: _pickedFileId!,
        expiryDate: _expiryDate,
        quantity: int.tryParse(_quantityController.text) ?? 0,
        compatibilityGroup: _selectedGroup ?? 'Non specificato',
      );
      Navigator.pop(context, product);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compila tutti i campi e carica un PDF')),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.productToEdit == null
                ? 'Nuovo Prodotto'
                : 'Modifica Prodotto',
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Nome prodotto
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(labelText: 'Nome prodotto'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo obbligatorio' : null,
                  ),
                ),

                // Codice CAS
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _casController,
                    decoration: const InputDecoration(labelText: 'Codice CAS'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo obbligatorio' : null,
                  ),
                ),

                // Gruppo di compatibilità
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: _selectedGroup,
                    decoration: const InputDecoration(
                      labelText: 'Gruppo di compatibilità',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _compatibilityOptions.map((group) {
                      return DropdownMenuItem(
                        value: group,
                        child: Text(group),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedGroup = value);
                    },
                    validator: (value) =>
                        value == null ? 'Seleziona un gruppo' : null,
                  ),
                ),

// Carica PDF
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: // ────────────── CARICA / CAMBIA PDF ──────────────
Padding(
  padding: const EdgeInsets.only(bottom: 16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
        onPressed: _isUploadingPdf
            ? null
            : () async {
                setState(() => _isUploadingPdf = true);

                final result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['pdf'],
);
                if (result != null) {
  // 1) Leggi i byte del file (web o mobile)
  final Uint8List bytes = kIsWeb
    ? result.files.single.bytes!
    : await File(result.files.single.path!).readAsBytes();

  // 2) Codifica in Base64
  final String b64 = base64Encode(bytes);

  // 3) Genera un fileId custom (UUID)
  final String fileId = const Uuid().v4();

  // 4) Prepara il documento da salvare in Mongo
  final doc = {
    'fileId': fileId,
    'filename': result.files.single.name,
    'data': b64,
    'uploadedAt': DateTime.now().toIso8601String(),
  };

  // 5) Salva in MongoDB → collection "files"
  final token = AuthSession.token!;
  await DatabaseService().addDataToCollection(
    '${AuthSession.username}-database',
    'files',
    doc,
    token,
  );

  // 6) Aggiorna stato locale col nostro fileId
  setState(() {
    _pickedFileId   = fileId;
    _pickedFileName = result.files.single.name;
    _pickedFilePath = '';  // non più necessario
  });
}


                setState(() => _isUploadingPdf = false);
              },
        child: _isUploadingPdf
            ? const CircularProgressIndicator()
            : Text(_pickedFilePath == null
                ? 'Carica Scheda Sicurezza (PDF)'
                : 'Cambia PDF'),
      ),
      if (_pickedFileName != null) ...[
        const SizedBox(height: 8),
        Text(
          _pickedFileName!,                   // mostra il nome del file scelto
          style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
        ),
      ],
    ],
  ),
),

                ),

                // Quantità
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Quantità'),
                    keyboardType: TextInputType.number,
                  ),
                ),

                // Scadenza
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    children: [
                      const Text('Scadenza:'),
                      const SizedBox(width: 12),
                      Text('${_expiryDate.toLocal()}'.split(' ')[0]),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _selectDate,
                      ),
                    ],
                  ),
                ),

                // Pulsante Aggiungi/Salva
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    widget.productToEdit == null ? 'Aggiungi' : 'Salva',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



