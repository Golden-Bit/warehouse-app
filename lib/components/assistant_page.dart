
import 'package:app_inventario/components/classes.dart';
import 'package:flutter/material.dart';

/// Pagina assistente virtuale con log eventi
class AssistantPage extends StatefulWidget {
  final List<LogEvent> logs;
  final VoidCallback onClearLogs;

  const AssistantPage({
    super.key,
    required this.logs,
    required this.onClearLogs,
  });

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedActionFilter;

  @override
  Widget build(BuildContext context) {
    final filteredLogs = widget.logs
        .where((log) {
          final searchMatch = log.description.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              );
          final actionMatch = _selectedActionFilter == null ||
              log.action.toLowerCase() == _selectedActionFilter!.toLowerCase();
          return searchMatch && actionMatch;
        })
        .toList()
        .reversed
        .toList(); // ultimi in alto

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistente Magazzino'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Cancella tutti i log',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Conferma eliminazione'),
                  content:
                      const Text('Sei sicuro di voler eliminare tutti i log?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annulla'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onClearLogs();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Log cancellati')),
                        );
                      },
                      child: const Text('Conferma',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Cerca nei log',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: DropdownButtonFormField<String>(
              value: _selectedActionFilter,
              items: <String?>[
                null,
                'aggiunto',
                'modificato',
                'eliminato',
                'importato_excel',
                'esportato_excel',
              ].map((action) {
                return DropdownMenuItem(
                  value: action,
                  child: Text(action == null ? 'Tutti' : action),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedActionFilter = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Filtra per azione',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredLogs.isEmpty
                ? const Center(child: Text('Nessuna attività trovata'))
                : ListView.builder(
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      final iconData = _getIcon(log.action);
                      final color = _getColor(log.action);

                      return ListTile(
                        leading: Icon(iconData, color: color),
                        title: Text(log.description),
                        subtitle: Text(_formatDate(log.timestamp)),
                        trailing: Text(log.action.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            )),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String action) {
    switch (action.toLowerCase()) {
      case 'aggiunto':
        return Icons.add_circle;
      case 'modificato':
        return Icons.edit;
      case 'eliminato':
        return Icons.delete;
      case 'importato_excel':
        return Icons.file_download;
      case 'esportato_excel':
        return Icons.file_upload;
      default:
        return Icons.info;
    }
  }

  Color _getColor(String action) {
    switch (action.toLowerCase()) {
      case 'aggiunto':
        return Colors.green;
      case 'modificato':
        return Colors.orange;
      case 'eliminato':
        return Colors.red;
      case 'importato_excel':
        return Colors.blue;
      case 'esportato_excel':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} – ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}





