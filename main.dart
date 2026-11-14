import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const navy = Color(0xFF102B50);
const pale = Color(0xFFEAF1F8);
const storageKey = 'sc9_local_schedules_v1';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Sc9App());
}

class MeetingPart {
  MeetingPart({required this.number, required this.title, required this.minutes,
    this.student = '', this.assistant = '', this.presenter = ''});
  final int number;
  String title;
  String minutes;
  String student;
  String assistant;
  String presenter;

  Map<String, dynamic> toJson() => {'number': number, 'title': title, 'minutes': minutes,
    'student': student, 'assistant': assistant, 'presenter': presenter};
  factory MeetingPart.fromJson(Map<String, dynamic> j) => MeetingPart(
    number: j['number'] as int? ?? 1, title: j['title'] as String? ?? '',
    minutes: j['minutes'] as String? ?? '', student: j['student'] as String? ?? '',
    assistant: j['assistant'] as String? ?? '', presenter: j['presenter'] as String? ?? '');
}

class MeetingSchedule {
  MeetingSchedule({String? id, DateTime? date, this.congregation = '', this.bibleReading = '',
    this.chairman = '', this.openingSong = '', this.openingPrayer = '', this.introduction = '1',
    this.middleSong = '', this.conclusion = '3', this.closingSong = '', this.closingPrayer = '',
    List<MeetingPart>? parts}) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
    date = date ?? DateTime.now(), parts = parts ?? defaultParts();

  String id;
  DateTime date;
  String congregation, bibleReading, chairman, openingSong, openingPrayer, introduction;
  String middleSong, conclusion, closingSong, closingPrayer;
  List<MeetingPart> parts;

  static List<MeetingPart> defaultParts() => [
    MeetingPart(number: 1, title: '', minutes: '10', presenter: ''),
    MeetingPart(number: 2, title: 'Espirituwal nga Bahandi', minutes: '10', presenter: ''),
    MeetingPart(number: 3, title: 'Pagbasa sa Bibliya', minutes: '4', student: ''),
    MeetingPart(number: 5, title: '', minutes: '', student: '', assistant: ''),
    MeetingPart(number: 6, title: '', minutes: '', student: '', assistant: ''),
    MeetingPart(number: 7, title: '', minutes: '', student: '', assistant: ''),
    MeetingPart(number: 8, title: '', minutes: '', presenter: ''),
    MeetingPart(number: 9, title: '', minutes: '', presenter: ''),
    MeetingPart(number: 10, title: '', minutes: '', presenter: ''),
  ];

  Map<String, dynamic> toJson() => {'id': id, 'date': date.toIso8601String(), 'congregation': congregation,
    'bibleReading': bibleReading, 'chairman': chairman, 'openingSong': openingSong,
    'openingPrayer': openingPrayer, 'introduction': introduction, 'middleSong': middleSong,
    'conclusion': conclusion, 'closingSong': closingSong, 'closingPrayer': closingPrayer,
    'parts': parts.map((p) => p.toJson()).toList()};
  factory MeetingSchedule.fromJson(Map<String, dynamic> j) => MeetingSchedule(
    id: j['id'] as String?, date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
    congregation: j['congregation'] as String? ?? '', bibleReading: j['bibleReading'] as String? ?? '',
    chairman: j['chairman'] as String? ?? '', openingSong: j['openingSong'] as String? ?? '',
    openingPrayer: j['openingPrayer'] as String? ?? '', introduction: j['introduction'] as String? ?? '1',
    middleSong: j['middleSong'] as String? ?? '', conclusion: j['conclusion'] as String? ?? '3',
    closingSong: j['closingSong'] as String? ?? '', closingPrayer: j['closingPrayer'] as String? ?? '',
    parts: (j['parts'] as List<dynamic>? ?? []).map((e) => MeetingPart.fromJson(Map<String, dynamic>.from(e as Map))).toList());
}

class ScheduleStore {
  static Future<List<MeetingSchedule>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return [];
    try { return (jsonDecode(raw) as List).map((e) => MeetingSchedule.fromJson(Map<String, dynamic>.from(e))).toList(); }
    catch (_) { return []; }
  }
  static Future<void> save(List<MeetingSchedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(schedules.map((s) => s.toJson()).toList()));
  }
}

class Sc9App extends StatelessWidget {
  const Sc9App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MIDWEEK MEETING SC9', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: navy),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA), appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white, foregroundColor: navy, elevation: 0),
      cardTheme: CardThemeData(color: Colors.white, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE3E8EF)))),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFFF7F9FC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
    home: const ScheduleHome());
}

class ScheduleHome extends StatefulWidget {
  const ScheduleHome({super.key});
  @override State<ScheduleHome> createState() => _ScheduleHomeState();
}
class _ScheduleHomeState extends State<ScheduleHome> {
  List<MeetingSchedule> schedules = [];
  bool loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final data = await ScheduleStore.load(); if (mounted) setState(() { schedules = data..sort((a,b) => b.date.compareTo(a.date)); loading = false; }); }
  Future<void> _persist() => ScheduleStore.save(schedules);
  Future<void> _open([MeetingSchedule? existing, bool duplicate = false]) async {
    final draft = existing == null ? MeetingSchedule() : MeetingSchedule.fromJson(existing.toJson());
    if (duplicate) { draft.id = DateTime.now().microsecondsSinceEpoch.toString(); draft.date = draft.date.add(const Duration(days: 7)); }
    final result = await Navigator.of(context).push<MeetingSchedule>(MaterialPageRoute(builder: (_) => ScheduleEditor(schedule: draft)));
    if (result == null) return;
    setState(() { schedules.removeWhere((s) => s.id == result.id); schedules.add(result); schedules.sort((a,b) => b.date.compareTo(a.date)); });
    await _persist();
  }
  Future<void> _delete(MeetingSchedule s) async {
    final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Papas-on ang eskedyul?'),
      content: const Text('Dili na kini makita sa imong listahan.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Kanselahon')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Papas-on'))]));
    if (yes == true) { setState(() => schedules.removeWhere((x) => x.id == s.id)); await _persist(); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('MIDWEEK MEETING SC9', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), Text('Tig-organisar nga eskedyul', style: TextStyle(fontSize: 12, color: Colors.black54))]),
      actions: [IconButton(tooltip: 'I-refresh', onPressed: _load, icon: const Icon(Icons.refresh))]),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => _open(), backgroundColor: navy, foregroundColor: Colors.white,
      icon: const Icon(Icons.add), label: const Text('Bag-ong eskedyul')),
    body: loading ? const Center(child: CircularProgressIndicator()) : schedules.isEmpty ? _empty() : ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 100), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(18)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('MAAYONG PAG-ABOT', style: TextStyle(color: Colors.white70, letterSpacing: 1.2, fontSize: 11, fontWeight: FontWeight.bold)), SizedBox(height: 6), Text('Andama ang imong tigom.', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('Paghimo, tipigi, ug i-export ang eskedyul bisan walay internet.', style: TextStyle(color: Colors.white70))])),
        const SizedBox(height: 22), Row(children: [const Expanded(child: Text('Mga gitipig nga eskedyul', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navy))), Text('${schedules.length} ka eskedyul', style: const TextStyle(color: Colors.black54))]),
        const SizedBox(height: 10), ...schedules.map(_scheduleCard),
      ]));
  Widget _empty() => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 76, height: 76, decoration: const BoxDecoration(color: pale, shape: BoxShape.circle), child: const Icon(Icons.calendar_month, size: 36, color: navy)),
    const SizedBox(height: 18), const Text('Wala pay gitipig nga eskedyul', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navy)),
    const SizedBox(height: 8), const Text('Pislita ang “Bag-ong eskedyul” aron magsugod sa imong midweek meeting schedule.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
  ])));
  Widget _scheduleCard(MeetingSchedule s) => Card(margin: const EdgeInsets.only(bottom: 10), child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () => _open(s), child: Padding(padding: const EdgeInsets.all(15), child: Row(children: [
    Container(width: 52, height: 56, decoration: BoxDecoration(color: pale, borderRadius: BorderRadius.circular(12)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(DateFormat('d').format(s.date), style: const TextStyle(color: navy, fontSize: 20, fontWeight: FontWeight.bold)), Text(DateFormat('MMM', 'en').format(s.date).toUpperCase(), style: const TextStyle(color: navy, fontSize: 10, fontWeight: FontWeight.bold))])),
    const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.congregation.isEmpty ? 'Eskedyul sa Midweek nga Tigom' : s.congregation, style: const TextStyle(fontWeight: FontWeight.bold, color: navy)), const SizedBox(height: 3), Text(DateFormat('EEEE, MMMM d, y', 'en').format(s.date), style: const TextStyle(color: Colors.black54, fontSize: 12)), Text(s.bibleReading.isEmpty ? 'Wala pay senemanang pagbasa' : s.bibleReading, style: const TextStyle(fontSize: 12))])),
    PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') _open(s); if (v == 'copy') _open(s, true); if (v == 'delete') _delete(s); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Usbon')), PopupMenuItem(value: 'copy', child: Text('Kopyahon sa sunod nga semana')), PopupMenuItem(value: 'delete', child: Text('Papas-on'))]),
  ]))));
}

class ScheduleEditor extends StatefulWidget {
  const ScheduleEditor({super.key, required this.schedule});
  final MeetingSchedule schedule;
  @override State<ScheduleEditor> createState() => _ScheduleEditorState();
}
class _ScheduleEditorState extends State<ScheduleEditor> {
  late MeetingSchedule s;
  late final TextEditingController congregation, reading, chairman, openingSong, openingPrayer, intro,
    middleSong, conclusion, closingSong, closingPrayer;
  final ScreenshotController screenshotController = ScreenshotController();
  @override void initState() { super.initState(); s = widget.schedule; congregation = _c(s.congregation); reading = _c(s.bibleReading); chairman = _c(s.chairman); openingSong = _c(s.openingSong); openingPrayer = _c(s.openingPrayer); intro = _c(s.introduction); middleSong = _c(s.middleSong); conclusion = _c(s.conclusion); closingSong = _c(s.closingSong); closingPrayer = _c(s.closingPrayer); }
  TextEditingController _c(String v) => TextEditingController(text: v);
  @override void dispose() { for (final c in [congregation, reading, chairman, openingSong, openingPrayer, intro, middleSong, conclusion, closingSong, closingPrayer]) { c.dispose(); } super.dispose(); }
  void _sync() { s.congregation = congregation.text.trim(); s.bibleReading = reading.text.trim(); s.chairman = chairman.text.trim(); s.openingSong = openingSong.text.trim(); s.openingPrayer = openingPrayer.text.trim(); s.introduction = intro.text.trim(); s.middleSong = middleSong.text.trim(); s.conclusion = conclusion.text.trim(); s.closingSong = closingSong.text.trim(); s.closingPrayer = closingPrayer.text.trim(); }
  Future<void> _pickDate() async { final d = await showDatePicker(context: context, initialDate: s.date, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (d != null) setState(() => s.date = d); }
  void _save() { _sync(); Navigator.pop(context, s); }
  Future<void> _exportPdf() async { _sync(); final doc = pw.Document(); doc.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(28), build: (_) => _pdfSchedule(s))); await Printing.sharePdf(bytes: await doc.save(), filename: 'SC9_${DateFormat('yyyyMMdd').format(s.date)}.pdf'); }
  Future<void> _exportPng() async { _sync(); try { final Uint8List? bytes = await screenshotController.captureFromWidget(_schedulePreview(s), context: context, pixelRatio: 3); if (bytes == null) throw Exception('Walay nakuha nga hulagway.'); await Share.shareXFiles([XFile.fromData(bytes, mimeType: 'image/png', name: 'SC9_${DateFormat('yyyyMMdd').format(s.date)}.png')], text: 'Eskedyul sa Midweek nga Tigom'); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dili ma-export ang PNG: $e'))); } }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Usbon ang eskedyul', style: TextStyle(fontWeight: FontWeight.bold)), actions: [IconButton(tooltip: 'PDF', onPressed: _exportPdf, icon: const Icon(Icons.picture_as_pdf_outlined)), IconButton(tooltip: 'PNG', onPressed: _exportPng, icon: const Icon(Icons.image_outlined))]),
    bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Tipigi ang eskedyul'), style: FilledButton.styleFrom(backgroundColor: navy, padding: const EdgeInsets.symmetric(vertical: 15))))),
    body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      _sectionTitle('Impormasyon sa tigom'), Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
        InkWell(onTap: _pickDate, child: InputDecorator(decoration: const InputDecoration(labelText: 'Petsa', prefixIcon: Icon(Icons.calendar_today)), child: Text(DateFormat('EEEE, MMMM d, y', 'en').format(s.date)))),
        const SizedBox(height: 10), _field(congregation, 'Ngalan sa Kongregasyon'), const SizedBox(height: 10), _field(reading, 'Senemanang Pagbasa sa Bibliya'), const SizedBox(height: 10), _field(chairman, 'Tsirman'),
      ]))),
      _sectionTitle('Pasiuna'), Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
        Row(children: [Expanded(child: _field(openingSong, 'Awit [Numero]')), const SizedBox(width: 10), Expanded(child: _field(openingPrayer, 'Pag-ampo [Ngalan]'))]),
        const SizedBox(height: 10), _field(intro, 'Introduksiyon (minuto)', keyboard: TextInputType.number),
      ]))),
      _sectionTitle('Bahandi Gikan sa Pulong sa Diyos'), ...s.parts.take(3).map((p) => _partCard(p)),
      _sectionTitle('Magmaepektibo sa Ministeryo'), ...s.parts.skip(3).take(3).map((p) => _partCard(p, ministry: true)),
      _sectionTitle('Kristohanong Pagkinabuhi'), Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
        _field(middleSong, 'Awit [Numero]'), const SizedBox(height: 10), ...s.parts.skip(6).map((p) => _partFields(p)),
        const Divider(height: 24), _field(conclusion, 'Konklusyon (minuto)', keyboard: TextInputType.number), const SizedBox(height: 10),
        Row(children: [Expanded(child: _field(closingSong, 'Awit [Numero]')), const SizedBox(width: 10), Expanded(child: _field(closingPrayer, 'Pag-ampo [Ngalan]'))]),
      ]))),
      const SizedBox(height: 18), _sectionTitle('Preview sa eskedyul nga i-export'),
      Screenshot(controller: screenshotController, child: _schedulePreview(s)),
      const SizedBox(height: 12), const Text('Ang imong mga kausaban tipigon lamang kon mopislit ka sa “Tipigi ang eskedyul”.', style: TextStyle(color: Colors.black54, fontSize: 12)),
    ]));
  Widget _sectionTitle(String t) => Padding(padding: const EdgeInsets.fromLTRB(2, 20, 2, 8), child: Text(t.toUpperCase(), style: const TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: .5)));
  Widget _field(TextEditingController c, String label, {TextInputType? keyboard}) => TextField(controller: c, keyboardType: keyboard, decoration: InputDecoration(labelText: label, isDense: true));
  Widget _partCard(MeetingPart p, {bool ministry = false}) => Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(13), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('PART ${p.number}', style: const TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 11)), const SizedBox(height: 9), _partFields(p, ministry: ministry)])));
  Widget _partFields(MeetingPart p, {bool ministry = false}) => Column(children: [
    Row(children: [Expanded(child: TextFormField(initialValue: p.title, onChanged: (v) => p.title = v, decoration: InputDecoration(labelText: '${p.number}. Ulohan', isDense: true))), const SizedBox(width: 9), SizedBox(width: 88, child: TextFormField(initialValue: p.minutes, onChanged: (v) => p.minutes = v, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minuto', isDense: true)))]),
    if (ministry || p.number == 3) ...[const SizedBox(height: 9), Row(children: [Expanded(child: TextFormField(initialValue: p.student, onChanged: (v) => p.student = v, decoration: InputDecoration(labelText: ministry ? 'Estudyante' : 'Estudyante', isDense: true))), if (ministry) ...[const SizedBox(width: 9), Expanded(child: TextFormField(initialValue: p.assistant, onChanged: (v) => p.assistant = v, decoration: const InputDecoration(labelText: 'Asistant', isDense: true)))]] )],
    if (!ministry && p.number != 3) ...[const SizedBox(height: 9), TextFormField(initialValue: p.presenter, onChanged: (v) => p.presenter = v, decoration: InputDecoration(labelText: p.number == 10 ? 'Tigdumala' : 'Ngalan', isDense: true))],
    if (p.number == 10) ...[const SizedBox(height: 9), TextFormField(initialValue: p.assistant, onChanged: (v) => p.assistant = v, decoration: const InputDecoration(labelText: 'Tigbasa', isDense: true))],
  ]);

  Widget _schedulePreview(MeetingSchedule x) => Container(color: Colors.white, padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text(x.congregation.isEmpty ? '[NGALAN SA KONGREGASYON]' : x.congregation, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: navy)),
    const Text('Eskedyul sa Midweek nga Tigom', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8), Text('${DateFormat('MMMM d, y', 'en').format(x.date)}     SENEMANANG PAGBASA SA BIBLIYA: ${x.bibleReading}'), Text('Tsirman: ${x.chairman}'),
    const Divider(), Text('Awit ${x.openingSong}     Pag-ampo: ${x.openingPrayer}'), Text('Introduksiyon (${x.introduction} min.)'),
    ..._previewSection('BAHANDI GIKAN SA PULONG SA DIYOS', x.parts.take(3)),
    ..._previewSection('MAGMAEPEKTIBO SA MINISTERYO', x.parts.skip(3).take(3)),
    Text('KRISTOHANONG PAGKINABUHI', style: const TextStyle(fontWeight: FontWeight.bold, color: navy)), Text('Awit ${x.middleSong}'),
    ..._previewSection('', x.parts.skip(6)), Text('Konklusyon (${x.conclusion} min.)'), Text('Awit ${x.closingSong}     Pag-ampo: ${x.closingPrayer}'),
  ]));
  List<Widget> _previewSection(String heading, Iterable<MeetingPart> parts) => [if (heading.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 7), child: Text(heading, style: const TextStyle(fontWeight: FontWeight.bold, color: navy))), ...parts.map((p) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(_partLine(p), style: const TextStyle(fontSize: 11))))];
  String _partLine(MeetingPart p) {
    final names = p.number == 3 ? 'Estudyante: ${p.student}' :
      (p.number >= 5 && p.number <= 7) ? 'Estudyante/Asistant: ${p.student} / ${p.assistant}' :
      p.number == 10 ? 'Tigdumala/Tigbasa: ${p.presenter} / ${p.assistant}' : p.presenter;
    final marker = p.number == 7 ? '0:00    ' : '';
    return '$marker${p.number}. ${p.title} (${p.minutes} min.)  $names';
  }

  List<pw.Widget> _pdfSchedule(MeetingSchedule x) => [
    pw.Center(child: pw.Text(x.congregation.isEmpty ? '[NGALAN SA KONGREGASYON]' : x.congregation, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12))),
    pw.Center(child: pw.Text('Eskedyul sa Midweek nga Tigom', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18))),
    pw.SizedBox(height: 10), pw.Text('${DateFormat('MMMM d, y', 'en').format(x.date)}    SENEMANANG PAGBASA SA BIBLIYA: ${x.bibleReading}'), pw.Text('Tsirman: ${x.chairman}'),
    pw.Divider(), pw.Text('Awit ${x.openingSong}     Pag-ampo: ${x.openingPrayer}'), pw.Text('Introduksiyon (${x.introduction} min.)'),
    ..._pdfSection('BAHANDI GIKAN SA PULONG SA DIYOS', x.parts.take(3)),
    ..._pdfSection('MAGMAEPEKTIBO SA MINISTERYO', x.parts.skip(3).take(3)),
    pw.Text('KRISTOHANONG PAGKINABUHI', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('Awit ${x.middleSong}'),
    ..._pdfSection('', x.parts.skip(6)), pw.Text('Konklusyon (${x.conclusion} min.)'), pw.Text('Awit ${x.closingSong}     Pag-ampo: ${x.closingPrayer}'),
  ];
  List<pw.Widget> _pdfSection(String title, Iterable<MeetingPart> parts) => [if (title.isNotEmpty) pw.Padding(padding: const pw.EdgeInsets.only(top: 8), child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))), ...parts.map((p) => pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 3), child: pw.Text('${p.number}. ${p.title} (${p.minutes} min.)   Estudyante: ${p.student}   Asistant: ${p.assistant}   ${p.presenter}'))];
}
