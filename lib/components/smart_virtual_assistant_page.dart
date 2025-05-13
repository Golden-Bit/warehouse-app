

import 'package:app_inventario/components/classes.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Assistente Virtuale Smart
class SmartVirtualAssistantPage extends StatefulWidget {
  final List<Product> products;
  final List<Loan> loans;
  final VoidCallback? onExportPDF;
  final VoidCallback? onExportCSV;
  final VoidCallback? onExportBackup;

  const SmartVirtualAssistantPage({
    super.key,
    required this.products,
    required this.loans,
    this.onExportPDF,
    this.onExportCSV,
    this.onExportBackup,
  });

  @override
  State<SmartVirtualAssistantPage> createState() =>
      _SmartVirtualAssistantPageState();
}

class _SmartVirtualAssistantPageState extends State<SmartVirtualAssistantPage> {
  late stt.SpeechToText _speech;
  final Map<String, List<String>> _intentSynonyms = {
    'prodotti_scaduti': [
      'scaduto',
      'scaduti',
      'oltre la data',
      'fuori validità',
      'non più valido',
      'non utilizzabile',
      'fuori uso',
      'expired',
      'prodotti non validi',
      'prodotto scaduto',
      'che è scaduto',
      'prodotto fuori data',
    ],
    'prodotti_in_scadenza': [
      'in scadenza',
      'sta per scadere',
      'prossima scadenza',
      'quasi scaduto',
      'a breve scadono',
      'prodotti che scadono presto',
      'entro 30 giorni',
      'prodotti prossimi alla scadenza',
      'tra poco scadono',
      'prodotto che scade',
      'in scadenza prossima',
    ],
    'prestiti': [
      'prestiti',
      'in prestito',
      'chi ha preso',
      'prestato a',
      'consegnato a',
      'dato in mano a',
      'non restituito',
      'in uso da altri',
      'materiale in prestito',
      'prodotti prestati',
      'prestito attivo',
      'chi ha il prodotto',
      'chi ha il materiale',
    ],
    'aiuto': [
      'aiuto',
      'help',
      'cosa sai fare',
      'cosa puoi fare',
      'come puoi aiutarmi',
      'funzionalità',
      'spiegami',
      'istruzioni',
      'spiega cosa fai',
      'in che modo puoi aiutarmi',
      'comandi vocali',
    ],
    'pdf': [
      'pdf',
      'report',
      'documento',
      'genera pdf',
      'esporta pdf',
      'salva pdf',
      'voglio un pdf',
      'scarica pdf',
      'report pdf',
      'file pdf',
    ],
    'csv': [
      'csv',
      'esporta csv',
      'file csv',
      'tabella',
      'voglio i dati',
      'formato csv',
      'excel',
      'dati in tabella',
      'dati excel',
      'scarica excel',
      'salva excel',
      'genera excel',
      'esporta in tabella',
    ],
    'backup': [
      'backup',
      'esporta tutto',
      'esportazione completa',
      'salvataggio',
      'salva dati',
      'backup json',
      'file json',
      'voglio un backup',
      'esporta magazzino',
      'genera backup',
      'esportazione magazzino',
    ],
    'saluto': [
      'ciao',
      'salve',
      'buongiorno',
      'buonasera',
      'ehi',
      'hey',
      'hola',
      'come stai',
      'tutto bene',
      'yo',
      'hei',
      'ben trovato',
      'ben ritrovato',
    ],
    'gratitudine': [
      'grazie',
      'ti ringrazio',
      'sei grande',
      'ottimo lavoro',
      'molto utile',
      'perfetto',
      'grazie mille',
    ],
  };

  bool _isListening = false;
  final _controller = TextEditingController();

  final List<_Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_Message('user', text));
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      final response = _generateResponse(text.toLowerCase());
      setState(() => _messages.add(response));
    });

    _controller.clear();
  }

  _Message _generateResponse(String question) {
    final products = widget.products;
    final loans = widget.loans;

    if (question.contains('aiuto') || question.contains('puoi fare')) {
      return _Message(
        'assistant',
        'Posso aiutarti con:\n'
            '• 📦 Prodotti in scadenza\n'
            '• ❌ Prodotti scaduti\n'
            '• 👤 Prestiti attivi\n'
            '• 📁 Esportazioni o backup\n'
            'Chiedimi qualcosa o usa i pulsanti!',
        quickReplies: [
          _QuickReply(
              'Prodotti scaduti', () => _sendMessage('prodotti scaduti')),
          _QuickReply('Prestiti attivi', () => _sendMessage('prestiti attivi')),
          _QuickReply('Esporta PDF', widget.onExportPDF ?? () {}),
        ],
      );
    }

    if (_matchesIntent(question, 'saluto')) {
      return _Message('assistant', 'Ciao! 👋 Come posso aiutarti oggi?');
    }

    if (_matchesIntent(question, 'aiuto')) {
      return _Message(
        'assistant',
        'Ecco cosa posso fare:\n'
            '• 🔍 Cercare prodotti\n'
            '• ⏳ Trovare quelli in scadenza\n'
            '• 📦 Mostrare i prestiti\n'
            '• 📁 Esportare file PDF, CSV o backup\n'
            'Scrivimi pure qualcosa!',
        quickReplies: [
          _QuickReply('Scaduti', () => _sendMessage('prodotti scaduti')),
          _QuickReply(
              'In scadenza', () => _sendMessage('prodotti in scadenza')),
          _QuickReply('Prestiti attivi', () => _sendMessage('prestiti')),
        ],
      );
    }

    if (_matchesIntent(question, 'prodotti_scaduti')) {
      final expired = products.where((p) => p.isExpired).toList();
      return expired.isEmpty
          ? _Message('assistant', '✅ Nessun prodotto attualmente scaduto.')
          : _Message('assistant',
              '⚠️ Prodotti scaduti:\n${expired.map((p) => '• ${p.name}').join('\n')}');
    }

    if (_matchesIntent(question, 'prodotti_in_scadenza')) {
      final near = products.where((p) => p.isNearExpiry).toList();
      return near.isEmpty
          ? _Message(
              'assistant', '🎉 Nessun prodotto in scadenza entro 30 giorni.')
          : _Message('assistant',
              '⏳ Prodotti in scadenza:\n${near.map((p) => '• ${p.name}').join('\n')}');
    }

    if (_matchesIntent(question, 'prestiti')) {
      final active = loans.where((l) => !l.isReturned).toList();
      if (active.isEmpty) {
        return _Message('assistant', '✅ Nessun prestito attivo.');
      }
      final details = active.map((l) =>
          '• ${l.productName} → ${l.person} (${_formatDate(l.startDate)})');
      return _Message(
          'assistant', '📋 Prestiti attivi:\n${details.join('\n')}');
    }

    if (_matchesIntent(question, 'pdf')) {
      return _Message(
        'assistant',
        '📄 Vuoi generare il PDF del magazzino?',
        actions: [
          if (widget.onExportPDF != null)
            _AssistantAction('Genera PDF', widget.onExportPDF!),
        ],
      );
    }

    if (_matchesIntent(question, 'csv')) {
      return _Message(
        'assistant',
        '📊 Vuoi esportare i prodotti in CSV?',
        actions: [
          if (widget.onExportCSV != null)
            _AssistantAction('Esporta CSV', widget.onExportCSV!),
        ],
      );
    }

    if (_matchesIntent(question, 'backup')) {
      return _Message(
        'assistant',
        '💾 Vuoi fare un backup completo del magazzino?',
        actions: [
          if (widget.onExportBackup != null)
            _AssistantAction('Backup JSON', widget.onExportBackup!),
        ],
      );
    }

    if (question.contains('in scadenza')) {
      final near = products.where((p) => p.isNearExpiry).toList();
      if (near.isEmpty) {
        return _Message(
            'assistant', '🎉 Nessun prodotto in scadenza entro 30 giorni.');
      }
      return _Message(
        'assistant',
        '⏳ Prodotti in scadenza (${near.length}):\n${near.map((p) => '• ${p.name}').join('\n')}',
      );
    }

    if (question.contains('prestiti')) {
      final active = loans.where((l) => !l.isReturned).toList();
      if (active.isEmpty) {
        return _Message(
            'assistant', '📦 Tutti i prodotti sono stati restituiti.');
      }
      final lines = active.map((l) =>
          '• ${l.productName} → ${l.person} (${_formatDate(l.startDate)})');
      return _Message('assistant', '🔄 Prestiti attivi:\n${lines.join('\n')}');
    }

    if (question.contains('esporta pdf')) {
      return _Message(
        'assistant',
        '📄 Esporto il PDF del magazzino...',
        actions: [
          if (widget.onExportPDF != null)
            _AssistantAction('Avvia Esportazione PDF', widget.onExportPDF!),
        ],
      );
    }

    if (question.contains('csv')) {
      return _Message(
        'assistant',
        '📑 Esporto in formato CSV...',
        actions: [
          if (widget.onExportCSV != null)
            _AssistantAction('Esporta CSV', widget.onExportCSV!),
        ],
      );
    }

    if (question.contains('backup')) {
      return _Message(
        'assistant',
        '💾 Esporto il backup del magazzino...',
        actions: [
          if (widget.onExportBackup != null)
            _AssistantAction('Backup JSON', widget.onExportBackup!),
        ],
      );
    }

    return _Message(
      'assistant',
      '🤖 Non sono sicuro di aver capito bene... vuoi parlare di prodotti, scadenze o prestiti?',
      quickReplies: [
        _QuickReply('Scaduti', () => _sendMessage('prodotti scaduti')),
        _QuickReply('In scadenza', () => _sendMessage('prodotti in scadenza')),
        _QuickReply('Prestiti', () => _sendMessage('prestiti')),
        _QuickReply('Aiuto', () => _sendMessage('aiuto')),
      ],
    );
  }

  bool _matchesIntent(String input, String intentKey) {
    final synonyms = _intentSynonyms[intentKey] ?? [];
    return synonyms.any((s) => input.contains(s));
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  void _listenVoice() async {
    if (!_isListening) {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done') setState(() => _isListening = false);
        },
        onError: (err) {
          debugPrint('Errore voce: $err');
          setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (result) {
          final spoken = result.recognizedWords;
          if (spoken.isNotEmpty) {
            _sendMessage(spoken);
          }
        });
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('💬 Assistente Virtuale')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                final isUser = msg.role == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Colors.blue.shade100
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(msg.text),
                      ),
                      if (!isUser && msg.quickReplies.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          children: msg.quickReplies.map((reply) {
                            return ElevatedButton(
                              onPressed: reply.onPressed,
                              child: Text(reply.label),
                            );
                          }).toList(),
                        ),
                      if (!isUser && msg.actions.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: msg.actions.map((a) {
                            return TextButton.icon(
                              onPressed: a.onPressed,
                              icon: const Icon(Icons.play_arrow),
                              label: Text(a.label),
                            );
                          }).toList(),
                        )
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  color: _isListening ? Colors.red : null,
                  onPressed: _listenVoice,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _sendMessage,
                    decoration: const InputDecoration(
                      hintText: 'Scrivi una domanda...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String role; // 'user' | 'assistant'
  final String text;
  final List<_QuickReply> quickReplies;
  final List<_AssistantAction> actions;

  _Message(
    this.role,
    this.text, {
    this.quickReplies = const [],
    this.actions = const [],
  });
}

class _QuickReply {
  final String label;
  final VoidCallback onPressed;
  _QuickReply(this.label, this.onPressed);
}

class _AssistantAction {
  final String label;
  final VoidCallback onPressed;
  _AssistantAction(this.label, this.onPressed);
}