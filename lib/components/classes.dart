

import 'package:flutter/material.dart';

class AppColors {
  // Blu con opacità 0.6
  static const primary = Color.fromRGBO(51, 102, 153, 0.6);
  static const secondary = Color(0xFF00CC99);
  static const error = Color(0xFFE53935);
  static const background = Color(0xFFF5F5F5);
}

class NotificationEvent {
  final DateTime timestamp;
  final String title;
  final String body;
  bool isRead;

  NotificationEvent({
    required this.timestamp,
    required this.title,
    required this.body,
    this.isRead = false,
  });
}


/// Rappresenta un messaggio dell’assistente con risposte rapide o azioni
class AssistantMessage {
  final String role; // 'user' o 'assistant'
  final String text;
  final List<AssistantAction> actions;

  AssistantMessage({
    required this.role,
    required this.text,
    this.actions = const [],
  });
}

class AssistantAction {
  final String label;
  final VoidCallback onPressed;

  AssistantAction({required this.label, required this.onPressed});
}



class Loan {
  final String productName;
  final String casCode;
  final String person;
  final DateTime startDate;
  final DateTime
      dueDate; // Nuova: data entro cui il prestito deve essere restituito
  final int quantity; // Nuova: quantità prestata
  final DateTime? returnDate;

  Loan({
    required this.productName,
    required this.casCode,
    required this.person,
    required this.startDate,
    required this.dueDate,
    required this.quantity,
    this.returnDate,
  });

  bool get isReturned => returnDate != null;

  Map<String, dynamic> toJson() => {
        'productName': productName,
        'casCode': casCode,
        'person': person,
        'startDate': startDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'quantity': quantity,
        'returnDate': returnDate?.toIso8601String(),
      };

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
        productName: json['productName'],
        casCode: json['casCode'],
        person: json['person'],
        startDate: DateTime.parse(json['startDate']),
        dueDate: DateTime.parse(json['dueDate']),
        quantity: json['quantity'],
        returnDate: json['returnDate'] != null
            ? DateTime.parse(json['returnDate'])
            : null,
      );
}


/// Modello dati per il prodotto chimico, con supporto a PDF salvati in MongoDB.
class Product {
  final String casCode;
  final String name;
  final String sdsPath;          // Mantiene il percorso locale/URL (opzionale)
  final String? sdsFileId;       // ID del file PDF salvato in MongoDB (Base64)
  final DateTime expiryDate;
  int quantity;
  final String compatibilityGroup;

  Product({
    required this.casCode,
    required this.name,
    required this.sdsPath,
    this.sdsFileId,
    required this.expiryDate,
    required this.quantity,
    required this.compatibilityGroup,
  });

  /// Serializza il prodotto in JSON, incluso l’ID del file PDF se presente.
  Map<String, dynamic> toJson() => {
        'casCode': casCode,
        'name': name,
        'sdsPath': sdsPath,
        'sdsFileId': sdsFileId,
        'expiryDate': expiryDate.toIso8601String(),
        'quantity': quantity,
        'compatibilityGroup': compatibilityGroup,
      };

  /// Costruisce un prodotto da JSON, leggendo anche l’ID del file PDF.
  factory Product.fromJson(Map<String, dynamic> json) => Product(
        casCode: json['casCode'] as String,
        name: json['name'] as String,
        sdsPath: json['sdsPath'] as String,
        sdsFileId: json['sdsFileId'] as String?,
        expiryDate: DateTime.parse(json['expiryDate'] as String),
        quantity: json['quantity'] as int,
        compatibilityGroup: json['compatibilityGroup'] as String,
      );

  /// Indica se il prodotto scadrà entro 30 giorni (esclusi gli scaduti).
  bool get isNearExpiry =>
      !isExpired &&
      expiryDate.isBefore(DateTime.now().add(const Duration(days: 30)));

  /// Indica se il prodotto è già scaduto.
  bool get isExpired => expiryDate.isBefore(DateTime.now());
}



class LogEvent {
  final DateTime timestamp;
  final String action;
  final String description;

  LogEvent({
    required this.timestamp,
    required this.action,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'action': action,
        'description': description,
      };

  factory LogEvent.fromJson(Map<String, dynamic> json) => LogEvent(
        timestamp: DateTime.parse(json['timestamp']),
        action: json['action'],
        description: json['description'],
      );
}



class PulseBadge extends StatefulWidget {
  final int count;
  const PulseBadge({required this.count});
  @override
  _PulseBadgeState createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<PulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.9,
      upperBound: 1.1,
    )
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _ctrl.reverse();
        if (s == AnimationStatus.dismissed) _ctrl.forward();
      })
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => ScaleTransition(
        scale: _ctrl,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          child: Center(
            child: Text(
              '${widget.count}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      );
}

class NotificationPage extends StatelessWidget {
  final List<NotificationEvent> notifications;
  final VoidCallback onMarkAllRead;
  const NotificationPage(
      {required this.notifications, required this.onMarkAllRead, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifiche'),
        actions: [
          TextButton(
            onPressed: onMarkAllRead,
            child: const Text('Segna tutte come lette',
                style: TextStyle(color: Colors.white, fontSize: 14)),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (_, i) {
          final n = notifications[i];
          return ListTile(
            tileColor: n.isRead ? null : Colors.blue.shade50,
            title: Text(n.title),
            subtitle: Text(n.body),
            trailing: Text(
              '${n.timestamp.hour.toString().padLeft(2, '0')}:'
              '${n.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: n.isRead ? Colors.grey : Colors.blue),
            ),
            onTap: () {
              n.isRead = true;
              // opzionale: Navigator.pop o refresh
            },
          );
        },
      ),
    );
  }
}
