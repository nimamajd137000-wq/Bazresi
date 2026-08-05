import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ExpertReporterApp());
}

class ExpertReporterApp extends StatelessWidget {
  const ExpertReporterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'گزارش‌گیری کارشناسان',
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: 'Vazir',
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class Report {
  final String id;
  final String expertName;
  final String personnelCode;
  final String date;
  final String time;
  final String activity;
  final int minutes;
  final String description;

  Report({
    required this.id,
    required this.expertName,
    required this.personnelCode,
    required this.date,
    required this.time,
    required this.activity,
    required this.minutes,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expertName': expertName,
      'personnelCode': personnelCode,
      'date': date,
      'time': time,
      'activity': activity,
      'minutes': minutes,
      'description': description,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] ?? '',
      expertName: map['expertName'] ?? '',
      personnelCode: map['personnelCode'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      activity: map['activity'] ?? '',
      minutes: map['minutes'] ?? 0,
      description: map['description'] ?? '',
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Report> reports = [];

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _activityController = TextEditingController();
  final _minutesController = TextEditingController();
  final _descController = TextEditingController();

  final List<String> commonActivities = [
    'پشتیبانی تلفنی',
    'رفع اشکال سیستم',
    'جلسه کاری',
    'توسعه نرم‌افزار',
    'مستندسازی',
    'آموزش کاربر',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('reports');

    if (raw != null) {
      final List decoded = json.decode(raw);

      setState(() {
        reports = decoded.map((e) => Report.fromMap(e)).toList();
      });
    }

    _nameController.text = prefs.getString('expertName') ?? '';
    _codeController.text = prefs.getString('personnelCode') ?? '';
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = json.encode(reports.map((e) => e.toMap()).toList());

    await prefs.setString('reports', encoded);
    await prefs.setString('expertName', _nameController.text);
    await prefs.setString('personnelCode', _codeController.text);
  }

  void _addReport() {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final act = _activityController.text.trim();
    final min = int.tryParse(_minutesController.text.trim()) ?? 0;
    final desc = _descController.text.trim();

    if (name.isEmpty || code.isEmpty || act.isEmpty || min <= 0) {
      _message('لطفاً اطلاعات ضروری را به درستی وارد کنید.');
      return;
    }

    final now = DateTime.now();
    final date = DateFormat('yyyy/MM/dd', 'fa').format(now);
    final time = DateFormat('HH:mm').format(now);

    final report = Report(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      expertName: name,
      personnelCode: code,
      date: date,
      time: time,
      activity: act,
      minutes: min,
      description: desc,
    );

    setState(() {
      reports.insert(0, report);
    });

    _save();

    _minutesController.clear();
    _descController.clear();

    _message('فعالیت ثبت شد.');
  }

  void _delete(String id) {
    setState(() {
      reports.removeWhere((r) => r.id == id);
    });

    _save();

    _message('گزارش حذف شد.');
  }

  void _message(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> exportExcel() async {
    if (reports.isEmpty) {
      _message('گزارشی برای خروجی وجود ندارد.');
      return;
    }

    final List<List<dynamic>> rows = [
      [
        'شناسه',
        'نام کارشناس',
        'کد پرسنلی',
        'تاریخ',
        'زمان',
        'فعالیت',
        'مدت (دقیقه)',
        'توضیحات'
      ],
    ];

    for (var r in reports) {
      rows.add([
        r.id,
        r.expertName,
        r.personnelCode,
        r.date,
        r.time,
        r.activity,
        r.minutes,
        r.description,
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    final dir = await getTemporaryDirectory();

    final path = '${dir.path}/expert_report_${DateTime.now().millisecondsSinceEpoch}.csv';

    final file = File(path);

    await file.writeAsString(csv, encoding: utf8);

    await Share.shareXFiles([XFile(path)], text: 'گزارش فعالیت کارشناس');
  }

  Future<void> importExpertExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null) return;

    final path = result.files.single.path;

    if (path == null) {
      _message('فایل انتخاب‌شده قابل دسترسی نیست.');
      return;
    }

    try {
      final text = await File(path).readAsString(
        encoding: utf8,
      );

      final rows = const CsvToListConverter().convert(text);

      if (rows.length < 2) {
        _message('فایل گزارش خالی است.');
        return;
      }

      int imported = 0;
      int duplicated = 0;

      final existingIds = reports.map((r) => r.id).toSet();

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        if (row.length < 8) continue;

        final id = '${row[0]}';

        if (id.isEmpty) continue;

        if (existingIds.contains(id)) {
          duplicated++;
          continue;
        }

        final report = Report(
          id: id,
          expertName: '${row[1]}',
          personnelCode: '${row[2]}',
          date: '${row[3]}',
          time: '${row[4]}',
          activity: '${row[5]}',
          minutes: int.tryParse('${row[6]}') ?? 0,
          description: '${row[7]}',
        );

        reports.add(report);
        existingIds.add(id);
        imported++;
      }

      await _save();

      setState(() {});

      _message(
        '$imported فعالیت وارد شد. '
        '${duplicated > 0 ? '$duplicated مورد تکراری بود.' : ''}',
      );
    } catch (e) {
      _message('خطا در خواندن فایل گزارش.');
    }
  }

  int get totalMinutes {
    return reports.fold(0, (sum, r) => sum + r.minutes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت گزارش کارشناسان'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'ورود از فایل',
            onPressed: importExpertExcel,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'خروجی اکسل / اشتراک',
            onPressed: exportExcel,
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'مشخصات کارشناس',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'نام کارشناس',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'کد پرسنلی',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ثبت فعالیت جدید',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _activityController,
                        decoration: const InputDecoration(
                          labelText: 'عنوان فعالیت',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: commonActivities.map((act) {
                          return ActionChip(
                            label: Text(act),
                            onPressed: () {
                              _activityController.text = act;
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _minutesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'مدت زمان (دقیقه)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'توضیحات تکمیلی',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('ثبت گزارش'),
                          onPressed: _addReport,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.indigo.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('تعداد فعالیت‌ها: ${reports.length}'),
                      Text('مجموع زمان: $totalMinutes دقیقه'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final item = reports[index];
                  return Card(
                    child: ListTile(
                      title: Text(item.activity),
                      subtitle: Text(
                        '${item.expertName} | ${item.date} - ${item.time}\n'
                        '${item.description}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${item.minutes} د'),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _delete(item.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
