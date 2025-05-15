import 'package:app_inventario/components/add_product_page.dart';
import 'package:app_inventario/components/assistant_page.dart';
import 'package:app_inventario/components/classes.dart';
import 'package:app_inventario/components/dashboard_summary.dart';
import 'package:app_inventario/components/loan_page.dart';
import 'package:app_inventario/components/product_card.dart';
import 'package:app_inventario/components/product_detail_page.dart';
import 'package:app_inventario/components/smart_virtual_assistant_page.dart';
import 'package:app_inventario/components/statics_page.dart';
import 'package:app_inventario/components/utils.dart';
import 'package:app_inventario/databases_manager/database_service.dart';
import 'package:app_inventario/user_manager/auth_sdk/cognito_api_client.dart';
import 'package:app_inventario/user_manager/auth_sdk/models/sign_in_request.dart';
import 'package:app_inventario/user_manager/pages/login_page_1.dart';
import 'package:app_inventario/user_manager/pages/registration_page_1.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// timezone data + API duo
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show kIsWeb;
// per il web-only HTML download
import 'dart:html' as html;
import 'package:google_fonts/google_fonts.dart';
import 'shared/theme.dart';
import 'dart:html' as html;  

/// Gestione sessione lato web (token & username salvati da LoginPasswordPage)
class AuthSession {
  static String? get _rawUser => html.window.localStorage['user'];
  static String? get token     => html.window.localStorage['token'];
  static String? get refresh   => html.window.localStorage['refreshToken'];

  /// Username utilizzato per nominare il database MongoDB
  static String get username {
    if (_rawUser == null) throw Exception('Utente non loggato');
    final Map<String, dynamic> js = jsonDecode(_rawUser!);
    return js['username'] as String;
  }

  /// Verifica la validità del token e – se mancano <60 s – ne ottiene uno nuovo
  static Future<void> ensureValidToken(CognitoApiClient api) async {
    if (token == null) throw Exception('Token assente – login necessario');

    final remaining = api.getRemainingTime(token!);
    if (remaining > 60) {
      api.lastAccessToken = token!;
      return;
    }

    // Proviamo il refresh
    /*if (refresh == null || refresh!.isEmpty) {
      throw Exception('Refresh token assente – login necessario');
    }
    final newAccess = await api.refreshTokens(refresh!);
    html.window.localStorage['token'] = newAccess;
    api.lastAccessToken = newAccess;*/
  }
    /// Invalida la sessione corrente
  static Future<void> logout() async {
    html.window.localStorage
      ..remove('token')
      ..remove('refreshToken')
      ..remove('user');                // rimuove i tre item principali  :contentReference[oaicite:0]{index=0}
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();                     // opzion.​: svuota la cache locale
  }
}


final elevatedButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: AppColors.primary,
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  elevation: 4,
  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
);

final outlinedButtonStyle = OutlinedButton.styleFrom(
  side: BorderSide(color: AppColors.primary, width: 2),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
);
const _drawerItemPadding =
    EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0);
final cardTheme = CardTheme(
  color: Colors.white,
  elevation: 6,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
);

final listTileTheme = ListTileThemeData(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
  tileColor: Colors.white,
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
);

// Poi integra all'interno delle tue ThemeData:

// Nuovo tema centralizzato e professionale
final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    secondary: AppColors.secondary,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: AppColors.background,
  fontFamily: GoogleFonts.roboto().fontFamily,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  appBarTheme: const AppBarTheme(
    elevation: 2,
    backgroundColor: AppColors.primary,
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    hintStyle: TextStyle(color: Colors.grey[600]),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedButtonStyle),
  outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
  cardTheme: cardTheme,
  listTileTheme: listTileTheme,
  textTheme: baseLightTextTheme,
);
final baseLightTextTheme = GoogleFonts.robotoTextTheme();
final baseDarkTextTheme = GoogleFonts.robotoTextTheme(
  ThemeData(brightness: Brightness.dark).textTheme,
);
final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    secondary: AppColors.secondary,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: Color(0xFF121212),
  fontFamily: GoogleFonts.roboto().fontFamily,
  visualDensity: VisualDensity.adaptivePlatformDensity,
  appBarTheme: const AppBarTheme(
    elevation: 2,
    backgroundColor: Color(0xFF1F1F1F),
    centerTitle: true,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF1E1E1E),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    hintStyle: TextStyle(color: Colors.grey[400]),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: elevatedButtonStyle.copyWith(
      backgroundColor: MaterialStateProperty.all<Color>(AppColors.secondary),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
  cardTheme: cardTheme.copyWith(
    color: Color(0xFF1E1E1E),
    shadowColor: Colors.black26,
  ),
  listTileTheme: listTileTheme.copyWith(tileColor: Color(0xFF2A2A2A)),
  textTheme: baseDarkTextTheme,
);


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  // 1) inizializza i dati dei fusi orari
  tz.initializeTimeZones();

  // 2) configurazione Android
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // 3) configurazione iOS/macOS (Darwin)
  const DarwinInitializationSettings darwinSettings =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  // 4) aggrega le impostazioni per tutte le piattaforme
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: darwinSettings,
  );

  // 5) inizializza il plugin
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // 6) (facoltativo) su iOS richiedi i permessi runtime
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
}

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> exportToCSV(List<Product> products, BuildContext context) async {
  debugPrint('[CSV] Avviato export con ${products.length} prodotti');

  if (products.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nessun prodotto da esportare')),
    );
    return;
  }

  try {
    final headers = 'Nome,CAS,Quantità,Scadenza,Compatibilità,Path PDF\n';
    final rows = products.map((p) {
      final formattedDate = "${p.expiryDate.toLocal()}".split(' ')[0];
      return '"${p.name}","${p.casCode}",${p.quantity},"$formattedDate","${p.compatibilityGroup}","${p.sdsPath}"';
    }).join('\n');
    final content = headers + rows;

    if (kIsWeb) {
      // Logica per il web: crea un Blob e avvia il download.
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..style.display = 'none'
        ..download = 'prodotti_magazzino.csv';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('CSV esportato con successo (download avviato)')),
      );
    } else {
      // Logica per mobile/desktop.
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/prodotti_magazzino.csv');
      await file.writeAsString(content);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('CSV esportato con successo'),
          action: SnackBarAction(
            label: 'Condividi',
            onPressed: () {
              if (file.existsSync()) {
                Share.shareXFiles([XFile(file.path)],
                    text: 'Lista prodotti CSV');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File non trovato')),
                );
              }
            },
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint('Errore esportazione CSV: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Errore: $e')),
    );
  }
}








// main.dart
final CognitoApiClient _authClient = CognitoApiClient();

/// Esegue il login (o il refresh) all’avvio dell’app.
/// Salva l’access token in SharedPreferences con la chiave 'authToken'.
Future<void> _restoreSession() async {
  try {
    await AuthSession.ensureValidToken(_authClient);
    debugPrint('🔑 Sessione ripristinata – token OK');

    
    // ─────────────── CREA IL DATABASE DELL'UTENTE ───────────────
    final token = AuthSession.token;
    if (token != null && token.isNotEmpty) {
      final dbName = 'database';
      try {
        await DatabaseService().createDatabase(dbName, token);
        debugPrint('✅ Database utente creato/verificato: $dbName');
      } catch (e) {
        debugPrint('⚠️ Impossibile creare il database utente: $e');
        // qui puoi decidere se interrompere o ignorare
      }
    }
    // ───────────────────────────────────────────────────────────────

  } catch (e) {
    debugPrint('ℹ️  Nessuna sessione valida: $e');
    // Lasciamo che l’utente venga riportato alla LoginPage (comportamento di default)
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();





  await _restoreSession();          // ⬅️  <<<  PRIMA DI QUALSIASI I/O





  await initNotifications(); // ✅ Terminato correttamente
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('themeMode');
  ThemeMode initialMode = ThemeMode.system;

  if (savedTheme == 'light') initialMode = ThemeMode.light;
  if (savedTheme == 'dark') initialMode = ThemeMode.dark;

  themeNotifier.value = initialMode;

  runApp(const MyApp());
}



/// MyApp è il widget principale dell'applicazione.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'Magazzino Chimico',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: mode,
      home: LoginPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegistrationPage(),
      },
        );
      },
    );
  }
}



/// Pagina principale
class ProductListPage extends StatefulWidget {
  const ProductListPage({Key? key}) : super(key: key);

  @override
  State<ProductListPage> createState() => ProductListPageState();
}

class ProductListPageState extends State<ProductListPage> {
    Future<void> _performLogout() async {
    await AuthSession.logout();
    // NB: se vuoi pulire lo stato locale:
    setState(() {
      _warehouses.clear();
      _warehouseLoans.clear();
      _warehouseLogs.clear();
    });
    // Torna alla LoginPage eliminando la history
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }
  /// mappa <nomeMagazzino, listaPrestiti>
  final Map<String, List<Loan>> _warehouseLoans = { 'Generale': [] };

  /// comodità: in tutto il resto del codice continui a usare “loans”
  List<Loan> get loans => _warehouseLoans[_activeWarehouse] ?? [];

/// <nomeMagazzino, listaLog>
final Map<String, List<LogEvent>> _warehouseLogs = {
  'Generale': [],
};

/// in tutto il codice continui a usare “_log” senza refactor massicci
List<LogEvent> get _log => _warehouseLogs[_activeWarehouse] ?? [];

  List<NotificationEvent> _notifications = [];

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _addNotification(String title, String body) {
    setState(() {
      _notifications.insert(
          0,
          NotificationEvent(
            timestamp: DateTime.now(),
            title: title,
            body: body,
          ));
    });
  }

  Future<void> exportLoansToCSV(BuildContext context) async {
    if (loans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun prestito da esportare')),
      );
      return;
    }

    final headers = 'Prodotto,CAS,Persona,Data Prestito,Data Restituzione\n';
    final rows = loans.map((loan) {
      final start = loan.startDate.toIso8601String().split('T').first;
      final end = loan.returnDate?.toIso8601String().split('T').first ?? '';
      return '"${loan.productName}","${loan.casCode}","${loan.person}","$start","$end"';
    }).join('\n');

    final csv = headers + rows;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/prestiti.csv');
    await file.writeAsString(csv);

    addLog('esportato_prestiti', 'Esportati ${loans.length} prestiti (CSV)');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Prestiti esportati in CSV'),
        action: SnackBarAction(
          label: 'Condividi',
          onPressed: () {
            Share.shareXFiles([XFile(file.path)], text: 'Prestiti prodotti');
          },
        ),
      ),
    );
  }

  late stt.SpeechToText _speech;
  // 👈 nuovo
  bool _isListening = false;
  Future<void> exportEverythingToPDF(
      BuildContext context, List<Product> products, List<Loan> loans) async {
    final pdf = pw.Document();

    final expired = products.where((p) => p.isExpired).length;
    final nearExpiry = products.where((p) => p.isNearExpiry).length;
    final totalQty = products.fold<int>(0, (sum, p) => sum + p.quantity);
    final groups = products.map((p) => p.compatibilityGroup).toSet().join(', ');

    // 🧾 Riepilogo generale
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '📊 Report Magazzino Chimico',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Totale prodotti: ${products.length}'),
            pw.Text('Quantità totale: $totalQty'),
            pw.Text('Scaduti: $expired'),
            pw.Text('In scadenza: $nearExpiry'),
            pw.Text('Gruppi di compatibilità: $groups'),
          ],
        ),
      ),
    );

    // 🧪 Tabella Prodotti
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            '📦 Elenco Prodotti',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Nome', 'CAS', 'Quantità', 'Scadenza', 'Compatibilità'],
            data: products
                .map((p) => [
                      p.name,
                      p.casCode,
                      '${p.quantity}',
                      p.expiryDate.toIso8601String().split('T').first,
                      p.compatibilityGroup,
                    ])
                .toList(),
          ),
        ],
      ),
    );

    // 📋 Storico Prestiti
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            '📋 Storico Prestiti',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: [
              'Prodotto',
              'CAS',
              'Persona',
              'Inizio',
              'Restituzione',
              'Stato'
            ],
            data: loans
                .map((l) => [
                      l.productName,
                      l.casCode,
                      l.person,
                      l.startDate.toIso8601String().split('T').first,
                      l.returnDate?.toIso8601String().split('T').first ?? '',
                      l.isReturned ? 'Restituito' : 'Attivo',
                    ])
                .toList(),
          ),
        ],
      ),
    );

    final pdfBytes = await pdf.save();
    if (kIsWeb) {
      // Su web: crea un Blob e simula il download tramite un AnchorElement.
      final blob = html.Blob([pdfBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..style.display = 'none'
        ..download = 'report_magazzino.pdf';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('PDF generato con successo (download avviato)')),
      );
    } else {
      // Su mobile/desktop: salva il file nel file system locale e offri la condivisione.
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/report_magazzino.pdf');
      await file.writeAsBytes(pdfBytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF generato con successo'),
          action: SnackBarAction(
            label: 'Condividi',
            onPressed: () {
              Share.shareXFiles(
                [XFile(file.path)],
                text: 'Report Magazzino Chimico (PDF)',
              );
            },
          ),
        ),
      );
    }
  }

// All'interno di _ProductListPageState, aggiungi questo metodo:
  void checkOverdueLoans() {
    final now = DateTime.now();
    for (final loan in loans) {
      if (!loan.isReturned && loan.dueDate.isBefore(now)) {
        _addNotification(
          'Prestito scaduto',
          '${loan.productName} prestato a ${loan.person} è scaduto!',
        );
        flutterLocalNotificationsPlugin.show(
          loan.hashCode, // ID unico basato sull'hash del prestito
          'Prestito scaduto',
          '${loan.productName} prestato a ${loan.person} è scaduto! Rinnova o restituisci immediatamente.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'overdue_loans',
              'Prestiti Scaduti',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    }
  }

  Future<void> exportStatisticsToExcel(BuildContext context) async {
    final excel = Excel.createExcel();

    // Foglio 1: Riepilogo prodotti
    final summarySheet = excel['Riepilogo Prodotti'];
    summarySheet.appendRow([
      'Totale Prodotti',
      'Quantità Totale',
      'Scaduti',
      'In Scadenza',
      'Gruppi Compatibilità'
    ]);

    final expired = products.where((p) => p.isExpired).length;
    final nearExpiry = products.where((p) => p.isNearExpiry).length;
    final totalQty = products.fold<int>(0, (sum, p) => sum + p.quantity);
    final groups =
        products.map((p) => p.compatibilityGroup).toSet().join(', ');

    summarySheet
        .appendRow([products.length, totalQty, expired, nearExpiry, groups]);

    // Foglio 2: Prestiti
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

  Future<void> exportLoansToExcel(BuildContext context) async {
    if (loans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun prestito da esportare')),
      );
      return;
    }

    final excel = Excel.createExcel();
    final sheet = excel['Prestiti'];

    sheet.appendRow([
      'Prodotto',
      'CAS',
      'Persona',
      'Data Prestito',
      'Data Restituzione',
    ]);

    for (final loan in loans) {
      sheet.appendRow([
        loan.productName,
        loan.casCode,
        loan.person,
        loan.startDate.toIso8601String().split('T').first,
        loan.returnDate?.toIso8601String().split('T').first ?? '',
      ]);
    }

    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/prestiti.xlsx');
      await file.writeAsBytes(fileBytes);

      addLog(
          'esportato_prestiti', 'Esportati ${loans.length} prestiti (Excel)');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Prestiti esportati in Excel'),
          action: SnackBarAction(
            label: 'Condividi',
            onPressed: () {
              Share.shareXFiles(
                [XFile(file.path)],
                text: 'Storico prestiti prodotti',
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> scheduleDailyReminder(List<Product> products) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);

    final upcoming = products.where((p) => p.isNearExpiry).toList();
    if (upcoming.isEmpty) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Promemoria scadenze',
      '${upcoming.length} prodotti in scadenza',
      scheduledTime.isBefore(now)
          ? scheduledTime.add(Duration(days: 1))
          : scheduledTime,
      const NotificationDetails(
        android:
            AndroidNotificationDetails('giornaliera', 'Notifica Giornaliera'),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

//─────────────────────────────────────────────────────────────────────────────
//  LOANS
//─────────────────────────────────────────────────────────────────────────────

  void addLog(String action, String description) {
    final event = LogEvent(
      timestamp: DateTime.now(),
      action: action,
      description: description,
    );
    _log.add(event);
    saveWarehouses();        // i log viaggiano ora col magazzino
  }

  bool _isTableView = false;
  void _updateAndSave([VoidCallback? fn]) {
    if (fn != null) {
      setState(fn);
    }
    saveWarehouses();
  }

  Future<void> importAllWarehousesFromExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      List<int> bytes;
      if (kIsWeb) {
        final webBytes = result.files.single.bytes;
        if (webBytes == null) return;
        bytes = webBytes;
      } else if (result.files.single.path != null) {
        final file = File(result.files.single.path!);
        bytes = await file.readAsBytes();
      } else {
        return;
      }

      final excel = Excel.decodeBytes(bytes);
      final Map<String, List<Product>> imported = {};
      int totalImported = 0;

      for (final sheetName in excel.tables.keys) {
        final sheet = excel.tables[sheetName];
        if (sheet == null || sheet.maxRows < 2) continue;

        final products = <Product>[];
        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.length < 6) continue;
          try {
            final name = row[0]?.value.toString() ?? '';
            final cas = row[1]?.value.toString() ?? '';
            final qty = int.tryParse(row[2]?.value.toString() ?? '') ?? 0;
            final expiry = DateTime.tryParse(row[3]?.value.toString() ?? '');
            final compat = row[4]?.value.toString() ?? 'Non specificato';
            final path = row[5]?.value.toString() ?? '';

            if (name.isEmpty || cas.isEmpty || expiry == null) continue;
            final product = Product(
              name: name,
              casCode: cas,
              quantity: qty,
              expiryDate: expiry,
              compatibilityGroup: compat,
              sdsPath: path,
            );
            products.add(product);
          } catch (e) {
            debugPrint('Errore in "$sheetName" riga ${i + 1}: $e');
          }
        }
        if (products.isNotEmpty) {
          imported[sheetName] = products;
          totalImported += products.length;
        }
      }

      if (imported.isNotEmpty) {
        _updateAndSave(() {
          _warehouses
            ..clear()
            ..addAll(imported);
          _activeWarehouse = _warehouses.keys.first;
          addLog('importato_excel',
              'Importati $totalImported prodotti da tutti i fogli Excel');
          _filterProducts();
        });
        saveWarehouses();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Importazione completata: $totalImported prodotti')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nessun dato valido trovato nel file')),
        );
      }
    }
  }

  Future<void> scheduleDailyExpiryCheck(List<Product> allProducts) async {
    final now = DateTime.now();
    final upcoming = allProducts.where((p) => p.isNearExpiry).toList();

    if (upcoming.isEmpty) return;

    final summary = upcoming.map((p) => p.name).take(3).join(', ');
    final count = upcoming.length;

    await flutterLocalNotificationsPlugin.show(
      0,
      'Prodotti in scadenza',
      '$count prodotto/i in scadenza: $summary',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scadenza_channel',
          'Notifiche Scadenze',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> importFromExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null) {
      List<int> bytes;
      if (kIsWeb) {
        final webBytes = result.files.single.bytes;
        if (webBytes == null) return;
        bytes = webBytes;
      } else if (result.files.single.path != null) {
        final file = File(result.files.single.path!);
        bytes = await file.readAsBytes();
      } else {
        return;
      }

      final excel = Excel.decodeBytes(bytes);
      int importedCount = 0;

      for (final sheet in excel.tables.values) {
        for (int rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
          final row = sheet.rows[rowIndex];
          if (row.length < 6) continue;
          try {
            final name = row[0]?.value.toString() ?? '';
            final cas = row[1]?.value.toString() ?? '';
            final qty = int.tryParse(row[2]?.value.toString() ?? '') ?? 0;
            final expiry = DateTime.tryParse(row[3]?.value.toString() ?? '');
            final compat = row[4]?.value.toString() ?? 'Non specificato';
            final path = row[5]?.value.toString() ?? '';

            if (name.isEmpty || cas.isEmpty || expiry == null) continue;

            final product = Product(
              name: name,
              casCode: cas,
              quantity: qty,
              expiryDate: expiry,
              compatibilityGroup: compat,
              sdsPath: path,
            );
            _addNewProduct(product);
            importedCount++;
          } catch (e) {
            debugPrint('Errore nella riga Excel: $e');
          }
        }
      }
      saveWarehouses();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Importati $importedCount prodotti da Excel')),
      );
      addLog('importato_excel', 'Importati $importedCount prodotti da Excel');
    }
  }

  Future<void> exportToExcel(
      List<Product> products, BuildContext context) async {
    final excel = Excel.createExcel();
    final sheet = excel['Magazzino'];

    // Intestazioni
    sheet.appendRow([
      'Nome',
      'Codice CAS',
      'Quantità',
      'Scadenza',
      'Compatibilità',
      'Path PDF',
    ]);

    // Dati
    for (var p in products) {
      sheet.appendRow([
        p.name,
        p.casCode,
        p.quantity,
        "${p.expiryDate.toLocal()}".split(' ')[0],
        p.compatibilityGroup,
        p.sdsPath,
      ]);
    }

    final fileBytes = excel.encode();
    if (fileBytes != null) {
      if (kIsWeb) {
        final blob = html.Blob([fileBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..style.display = 'none'
          ..download = 'prodotti_magazzino.xlsx';
        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Excel esportato con successo (download avviato)')),
        );
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/prodotti_magazzino.xlsx';
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        addLog('esportato_excel',
            'Esportati ${products.length} prodotti in Excel');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Excel esportato con successo'),
            action: SnackBarAction(
              label: 'Condividi',
              onPressed: () {
                Share.shareXFiles([XFile(filePath)],
                    text: 'Prodotti Magazzino');
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> exportAllWarehousesToExcel(
      Map<String, List<Product>> warehouses, BuildContext context) async {
    final excel = Excel.createExcel();

    for (final entry in warehouses.entries) {
      final sheetName = entry.key;
      final sheet = excel[sheetName];

      // Intestazione
      sheet.appendRow([
        'Nome',
        'Codice CAS',
        'Quantità',
        'Scadenza',
        'Compatibilità',
        'Path PDF',
      ]);

      // Dati
      for (final p in entry.value) {
        sheet.appendRow([
          p.name,
          p.casCode,
          p.quantity,
          "${p.expiryDate.toLocal()}".split(' ')[0],
          p.compatibilityGroup,
          p.sdsPath,
        ]);
      }
    }

    final fileBytes = excel.encode();
    if (fileBytes != null) {
      if (kIsWeb) {
        final blob = html.Blob([fileBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..style.display = 'none'
          ..download = 'magazzini_completi.xlsx';
        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Excel (tutti i magazzini) esportato (download avviato)')),
        );
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/magazzini_completi.xlsx';
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Excel (tutti i magazzini) esportato'),
            action: SnackBarAction(
              label: 'Condividi',
              onPressed: () {
                Share.shareXFiles([XFile(filePath)],
                    text: 'Magazzini chimici - Esportazione completa');
              },
            ),
          ),
        );
        addLog('importato_excel', 'Importato backup JSON');
      }
    }
  }

  Future<String?> _promptRenameWarehouse(String oldName) async {
    final controller = TextEditingController(text: oldName);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rinomina magazzino'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nuovo nome magazzino'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              Navigator.pop(context, newName);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  Future<void> exportWarehousesAsJson(
      BuildContext context, Map<String, List<Product>> warehouses) async {
    final data = warehouses.map((name, products) =>
        MapEntry(name, products.map((p) => p.toJson()).toList()));
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    if (kIsWeb) {
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..style.display = 'none'
        ..download = 'backup_magazzino.json';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Backup esportato con successo (download avviato)')),
      );
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/backup_magazzino.json');
      await file.writeAsString(jsonString);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Backup esportato'),
          action: SnackBarAction(
            label: 'Condividi',
            onPressed: () {
              Share.shareXFiles([XFile(file.path)],
                  text: 'Backup magazzino chimico');
            },
          ),
        ),
      );
    }
  }

  Future<void> importWarehousesFromJson(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      String jsonString;
      if (kIsWeb) {
        final bytes = result.files.single.bytes;
        if (bytes == null) return;
        jsonString = utf8.decode(bytes);
      } else if (result.files.single.path != null) {
        final file = File(result.files.single.path!);
        jsonString = await file.readAsString();
      } else {
        return;
      }

      try {
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        final newWarehouses = decoded.map((name, value) {
          final products =
              (value as List).map((e) => Product.fromJson(e)).toList();
          return MapEntry(name, products);
        });

        _updateAndSave(() {
          _warehouses
            ..clear()
            ..addAll(newWarehouses);
          _activeWarehouse = _warehouses.keys.first;
          _filterProducts();
        });

        saveWarehouses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup importato con successo')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nel file JSON')),
        );
      }
    }
  }















//// Salva i magazzini in locale **e** li sincronizza con MongoDB (modalità upsert).
/// ─────────────────────────────────────────────────────────────────────────────
/// • Persistenza locale in `SharedPreferences`.
/// • Upsert sul server:
///   – se esiste un documento con lo stesso `name` → `update_item`  
///   – altrimenti                                → `add_item`  
/// • L’errore sul singolo magazzino **non** blocca gli altri.
/// • Se la collection non esiste viene creata “al volo”.
Future<void> saveWarehouses() async {
  //───────────────────────── 1. Persistenza locale ──────────────────────────
  final prefs = await SharedPreferences.getInstance();   // rimane per ware-cache

  try {
    final token = AuthSession.token;
    if (token == null || token.isEmpty) {
      debugPrint('⚠️  Utente non loggato – skip sync MongoDB');
      return;
    }

    final dbService = DatabaseService();
    final dbName = '${AuthSession.username}-database';
    const collectionName = 'warehouses';

    // 2a) Otteniamo la lista dei documenti già presenti (potrebbe essere vuota)
    List<Map<String, dynamic>> existingDocs = [];
    try {
      existingDocs = await dbService.fetchCollectionData(
          dbName, collectionName, token);
    } catch (_) {
      // Se la collection non esiste la creiamo.
      await dbService.createCollection(dbName, collectionName, token);
    }

    // 2b) Indicizzazione rapida <name, _id>
    final Map<String, String> idByName = {
      for (final doc in existingDocs)
        if (doc['name'] != null && doc['_id'] != null)
          doc['name'] as String: doc['_id'].toString(),
    };

    // 2c) Upsert best-effort per ogni magazzino
    for (final entry in _warehouses.entries) {
      final payload = <String, dynamic>{
        'name'    : entry.key,
        'products': entry.value.map((p) => p.toJson()).toList(),
        'loans'   : (_warehouseLoans[entry.key] ?? [])
                    .map((l) => l.toJson()).toList(),
        'logs'    : (_warehouseLogs[entry.key] ?? [])
                    .map((e) => e.toJson()).toList(),
      };

      try {
        if (idByName.containsKey(entry.key)) {
          // UPDATE
          await dbService.updateCollectionData(
            dbName,
            collectionName,
            idByName[entry.key]!,
            payload,
            token,
          );
        } else {
          // INSERT
          await dbService.addDataToCollection(
            dbName,
            collectionName,
            payload,
            token,
          );
        }
      } catch (e) {
        // Se l’update ha fallito per 4xx/5xx riproviamo un insert singolo.
        debugPrint('⚠️  Sync fallita per "${entry.key}": $e – tento insert …');
        /*try {
          await dbService.addDataToCollection(
            dbName,
            collectionName,
            payload,
            token,
          );
        } catch (e2) {
          debugPrint('🚫  Anche l’insert di "${entry.key}" è fallita: $e2');
          // Continuiamo comunque col loop: gli altri magazzini non devono subire lo stesso errore
        }*/
      }
    }

    debugPrint('✅ Magazzini sincronizzati con MongoDB (upsert compleato)');
  } catch (e, st) {
    debugPrint('⚠️  Errore globale durante la sync MongoDB: $e\n$st');
  }
}

/// Carica i magazzini dall’API Mongo. In fallback usa SharedPreferences.
Future<void> _loadWarehouses() async {
  print("1");
  final prefs = await SharedPreferences.getInstance();
print("2");
  _warehouses.clear();
  _warehouseLoans.clear();
  _warehouseLogs.clear();
  print("3");
  try {
    final token = AuthSession.token;
    print("####$token");
    final username = AuthSession.username;
    print(username);
    if (token == null) throw Exception('Token non presente');
    print("4");
    final db = DatabaseService();
    print("5");
    final dbName = '${AuthSession.username}-database';
    print("6");
    const collectionName = 'warehouses';
    print("####");
    print(AuthSession.token);
    print(AuthSession.username);
print('****');
    // 1) scarica tutti i documenti
    final docs = await db.fetchCollectionData(dbName, collectionName, token);
          if (_warehouses.isEmpty) {
    _warehouses['Generale'] = [];          // ← entry di default
    _activeWarehouse = 'Generale';
  }

  print(docs);
  
    if (docs.isEmpty) throw Exception('Collection vuota');

    // 2) ricostruisci la mappa locale
    for (final doc in docs) {
      final String name = doc['name'];
      final List<Product> products = (doc['products'] as List)
           .map<Product>((e) => Product.fromJson(e))
           .toList();
       _warehouses[name] = products;

      _warehouseLoans[name] = (doc['loans'] ?? [])
          .map<Loan>((e) => Loan.fromJson(e))
          .toList();
      
           _warehouseLogs[name]  = (doc['logs'] ?? [])
     .map<LogEvent>((e) => LogEvent.fromJson(e)).toList();
    
    }


    _activeWarehouse = prefs.getString('activeWarehouse') ??
        _warehouses.keys.first; // mantieni la selezione precedente

    _filterProducts();
    return; // successo, usciamo
  } catch (e, st) {
    debugPrint('⚠️  Impossibile caricare da Mongo, uso fallback locale: $e\n$st');
  }

  // ---------- Fallback locale (comportamento originale) --------------------
  final localJson = prefs.getString('warehouses');
  final active = prefs.getString('activeWarehouse');
  if (localJson != null) {
    final decoded = jsonDecode(localJson) as Map<String, dynamic>;
    decoded.forEach((name, value) {
      _warehouses[name] =
          (value as List).map((e) => Product.fromJson(e)).toList();
    });
    
    _activeWarehouse = active ?? _warehouses.keys.first;
    
    _filterProducts();
  }
}
















  String _quickFilter = 'Tutti'; // default
  String _orderBy = 'Nome'; // default
  void updateProduct(Product oldProduct, Product newProduct) {
    final index = products.indexOf(oldProduct);
    if (index != -1) {
      _updateAndSave(() {
        products[index] = newProduct;
        addLog('modificato', 'Modificato ${newProduct.name}');

        _filterProducts();
      });
      saveWarehouses();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prodotto "${newProduct.name}" aggiornato')),
      );
    }
  }

  void removeProduct(Product product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: Text('Vuoi davvero eliminare il prodotto "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              _updateAndSave(() {
                products.remove(product);
                addLog('eliminato', 'Eliminato ${product.name}');

                _filterProducts();
                saveWarehouses();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Prodotto "${product.name}" eliminato')),
              );
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String? _selectedFilterGroup; // nuovo filtro
  Future<void> importFromCSV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      String content;
      if (kIsWeb) {
        final bytes = result.files.single.bytes;
        if (bytes == null) return;
        content = utf8.decode(bytes);
      } else if (result.files.single.path != null) {
        final file = File(result.files.single.path!);
        content = await file.readAsString();
      } else {
        return;
      }

      final lines = content.split('\n');
      // Rimuovi intestazione
      final dataLines = lines.skip(1);
      int importedCount = 0;
      for (final line in dataLines) {
        final fields = line.split(',');
        if (fields.length < 6) continue;
        try {
          final product = Product(
            name: fields[0].replaceAll('"', ''),
            casCode: fields[1].replaceAll('"', ''),
            quantity: int.tryParse(fields[2]) ?? 0,
            expiryDate: DateTime.parse(fields[3].replaceAll('"', '')),
            compatibilityGroup: fields[4].replaceAll('"', ''),
            sdsPath: fields[5].replaceAll('"', ''),
          );
          _addNewProduct(product);
          importedCount++;
        } catch (e) {
          debugPrint('Errore nell\'importazione: $e');
        }
      }
      saveWarehouses();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Importazione completata')),
      );
      addLog('importato_excel', 'Importati $importedCount prodotti da Excel');
    }
  }

  final Map<String, List<String>> _incompatibilityRules = {
    'Acido': ['Base'],
    'Base': ['Acido'],
    'Infiammabile': ['Ossidante'],
    'Ossidante': ['Infiammabile'],
    // puoi espandere qui...
  };

  final Map<String, List<Product>> _warehouses = {
    'Generale': [
      /*Product(
        casCode: "50-00-0",
        name: "Formaldeide",
        sdsPath: "/path/fittizio/formaldeide.pdf",
        expiryDate: DateTime(2023, 12, 31),
        quantity: 50,
        compatibilityGroup: "Aldehyde", // ✅ AGGIUNTO
      ),
      Product(
        casCode: "64-17-5",
        name: "Etanolo",
        sdsPath: "/path/fittizio/etanolo.pdf",
        expiryDate: DateTime(2024, 5, 20),
        quantity: 200,
        compatibilityGroup: "Alcol", // ✅ AGGIUNTO
      ),*/
    ], // Magazzino di default
  };
  String _activeWarehouse = 'Generale';

  List<Product> get products => _warehouses[_activeWarehouse] ?? [];

  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _filteredProducts = products;
    _searchController.addListener(_filterProducts);

    _loadWarehouses().then((_) {
      scheduleDailyExpiryCheck(products); // controllo giornaliero
    });

    // Avvia un timer periodico (ogni 5 minuti) per controllare i prestiti scaduti
    Timer.periodic(Duration(minutes: 5), (timer) {
      checkOverdueLoans();
    });

        // ─────────────── CREA IL DATABASE DELL'UTENTE ───────────────
    final token = AuthSession.token;
    if (token != null && token.isNotEmpty) {
      final dbName = 'database';
      try {
        DatabaseService().createDatabase(dbName, token);
        debugPrint('✅ Database utente creato/verificato: $dbName');
      } catch (e) {
        debugPrint('⚠️ Impossibile creare il database utente: $e');
        // qui puoi decidere se interrompere o ignorare
      }
    }
    // ───────────────────────────────────────────────────────────────

  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    _updateAndSave(() {
      _filteredProducts = products.where((product) {
        final matchesSearch = product.name.toLowerCase().contains(query) ||
            product.casCode.toLowerCase().contains(query);
        final matchesGroup = _selectedFilterGroup == null ||
            product.compatibilityGroup == _selectedFilterGroup;

        final matchesQuickFilter = switch (_quickFilter) {
          'Scaduti' => product.isExpired,
          'In Scadenza' => product.isNearExpiry,
          _ => true,
        };

        return matchesSearch && matchesGroup && matchesQuickFilter;
      }).toList();

      // Ordinamento
      _filteredProducts.sort((a, b) {
        switch (_orderBy) {
          case 'Quantità':
            return b.quantity.compareTo(a.quantity);
          case 'Scadenza':
            return a.expiryDate.compareTo(b.expiryDate);
          case 'Nome':
          default:
            return a.name.compareTo(b.name);
        }
      });
    });
  }

  Future<String?> _promptNewWarehouseName() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuovo Magazzino'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nome magazzino'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Crea')),
        ],
      ),
    );
  }

  void _manageWarehouses() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: _warehouses.keys.map((name) {
            final isActive = name == _activeWarehouse;
            return ListTile(
              title: Text(name),
              leading: isActive
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Rinomina',
                    onPressed: () async {
                      final newName = await _promptRenameWarehouse(name);
                      if (newName != null &&
                          newName.isNotEmpty &&
                          !_warehouses.containsKey(newName)) {
                        _updateAndSave(() {
                          _warehouses[newName] = _warehouses.remove(name)!;
                          if (_activeWarehouse == name) {
                            _activeWarehouse = newName;
                          }
                        });
                        saveWarehouses();
                        Navigator.pop(context); // chiude il bottom sheet
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Elimina',
                    onPressed: _warehouses[name]!.isEmpty
                        ? () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Conferma eliminazione'),
                                content: Text(
                                    'Vuoi eliminare il magazzino "$name"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Annulla'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _updateAndSave(() {
                                        _warehouses.remove(name);
                                        if (_activeWarehouse == name) {
                                          _activeWarehouse =
                                              _warehouses.keys.first;
                                        }
                                        _filterProducts();
                                        saveWarehouses();
                                      });
                                      Navigator.pop(context); // chiudi dialog
                                      Navigator.pop(
                                          context); // chiudi bottom sheet
                                    },
                                    child: const Text('Elimina',
                                        style:
                                            TextStyle(color: Colors.redAccent)),
                                  ),
                                ],
                              ),
                            );
                          }
                        : null,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _addNewProduct(Product product) {
    // Check compatibilità
    final incompatibleWithExisting = products.any((p) {
      final incompatibili =
          _incompatibilityRules[product.compatibilityGroup] ?? [];
      return incompatibili.contains(p.compatibilityGroup);
    });

    if (incompatibleWithExisting) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Incompatibilità rilevata'),
          content: const Text(
            'Il prodotto che stai tentando di aggiungere è incompatibile con almeno un altro presente in magazzino.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ok'),
            ),
          ],
        ),
      );
      return;
    }

    // Altrimenti aggiungi normalmente
    _updateAndSave(() {
      products.add(product);
      products.sort((a, b) => a.name.compareTo(b.name));
      _filterProducts();
      saveWarehouses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

Widget _buildDrawer(BuildContext context) {
  return Drawer(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(0),
        bottomRight: Radius.circular(0),
      ),
    ),
    child: Column(
      children: [
        /*────────────────────────  AREA SCROLLABILE  ────────────────────────*/
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.6), // blu 0.6
                ),
                child: const Text(
                  'Magazzino Chimico',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              ListTile(
                contentPadding: _drawerItemPadding,
                leading: const Icon(Icons.smart_toy_outlined),
                title: const Text('Assistente Virtuale'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SmartVirtualAssistantPage(
                        products: products,
                        loans: loans,
                        onExportPDF: () =>
                            exportEverythingToPDF(context, products, loans),
                        onExportCSV: () => exportToCSV(products, context),
                        onExportBackup: () =>
                            exportWarehousesAsJson(context, _warehouses),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2),
                title: const Text('Prodotti'),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: _drawerItemPadding,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ProductListPage()),
                  );
                },
              ),
              ListTile(
                contentPadding: _drawerItemPadding,
                leading: const Icon(Icons.assignment_outlined),
                title: const Text('Prestiti'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoanPage(
                        
                        loans: loans,
                        products: products,
                        onNewLoan: (loan) {
                          setState(() {
                            loans.add(loan);
                            addLog('prestato',
                                '${loan.productName} a ${loan.person}');
                            _addNotification(
                              'Nuovo prestito',
                              '${loan.productName} (${loan.quantity}) a ${loan.person}',
                            );
                            saveWarehouses();
                            scheduleLoanReturnNotification(loan);
                          });
                        },
                        onReturn: (updatedLoan) {
                          setState(() {
                            final index = loans.indexWhere((l) =>
                                l.casCode == updatedLoan.casCode &&
                                l.person == updatedLoan.person &&
                                l.startDate == updatedLoan.startDate);
                            if (index != -1) {
                              if (updatedLoan.returnDate == null) {
                                loans[index] = updatedLoan;
                                addLog(
                                    'rinnovato',
                                    'Prestito di ${updatedLoan.productName} rinnovato: nuova scadenza ${updatedLoan.dueDate.toLocal().toString().split(' ')[0]}');
                              } else {
                                loans[index] = updatedLoan;
                                final matchingProduct = products
                                    .firstWhereOrNull((p) =>
                                        p.casCode == updatedLoan.casCode);
                                if (matchingProduct != null) {
                                  matchingProduct.quantity +=
                                      updatedLoan.quantity;
                                  _filterProducts();
                                }
                                addLog('restituito',
                                    '${updatedLoan.productName} da ${updatedLoan.person}');
                              }
                              saveWarehouses();
                            }
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: _drawerItemPadding,
                leading: const Icon(Icons.history),
                title: const Text('Log attività'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssistantPage(
                        logs: _log,
                        onClearLogs: () {
                          setState(() => _log.clear());
                          saveWarehouses();
                        },
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: _drawerItemPadding,
                leading: const Icon(Icons.pie_chart),
                title: const Text('Statistiche'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StatisticsPage(
                        products: products,
                        loans: loans,
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: _drawerItemPadding,
                leading: const Icon(Icons.brightness_6),
                title: const Text('Cambia tema'),
                onTap: () async {
                  Navigator.pop(context);
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (_) => SimpleDialog(
                      title: const Text('Tema'),
                      children: [
                        SimpleDialogOption(
                          child: const Text('Chiaro'),
                          onPressed: () => Navigator.pop(context, 'light'),
                        ),
                        SimpleDialogOption(
                          child: const Text('Scuro'),
                          onPressed: () => Navigator.pop(context, 'dark'),
                        ),
                        SimpleDialogOption(
                          child: const Text('Sistema'),
                          onPressed: () => Navigator.pop(context, 'system'),
                        ),
                      ],
                    ),
                  );
                  final prefs = await SharedPreferences.getInstance();
                  if (selected != null) {
                    switch (selected) {
                      case 'light':
                        themeNotifier.value = ThemeMode.light;
                        break;
                      case 'dark':
                        themeNotifier.value = ThemeMode.dark;
                        break;
                      default:
                        themeNotifier.value = ThemeMode.system;
                    }
                    prefs.setString('themeMode', selected);
                  }
                },
              ),
            ],
          ),
        ),
        /*────────────────────────────  LOGOUT  ─────────────────────────────*/
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          contentPadding: _drawerItemPadding,
          onTap: () async {
            Navigator.pop(context);     // chiude il drawer
            await _performLogout();     // vedi metodo nello State
          },
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // il tuo drawer esistente
      drawer: _buildDrawer(context),

      // —————— nuova proprietà per il "scrim" grigio dietro il drawer ——————
      drawerScrimColor: Colors.grey.withOpacity(0.6),

      appBar: AppBar(
        title: const Text('Magazzino Chimico'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Tema',
            onSelected: (value) async {
              final prefs = await SharedPreferences.getInstance();
              switch (value) {
                case 'Chiaro':
                  themeNotifier.value = ThemeMode.light;
                  prefs.setString('themeMode', 'light');
                  break;
                case 'Scuro':
                  themeNotifier.value = ThemeMode.dark;
                  prefs.setString('themeMode', 'dark');
                  break;
                default:
                  themeNotifier.value = ThemeMode.system;
                  prefs.setString('themeMode', 'system');
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'Chiaro', child: Text('Tema chiaro')),
              PopupMenuItem(value: 'Scuro', child: Text('Tema scuro')),
              PopupMenuItem(value: 'Sistema', child: Text('Sistema')),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == '__new__') {
                final newName = await _promptNewWarehouseName();
                if (newName != null && !_warehouses.containsKey(newName)) {
                  _updateAndSave(() {
                    _warehouses[newName] = [];
                    _activeWarehouse = newName;
                    _filterProducts();
                    saveWarehouses();
                  });
                }
              } else {
                _updateAndSave(() {
                  _activeWarehouse = value;
                  _filterProducts();
                  saveWarehouses();
                });
              }
            },
            itemBuilder: (context) {
              return _warehouses.keys.map((name) {
                return PopupMenuItem(
                  value: name,
                  child: Text(name),
                );
              }).toList()
                ..add(
                  const PopupMenuItem(
                    value: '__new__',
                    child: Text('➕ Nuovo magazzino'),
                  ),
                );
            },
            icon: const Icon(Icons.store),
            tooltip: 'Cambia magazzino',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => exportToCSV(products, context),
            tooltip: 'Esporta in CSV',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Esporta tutto in PDF',
            onPressed: () => exportEverythingToPDF(context, products, loans),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => importFromCSV(),
            tooltip: 'Importa da CSV',
          ),
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: () => exportWarehousesAsJson(context, _warehouses),
            tooltip: 'Esporta Backup JSON',
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: () => importWarehousesFromJson(context),
            tooltip: 'Importa Backup JSON',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Gestisci magazzini',
            onPressed: _manageWarehouses,
          ),
          IconButton(
            icon: Icon(_isTableView ? Icons.view_list : Icons.table_chart),
            tooltip: _isTableView ? 'Vista lista' : 'Vista tabella',
            onPressed: () {
              _updateAndSave(() {
                _isTableView = !_isTableView;
              });
            },
          ),
// nell’AppBar.actions, al posto dell’IconButton precedente:
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: 'Notifiche',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationPage(
                        notifications: _notifications,
                        onMarkAllRead: () {
                          setState(() {
                            for (var n in _notifications) n.isRead = true;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: PulseBadge(count: _unreadCount),
                ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          DashboardSummary(products: _filteredProducts),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Tutti'),
                  selected: _quickFilter == 'Tutti',
                  onSelected: (_) {
                    _updateAndSave(() {
                      _quickFilter = 'Tutti';
                      _filterProducts();
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Scaduti'),
                  selected: _quickFilter == 'Scaduti',
                  onSelected: (_) {
                    _updateAndSave(() {
                      _quickFilter = 'Scaduti';
                      _filterProducts();
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('In Scadenza'),
                  selected: _quickFilter == 'In Scadenza',
                  onSelected: (_) {
                    _updateAndSave(() {
                      _quickFilter = 'In Scadenza';
                      _filterProducts();
                    });
                  },
                ),
              ],
            ),
          ),
          if (products.any((p) => p.isExpired))
            Container(
              width: double.infinity,
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(12),
              child: const Text(
                '⚠️ Attenzione: ci sono prodotti scaduti!',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          if (products.any((p) => p.isNearExpiry))
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.all(12),
              child: const Text(
                '⚠️ Ci sono prodotti in scadenza entro 30 giorni!',
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Cerca per nome o CAS',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonFormField<String>(
              value: _selectedFilterGroup,
              items: <String?>[
                null,
                'Acido',
                'Base',
                'Infiammabile',
                'Ossidante',
                'Non specificato'
              ].map((group) {
                return DropdownMenuItem<String>(
                  value: group,
                  child: Text(group ?? 'Tutti'),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: 'Filtra per compatibilità',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _updateAndSave(() {
                  _selectedFilterGroup = value;
                  _filterProducts();
                });
              },
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: DropdownButtonFormField<String>(
              value: _orderBy,
              items: ['Nome', 'Quantità', 'Scadenza'].map((order) {
                return DropdownMenuItem(
                  value: order,
                  child: Text('Ordina per $order'),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: 'Ordina per',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value != null) {
                  _updateAndSave(() {
                    _orderBy = value;
                    _filterProducts();
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? const Center(child: Text('Nessun prodotto trovato'))
                      : _isTableView
                          ? SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Nome')),
                                  DataColumn(label: Text('CAS')),
                                  DataColumn(label: Text('Quantità')),
                                  DataColumn(label: Text('Scadenza')),
                                  DataColumn(label: Text('Compatibilità')),
                                  DataColumn(label: Text('Azioni')),
                                ],
                                rows: _filteredProducts.map((product) {
                                  Color? rowColor;
                                  if (product.isExpired) {
                                    rowColor = Colors.red.shade50;
                                  } else if (product.isNearExpiry) {
                                    rowColor = Colors.orange.shade50;
                                  }
                                  return DataRow(
                                    color: MaterialStateProperty.resolveWith<
                                        Color?>((_) => rowColor),
                                    cells: [
                                      DataCell(Text(product.name)),
                                      DataCell(Text(product.casCode)),
                                      DataCell(Text('${product.quantity}')),
                                      DataCell(Text(
                                          '${product.expiryDate.toLocal()}'
                                              .split(' ')[0])),
                                      DataCell(
                                          Text(product.compatibilityGroup)),
                                      DataCell(Row(
                                        children: [
                                          IconButton(
                                            icon:
                                                const Icon(Icons.info_outline),
                                            tooltip: 'Dettagli',
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ProductDetailPage(
                                                    product: product,
                                                    loans: context
                                                        .findAncestorStateOfType<
                                                            ProductListPageState>()!
                                                        .loans, // ← ottieni e passi qui i prestiti
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () async {
                                              final updated = await Navigator
                                                  .push<Product?>(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      AddProductPage(
                                                          productToEdit:
                                                              product),
                                                ),
                                              );
                                              if (updated != null) {
                                                updateProduct(product, updated);
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () =>
                                                removeProduct(product),
                                          ),
                                        ],
                                      )),
                                    ],
                                  );
                                }).toList(),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                return ProductCard(
                                  product: _filteredProducts[index],
                                  onLoan: (product, loan) {
                                    setState(() {
                                      loans.add(loan);
                                      addLog('prestato',
                                          '${product.name} (${loan.quantity}) a ${loan.person}');
                                      product.quantity -= loan.quantity;
                                      _filterProducts();
                                    });
                                    saveWarehouses();
                                    saveWarehouses();
                                    scheduleLoanReturnNotification(loan);
                                  },
                                );
                              },
                            ),
                ),
                Container(
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    'Totale prodotti: ${_filteredProducts.length} | Quantità totale: ${_filteredProducts.fold<int>(0, (sum, p) => sum + p.quantity)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'fab_stats',
              tooltip: 'Statistiche',
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.pie_chart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StatisticsPage(
                      products: products,
                      loans: loans,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            FloatingActionButton(
              heroTag: 'fab_add',
              tooltip: 'Aggiungi prodotto',
              child: const Icon(Icons.add),
              onPressed: () async {
                final newProduct = await Navigator.push<Product?>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductPage()),
                );
                if (newProduct != null) {
                  _addNewProduct(newProduct);
                  addLog('aggiunto', 'Aggiunto ${newProduct.name}');
                  saveWarehouses();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Prodotto "${newProduct.name}" aggiunto con successo'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}