import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

void main() {
runApp(const InspectionReportApp());
}

class InspectionReportApp extends StatelessWidget {
const InspectionReportApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'گزارشات مدیریت بازرسی',
theme: ThemeData(
useMaterial3: true,
fontFamily: 'sans',
colorScheme: ColorScheme.fromSeed(
seedColor: const Color(0xFF123B5D),
),
scaffoldBackgroundColor: const Color(0xFFF4F7FA),
),
home: const LoginPage(),
);
}
}

// ------------------------------------------------------------
// مدل فعالیت
// ------------------------------------------------------------

class ActivityItem {
String title;
String description;
String date;
String time;

ActivityItem({
required this.title,
required this.description,
required this.date,
required this.time,
});

Map<String, dynamic> toMap() {
return {
'title': title,
'description': description,
'date': date,
'time': time,
};
}

factory ActivityItem.fromMap(Map<String, dynamic> map) {
return ActivityItem(
title: map['title']?.toString() ?? '',
description: map['description']?.toString() ?? '',
date: map['date']?.toString() ?? '',
time: map['time']?.toString() ?? '',
);
}
}

// ------------------------------------------------------------
// گزارش
// ------------------------------------------------------------

class Report {
String id;
String expertName;
String personnelCode;
String reportDate;
List<ActivityItem> activities;
String status;

Report({
required this.id,
required this.expertName,
required this.personnelCode,
required this.reportDate,
required this.activities,
required this.status,
});

Map<String, dynamic> toMap() {
return {
'id': id,
'expertName': expertName,
'personnelCode': personnelCode,
'reportDate': reportDate,
'activities': activities.map((e) => e.toMap()).toList(),
'status': status,
};
}

factory Report.fromMap(Map<String, dynamic> map) {
final rawActivities = map['activities'];

```
final List<ActivityItem> activities = [];

if (rawActivities is List) {
  for (final item in rawActivities) {
    if (item is Map) {
      activities.add(
        ActivityItem.fromMap(
          Map<String, dynamic>.from(item),
        ),
      );
    }
  }
}

return Report(
  id: map['id']?.toString() ?? '',
  expertName: map['expertName']?.toString() ?? '',
  personnelCode: map['personnelCode']?.toString() ?? '',
  reportDate: map['reportDate']?.toString() ?? '',
  activities: activities,
  status: map['status']?.toString() ?? 'ارسال شده',
);
```

}
}

// ------------------------------------------------------------
// ذخیره‌سازی
// ------------------------------------------------------------

class StorageService {
static const String reportsKey = 'reports';

static Future<List<Report>> getReports() async {
final prefs = await SharedPreferences.getInstance();
final raw = prefs.getString(reportsKey);

```
if (raw == null || raw.isEmpty) {
  return [];
}

try {
  final decoded = jsonDecode(raw);

  if (decoded is! List) {
    return [];
  }

  return decoded
      .whereType<Map>()
      .map(
        (e) => Report.fromMap(
          Map<String, dynamic>.from(e),
        ),
      )
      .toList();
} catch (_) {
  return [];
}
```

}

static Future<void> saveReports(List<Report> reports) async {
final prefs = await SharedPreferences.getInstance();

```
final data = reports.map((e) => e.toMap()).toList();

await prefs.setString(
  reportsKey,
  jsonEncode(data),
);
```

}

static Future<void> addReport(Report report) async {
final reports = await getReports();
reports.add(report);
await saveReports(reports);
}
}

// ------------------------------------------------------------
// ورود
// ------------------------------------------------------------

class LoginPage extends StatefulWidget {
const LoginPage({super.key});

@override
State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
final passwordController = TextEditingController();

bool obscure = true;

void login() {
final password = passwordController.text.trim();

```
if (password == '1234') {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const HomePage(),
    ),
  );
  return;
}

ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('رمز عبور اشتباه است'),
  ),
);
```

}

@override
Widget build(BuildContext context) {
return Scaffold(
body: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.all(24),
child: Card(
elevation: 4,
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.admin_panel_settings,
size: 70,
color: Color(0xFF123B5D),
),
const SizedBox(height: 15),
const Text(
'گزارشات مدیریت بازرسی',
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 8),
const Text('ورود به سامانه'),
const SizedBox(height: 25),
TextField(
controller: passwordController,
obscureText: obscure,
decoration: InputDecoration(
labelText: 'رمز عبور',
prefixIcon: const Icon(Icons.lock),
suffixIcon: IconButton(
onPressed: () {
setState(() {
obscure = !obscure;
});
},
icon: Icon(
obscure
? Icons.visibility
: Icons.visibility_off,
),
),
border: const OutlineInputBorder(),
),
onSubmitted: (_) => login(),
),
const SizedBox(height: 20),
SizedBox(
width: double.infinity,
child: FilledButton.icon(
onPressed: login,
icon: const Icon(Icons.login),
label: const Padding(
padding: EdgeInsets.all(12),
child: Text('ورود'),
),
),
),
const SizedBox(height: 10),
const Text(
'رمز پیش‌فرض: 1234',
style: TextStyle(
color: Colors.grey,
),
),
],
),
),
),
),
),
);
}
}

// ------------------------------------------------------------
// صفحه اصلی
// ------------------------------------------------------------

class HomePage extends StatefulWidget {
const HomePage({super.key});

@override
State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
int index = 0;

final pages = const [
DashboardPage(),
ExpertPage(),
ManagerPage(),
StatisticsPage(),
SettingsPage(),
];

final titles = const [
'گزارشات مدیریت بازرسی',
'ثبت گزارش کارشناس',
'پنل مدیر',
'آمار و نمودار',
'تنظیمات',
];

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: Text(
titles[index],
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
centerTitle: true,
),
body: pages[index],
bottomNavigationBar: NavigationBar(
selectedIndex: index,
onDestinationSelected: (value) {
setState(() {
index = value;
});
},
destinations: const [
NavigationDestination(
icon: Icon(Icons.dashboard_outlined),
selectedIcon: Icon(Icons.dashboard),
label: 'خانه',
),
NavigationDestination(
icon: Icon(Icons.person_outline),
selectedIcon: Icon(Icons.person),
label: 'کارشناس',
),
NavigationDestination(
icon: Icon(Icons.manage_accounts_outlined),
selectedIcon: Icon(Icons.manage_accounts),
label: 'مدیر',
),
NavigationDestination(
icon: Icon(Icons.bar_chart_outlined),
selectedIcon: Icon(Icons.bar_chart),
label: 'آمار',
),
NavigationDestination(
icon: Icon(Icons.settings_outlined),
selectedIcon: Icon(Icons.settings),
label: 'تنظیمات',
),
],
),
);
}
}

// ------------------------------------------------------------
// داشبورد
// ------------------------------------------------------------

class DashboardPage extends StatelessWidget {
const DashboardPage({super.key});

@override
Widget build(BuildContext context) {
return FutureBuilder<List<Report>>(
future: StorageService.getReports(),
builder: (context, snapshot) {
final reports = snapshot.data ?? [];

```
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFF123B5D),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سامانه گزارشات مدیریت بازرسی',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'مدیریت، ثبت و تجمیع گزارش فعالیت کارشناسان',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _DashboardCard(
                title: 'گزارش‌ها',
                value: reports.length.toString(),
                icon: Icons.description,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DashboardCard(
                title: 'فعالیت‌ها',
                value: reports
                    .fold<int>(
                      0,
                      (sum, report) =>
                          sum + report.activities.length,
                    )
                    .toString(),
                icon: Icons.task_alt,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('نحوه استفاده'),
            subtitle: const Text(
              'کارشناس از بخش ثبت گزارش، فعالیت‌های روزانه خود را وارد و گزارش را ارسال می‌کند. مدیر می‌تواند گزارش‌ها را مشاهده و به Excel صادر کند.',
            ),
          ),
        ),
      ],
    );
  },
);
```

}
}

class _DashboardCard extends StatelessWidget {
final String title;
final String value;
final IconData icon;

const _DashboardCard({
required this.title,
required this.value,
required this.icon,
});

@override
Widget build(BuildContext context) {
return Card(
child: Padding(
padding: const EdgeInsets.all(18),
child: Column(
children: [
Icon(
icon,
size: 36,
color: const Color(0xFF123B5D),
),
const SizedBox(height: 8),
Text(
value,
style: const TextStyle(
fontSize: 25,
fontWeight: FontWeight.bold,
),
),
Text(title),
],
),
),
);
}
}

// ------------------------------------------------------------
// ثبت گزارش کارشناس
// ------------------------------------------------------------

class ExpertPage extends StatefulWidget {
const ExpertPage({super.key});

@override
State<ExpertPage> createState() => _ExpertPageState();
}

class _ExpertPageState extends State<ExpertPage> {
final expertNameController = TextEditingController();
final personnelController = TextEditingController();

final List<ActivityItem> activities = [];

String activityTitle = 'بازرسی';
final descriptionController = TextEditingController();

final activityTitles = const [
'بازرسی',
'بازدید',
'بررسی پرونده',
'تنظیم گزارش',
'جلسه',
'مکاتبه اداری',
'پاسخگویی',
'پیگیری',
'نظارت',
'سایر',
];

void addActivity() {
if (descriptionController.text.trim().isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('شرح فعالیت را وارد کنید'),
),
);
return;
}

```
final now = DateTime.now();

final date = DateFormat(
  'yyyy/MM/dd',
).format(now);

final time = DateFormat(
  'HH:mm',
).format(now);

setState(() {
  activities.add(
    ActivityItem(
      title: activityTitle,
      description: descriptionController.text.trim(),
      date: date,
      time: time,
    ),
  );

  descriptionController.clear();
});
```

}

Future<void> saveReport() async {
if (expertNameController.text.trim().isEmpty ||
personnelController.text.trim().isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('نام کارشناس و کد پرسنلی را وارد کنید'),
),
);
return;
}

```
if (activities.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('حداقل یک فعالیت ثبت کنید'),
    ),
  );
  return;
}

final now = DateTime.now();

final report = Report(
  id: 'REP-${now.millisecondsSinceEpoch}',
  expertName: expertNameController.text.trim(),
  personnelCode: personnelController.text.trim(),
  reportDate: DateFormat('yyyy/MM/dd').format(now),
  activities: List.from(activities),
  status: 'ارسال شده',
);

await StorageService.addReport(report);

setState(() {
  activities.clear();
});

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      'گزارش با کد ${report.id} ارسال شد',
    ),
  ),
);
```

}

@override
Widget build(BuildContext context) {
return ListView(
padding: const EdgeInsets.all(16),
children: [
const Text(
'اطلاعات کارشناس',
style: TextStyle(
fontSize: 19,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 12),
TextField(
controller: expertNameController,
decoration: const InputDecoration(
labelText: 'نام و نام خانوادگی',
prefixIcon: Icon(Icons.person),
border: OutlineInputBorder(),
),
),
const SizedBox(height: 12),
TextField(
controller: personnelController,
decoration: const InputDecoration(
labelText: 'کد پرسنلی',
prefixIcon: Icon(Icons.badge),
border: OutlineInputBorder(),
),
),
const SizedBox(height: 25),
const Text(
'ثبت فعالیت',
style: TextStyle(
fontSize: 19,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 12),
DropdownButtonFormField<String>(
value: activityTitle,
decoration: const InputDecoration(
labelText: 'عنوان فعالیت',
border: OutlineInputBorder(),
),
items: activityTitles
.map(
(title) => DropdownMenuItem(
value: title,
child: Text(title),
),
)
.toList(),
onChanged: (value) {
if (value != null) {
setState(() {
activityTitle = value;
});
}
},
),
const SizedBox(height: 12),
TextField(
controller: descriptionController,
maxLines: 4,
decoration: const InputDecoration(
labelText: 'شرح و جزئیات فعالیت',
border: OutlineInputBorder(),
),
),
const SizedBox(height: 12),
FilledButton.icon(
onPressed: addActivity,
icon: const Icon(Icons.add),
label: const Text('افزودن فعالیت'),
),
const SizedBox(height: 20),
if (activities.isNotEmpty)
...activities.asMap().entries.map(
(entry) {
final number = entry.key + 1;
final activity = entry.value;

```
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(number.toString()),
              ),
              title: Text(
                activity.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${activity.description}\n${activity.date} - ${activity.time}',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  setState(() {
                    activities.removeAt(entry.key);
                  });
                },
              ),
            ),
          );
        },
      ),
    const SizedBox(height: 15),
    FilledButton.icon(
      onPressed: saveReport,
      icon: const Icon(Icons.send),
      label: const Padding(
        padding: EdgeInsets.all(13),
        child: Text('ارسال گزارش به مدیر'),
      ),
    ),
  ],
);
```

}
}

// ------------------------------------------------------------
// پنل مدیر
// ------------------------------------------------------------

class ManagerPage extends StatefulWidget {
const ManagerPage({super.key});

@override
State<ManagerPage> createState() => _ManagerPageState();
}

class _ManagerPageState extends State<ManagerPage> {
String search = '';

Future<void> exportExcel() async {
final reports = await StorageService.getReports();

```
if (reports.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('گزارشی برای خروجی وجود ندارد'),
    ),
  );
  return;
}

final excel = Excel.createExcel();

final sheet = excel['گزارشات'];

sheet.appendRow([
  TextCellValue('کد گزارش'),
  TextCellValue('نام کارشناس'),
  TextCellValue('کد پرسنلی'),
  TextCellValue('تاریخ گزارش'),
  TextCellValue('شماره فعالیت'),
  TextCellValue('عنوان فعالیت'),
  TextCellValue('شرح فعالیت'),
  TextCellValue('تاریخ فعالیت'),
  TextCellValue('ساعت فعالیت'),
  TextCellValue('وضعیت'),
]);

for (final report in reports) {
  for (int i = 0; i < report.activities.length; i++) {
    final activity = report.activities[i];

    sheet.appendRow([
      TextCellValue(report.id),
      TextCellValue(report.expertName),
      TextCellValue(report.personnelCode),
      TextCellValue(report.reportDate),
      IntCellValue(i + 1),
      TextCellValue(activity.title),
      TextCellValue(activity.description),
      TextCellValue(activity.date),
      TextCellValue(activity.time),
      TextCellValue(report.status),
    ]);
  }
}

final bytes = excel.save();

if (bytes == null) {
  return;
}

final directory =
    await getApplicationDocumentsDirectory();

final file = File(
  '${directory.path}/inspection_reports.xlsx',
);

await file.writeAsBytes(bytes, flush: true);

await SharePlus.instance.share(
  ShareParams(
    files: [
      XFile(file.path),
    ],
    text: 'خروجی گزارشات مدیریت بازرسی',
  ),
);
```

}

@override
Widget build(BuildContext context) {
return FutureBuilder<List<Report>>(
future: StorageService.getReports(),
builder: (context, snapshot) {
final allReports = snapshot.data ?? [];

```
    final reports = allReports.where((report) {
      if (search.trim().isEmpty) {
        return true;
      }

      final q = search.trim().toLowerCase();

      return report.id.toLowerCase().contains(q) ||
          report.expertName.toLowerCase().contains(q) ||
          report.personnelCode.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'جستجو',
              hintText: 'کد گزارش، نام کارشناس یا کد پرسنلی',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                search = value;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: exportExcel,
              icon: const Icon(Icons.table_view),
              label: const Text('خروجی Excel'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: reports.isEmpty
              ? const Center(
                  child: Text(
                    'گزارشی ثبت نشده است',
                  ),
                )
              : ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ExpansionTile(
                        title: Text(
                          report.expertName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${report.id}\n${report.reportDate} | ${report.activities.length} فعالیت',
                        ),
                        children: [
                          ...report.activities.asMap().entries.map(
                            (entry) {
                              final activity = entry.value;

                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    '${entry.key + 1}',
                                  ),
                                ),
                                title: Text(
                                  activity.title,
                                ),
                                subtitle: Text(
                                  '${activity.description}\n${activity.date} - ${activity.time}',
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  },
);
```

}
}

// ------------------------------------------------------------
// آمار
// ------------------------------------------------------------

class StatisticsPage extends StatelessWidget {
const StatisticsPage({super.key});

@override
Widget build(BuildContext context) {
return FutureBuilder<List<Report>>(
future: StorageService.getReports(),
builder: (context, snapshot) {
final reports = snapshot.data ?? [];

```
    int totalActivities = 0;

    final Map<String, int> activityCounts = {};

    for (final report in reports) {
      totalActivities += report.activities.length;

      for (final activity in report.activities) {
        activityCounts[activity.title] =
            (activityCounts[activity.title] ?? 0) + 1;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatBox(
          title: 'تعداد گزارش‌ها',
          value: reports.length.toString(),
          icon: Icons.description,
        ),
        _StatBox(
          title: 'تعداد کل فعالیت‌ها',
          value: totalActivities.toString(),
          icon: Icons.task,
        ),
        _StatBox(
          title: 'تعداد کارشناسان',
          value: reports
              .map((e) => e.personnelCode)
              .toSet()
              .length
              .toString(),
          icon: Icons.people,
        ),
        const SizedBox(height: 20),
        const Text(
          'توزیع فعالیت‌ها',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (activityCounts.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'هنوز فعالیتی ثبت نشده است.',
              ),
            ),
          )
        else
          ...activityCounts.entries.map(
            (entry) => Card(
              child: ListTile(
                title: Text(entry.key),
                trailing: CircleAvatar(
                  child: Text(
                    entry.value.toString(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  },
);
```

}
}

class _StatBox extends StatelessWidget {
final String title;
final String value;
final IconData icon;

const _StatBox({
required this.title,
required this.value,
required this.icon,
});

@override
Widget build(BuildContext context) {
return Card(
child: ListTile(
leading: Icon(
icon,
size: 38,
color: const Color(0xFF123B5D),
),
title: Text(title),
trailing: Text(
value,
style: const TextStyle(
fontSize: 25,
fontWeight: FontWeight.bold,
),
),
),
);
}
}

// ------------------------------------------------------------
// تنظیمات
// ------------------------------------------------------------

class SettingsPage extends StatelessWidget {
const SettingsPage({super.key});

@override
Widget build(BuildContext context) {
return ListView(
padding: const EdgeInsets.all(16),
children: [
Card(
child: ListTile(
leading: const Icon(Icons.lock),
title: const Text('رمز ورود'),
subtitle: const Text(
'رمز فعلی نسخه آزمایشی: 1234',
),
),
),
Card(
child: ListTile(
leading: const Icon(Icons.info_outline),
title: const Text('درباره برنامه'),
subtitle: const Text(
'سامانه گزارشات مدیریت بازرسی',
),
),
),
],
);
}
}
