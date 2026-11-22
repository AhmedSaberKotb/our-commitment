
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = TaskStore();
  await store.load();
  runApp(OurCommitmentApp(store: store));
}

enum TaskOwner { shared, me, friend }
enum Frequency { daily, alternate, weekly, saturday, friday, once }

class TaskItem {
  TaskItem({
    required this.id,
    required this.title,
    required this.owner,
    required this.frequency,
    required this.points,
    this.category = 'عام',
    this.active = true,
  });

  final String id;
  String title;
  TaskOwner owner;
  Frequency frequency;
  int points;
  String category;
  bool active;

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'owner': owner.name,
    'frequency': frequency.name, 'points': points,
    'category': category, 'active': active,
  };

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
    id: j['id'], title: j['title'],
    owner: TaskOwner.values.firstWhere((e) => e.name == j['owner'], orElse: () => TaskOwner.me),
    frequency: Frequency.values.firstWhere((e) => e.name == j['frequency'], orElse: () => Frequency.daily),
    points: j['points'] ?? 1, category: j['category'] ?? 'عام',
    active: j['active'] ?? true,
  );
}

class TaskStore extends ChangeNotifier {
  static const _tasksKey = 'tasks_v1';
  static const _doneKey = 'done_v1';
  List<TaskItem> tasks = [];
  Map<String, bool> completions = {};

  String dayKey([DateTime? value]) {
    final d = value ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String completionKey(String taskId, [DateTime? day]) => '${dayKey(day)}::$taskId';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final rawTasks = p.getString(_tasksKey);
    final rawDone = p.getString(_doneKey);
    if (rawTasks != null) {
      tasks = (jsonDecode(rawTasks) as List).map((e) => TaskItem.fromJson(e)).toList();
    } else {
      tasks = _starterTasks();
      await save();
    }
    if (rawDone != null) {
      completions = Map<String, bool>.from(jsonDecode(rawDone));
    }
    notifyListeners();
  }

  List<TaskItem> _starterTasks() => [
    TaskItem(id: 'fajr', title: 'صلاة الفجر', owner: TaskOwner.shared, frequency: Frequency.daily, points: 1, category: 'عبادات'),
    TaskItem(id: 'dhuhr', title: 'صلاة الظهر', owner: TaskOwner.shared, frequency: Frequency.daily, points: 1, category: 'عبادات'),
    TaskItem(id: 'asr', title: 'صلاة العصر', owner: TaskOwner.shared, frequency: Frequency.daily, points: 1, category: 'عبادات'),
    TaskItem(id: 'maghrib', title: 'صلاة المغرب', owner: TaskOwner.shared, frequency: Frequency.daily, points: 1, category: 'عبادات'),
    TaskItem(id: 'isha', title: 'صلاة العشاء', owner: TaskOwner.shared, frequency: Frequency.daily, points: 1, category: 'عبادات'),
    TaskItem(id: 'duha', title: 'صلاة الضحى', owner: TaskOwner.shared, frequency: Frequency.daily, points: 1, category: 'عبادات'),
    TaskItem(id: 'rawatib', title: '12 ركعة نوافل', owner: TaskOwner.shared, frequency: Frequency.daily, points: 2, category: 'عبادات'),
    TaskItem(id: 'adhkar', title: 'أذكار الصباح والمساء', owner: TaskOwner.shared, frequency: Frequency.daily, points: 2, category: 'ذكر'),
    TaskItem(id: 'quran', title: 'ورد القرآن – 4 أوجه', owner: TaskOwner.shared, frequency: Frequency.daily, points: 2, category: 'قرآن'),
    TaskItem(id: 'dhikr', title: 'ورد الذكر – 5 أذكار', owner: TaskOwner.shared, frequency: Frequency.daily, points: 2, category: 'ذكر'),
    TaskItem(id: 'series', title: 'سلسلة رعاية الصلاة – 15 دقيقة', owner: TaskOwner.shared, frequency: Frequency.daily, points: 1, category: 'تعلم'),
    TaskItem(id: 'book', title: 'قراءة لأنك الله – 5 صفحات', owner: TaskOwner.shared, frequency: Frequency.daily, points: 1, category: 'قراءة'),
    TaskItem(id: 'night', title: 'قيام الليل – ركعتان', owner: TaskOwner.shared, frequency: Frequency.daily, points: 1, category: 'عبادات'),
    TaskItem(id: 'aqeedah', title: 'محاضرة في العقيدة', owner: TaskOwner.shared, frequency: Frequency.saturday, points: 4, category: 'تعلم'),
    TaskItem(id: 'study', title: 'مذاكرة يومية', owner: TaskOwner.me, frequency: Frequency.daily, points: 3, category: 'تعلم'),
    TaskItem(id: 'memorize', title: 'حفظ القرآن', owner: TaskOwner.me, frequency: Frequency.daily, points: 2, category: 'قرآن'),
    TaskItem(id: 'friend_review', title: 'مراجعة القرآن – ساعتان', owner: TaskOwner.friend, frequency: Frequency.daily, points: 6, category: 'قرآن'),
    TaskItem(id: 'tajweed', title: 'مذاكرة التجويد', owner: TaskOwner.friend, frequency: Frequency.alternate, points: 2, category: 'تعلم'),
  ];

  bool isDue(TaskItem t, [DateTime? now]) {
    final d = now ?? DateTime.now();
    switch (t.frequency) {
      case Frequency.daily: return true;
      case Frequency.alternate:
        final epoch = DateTime(2026, 11, 22);
        return (DateTime(d.year, d.month, d.day).difference(epoch).inDays % 2) == 0;
      case Frequency.weekly:
      case Frequency.friday: return d.weekday == DateTime.friday;
      case Frequency.saturday: return d.weekday == DateTime.saturday;
      case Frequency.once: return true;
    }
  }

  bool isDone(TaskItem t) => completions[completionKey(t.id)] ?? false;
  Future<void> toggle(TaskItem t) async {
    final key = completionKey(t.id);
    completions[key] = !(completions[key] ?? false);
    await save();
    notifyListeners();
  }

  int get earned => tasks.where((t) => t.active && isDue(t) && isDone(t)).fold(0, (a, t) => a + t.points);
  int get possible => tasks.where((t) => t.active && isDue(t)).fold(0, (a, t) => a + t.points);
  double get rate => possible == 0 ? 0 : earned / possible;

  Future<void> addOrUpdate(TaskItem t) async {
    final i = tasks.indexWhere((x) => x.id == t.id);
    if (i < 0) { tasks.add(t); } else { tasks[i] = t; }
    await save(); notifyListeners();
  }
  Future<void> archive(TaskItem t) async {
    t.active = false;
    await save(); notifyListeners();
  }
  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_tasksKey, jsonEncode(tasks.map((e) => e.toJson()).toList()));
    await p.setString(_doneKey, jsonEncode(completions));
  }
}

class OurCommitmentApp extends StatelessWidget {
  const OurCommitmentApp({super.key, required this.store});
  final TaskStore store;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Our Commitment',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff237a57), brightness: Brightness.light), useMaterial3: true, fontFamily: 'Arial'),
    home: Directionality(textDirection: TextDirection.rtl, child: MainScreen(store: store)),
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.store});
  final TaskStore store;
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int tab = 0;
  @override
  void initState() { super.initState(); widget.store.addListener(_refresh); }
  @override
  void dispose() { widget.store.removeListener(_refresh); super.dispose(); }
  void _refresh() { if (mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) {
    final titles = ['الرئيسية', 'المهام', 'الإحصائيات', 'الإعدادات'];
    return Scaffold(
      appBar: AppBar(title: Text('Our Commitment · ${titles[tab]}'), centerTitle: true),
      body: IndexedStack(index: tab, children: [
        Dashboard(store: widget.store),
        TasksPage(store: widget.store),
        StatsPage(store: widget.store),
        SettingsPage(store: widget.store),
      ]),
      floatingActionButton: tab == 1 ? FloatingActionButton.extended(
        onPressed: () => showTaskEditor(context, widget.store),
        icon: const Icon(Icons.add), label: const Text('إضافة مهمة'),
      ) : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'المهام'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'الإحصائيات'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key, required this.store});
  final TaskStore store;
  @override
  Widget build(BuildContext context) {
    final due = store.tasks.where((t) => t.active && store.isDue(t)).toList();
    final done = due.where(store.isDone).length;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('أهلاً بيك 👋', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text('خطوة ثابتة كل يوم أفضل من اندفاع مؤقت.', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 18),
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('إنجاز اليوم'),
        const SizedBox(height: 8),
        Row(children: [
          Text('${(store.rate * 100).round()}%', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: const Color(0xff237a57), fontWeight: FontWeight.bold)),
          const Spacer(), Text('${store.earned} / ${store.possible} نقطة'),
        ]),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: store.rate, minHeight: 9, borderRadius: BorderRadius.circular(20)),
        const SizedBox(height: 8),
        Text('$done من ${due.length} مهمة مكتملة'),
      ]))),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('مهام اليوم', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        TextButton(onPressed: () {}, child: const Text('')),
      ]),
      ...due.map((t) => TaskTile(task: t, store: store)),
    ]);
  }
}

class TasksPage extends StatelessWidget {
  const TasksPage({super.key, required this.store});
  final TaskStore store;
  @override
  Widget build(BuildContext context) {
    final active = store.tasks.where((t) => t.active).toList();
    return ListView(padding: const EdgeInsets.all(12), children: [
      Text('إدارة المهام', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('اضغط على المهمة لتعديلها، أو استخدم القائمة لأرشفتها.'),
      const SizedBox(height: 12),
      for (final group in TaskOwner.values) ...[
        Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(ownerLabel(group), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
        ...active.where((t) => t.owner == group).map((t) => Card(child: ListTile(
          title: Text(t.title),
          subtitle: Text('${frequencyLabel(t.frequency)} · ${t.points} نقاط'),
          leading: CircleAvatar(child: Icon(group == TaskOwner.shared ? Icons.people : Icons.person)),
          onTap: () => showTaskEditor(context, store, existing: t),
          trailing: PopupMenuButton<String>(
            onSelected: (v) { if (v == 'edit') showTaskEditor(context, store, existing: t); if (v == 'archive') store.archive(t); },
            itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('تعديل')), PopupMenuItem(value: 'archive', child: Text('أرشفة'))],
          ),
        ))),
      ],
    ]);
  }
}

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, required this.store});
  final TaskItem task;
  final TaskStore store;
  @override
  Widget build(BuildContext context) => Card(
    child: CheckboxListTile(
      value: store.isDone(task),
      onChanged: (_) => store.toggle(task),
      title: Text(task.title, style: TextStyle(decoration: store.isDone(task) ? TextDecoration.lineThrough : null)),
      subtitle: Text('${ownerLabel(task.owner)} · ${task.points} نقاط'),
      secondary: const Icon(Icons.task_alt),
      controlAffinity: ListTileControlAffinity.leading,
    ),
  );
}

class StatsPage extends StatelessWidget {
  const StatsPage({super.key, required this.store});
  final TaskStore store;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Text('إحصائيات اليوم', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    Card(child: ListTile(leading: const Icon(Icons.stars), title: const Text('النقاط المكتسبة'), trailing: Text('${store.earned}'))),
    Card(child: ListTile(leading: const Icon(Icons.flag), title: const Text('النقاط المستهدفة'), trailing: Text('${store.possible}'))),
    Card(child: ListTile(leading: const Icon(Icons.percent), title: const Text('نسبة الإنجاز'), trailing: Text('${(store.rate * 100).round()}%'))),
    const SizedBox(height: 12),
    const Text('المقارنة الأسبوعية والمزامنة بين الجهازين ستكون ضمن المرحلة التالية بعد ربط الحسابين.'),
  ]);
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.store});
  final TaskStore store;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: const [
    Text('الإعدادات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    SizedBox(height: 12),
    ListTile(leading: Icon(Icons.cloud_sync), title: Text('المزامنة'), subtitle: Text('غير مفعّلة في النسخة التجريبية المحلية')),
    ListTile(leading: Icon(Icons.wifi_off), title: Text('العمل بدون إنترنت'), subtitle: Text('الحفظ المحلي مفعّل')),
    ListTile(leading: Icon(Icons.schedule), title: Text('إغلاق اليوم'), subtitle: Text('12:00 منتصف الليل · توقيت مصر')),
    ListTile(leading: Icon(Icons.backup), title: Text('النسخ الاحتياطي'), subtitle: Text('سيضاف التصدير والاستيراد في المرحلة التالية')),
  ]);
}

Future<void> showTaskEditor(BuildContext context, TaskStore store, {TaskItem? existing}) async {
  final title = TextEditingController(text: existing?.title ?? '');
  var owner = existing?.owner ?? TaskOwner.me;
  var frequency = existing?.frequency ?? Frequency.daily;
  var points = existing?.points ?? 2;
  var category = existing?.category ?? 'عام';
  await showModalBottomSheet(
    context: context, isScrollControlled: true, showDragHandle: true,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 8, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(existing == null ? 'إضافة مهمة' : 'تعديل المهمة', style: Theme.of(ctx).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(controller: title, decoration: const InputDecoration(labelText: 'اسم المهمة', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        DropdownButtonFormField<TaskOwner>(value: owner, decoration: const InputDecoration(labelText: 'صاحب المهمة'), items: TaskOwner.values.map((e) => DropdownMenuItem(value: e, child: Text(ownerLabel(e)))).toList(), onChanged: (v) => setLocal(() => owner = v ?? owner)),
        const SizedBox(height: 12),
        DropdownButtonFormField<Frequency>(value: frequency, decoration: const InputDecoration(labelText: 'التكرار'), items: Frequency.values.map((e) => DropdownMenuItem(value: e, child: Text(frequencyLabel(e)))).toList(), onChanged: (v) => setLocal(() => frequency = v ?? frequency)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'التصنيف'), items: ['عام','عبادات','ذكر','قرآن','تعلم','قراءة','صحة','تطوير شخصي'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setLocal(() => category = v ?? category)),
        const SizedBox(height: 8),
        Row(children: [const Text('النقاط'), const Spacer(), IconButton(onPressed: () => setLocal(() => points = (points - 1).clamp(1, 8).toInt()), icon: const Icon(Icons.remove_circle_outline)), Text('$points', style: Theme.of(ctx).textTheme.titleLarge), IconButton(onPressed: () => setLocal(() => points = (points + 1).clamp(1, 8).toInt()), icon: const Icon(Icons.add_circle_outline))]),
        const SizedBox(height: 12),
        FilledButton(onPressed: title.text.trim().isEmpty ? null : () async {
          final item = TaskItem(id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(), title: title.text.trim(), owner: owner, frequency: frequency, points: points, category: category);
          await store.addOrUpdate(item);
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const SizedBox(width: double.infinity, child: Center(child: Text('حفظ المهمة')))),
      ])),
    )),
  );
}

String ownerLabel(TaskOwner o) => switch (o) { TaskOwner.shared => 'مشتركة', TaskOwner.me => 'مهامي', TaskOwner.friend => 'مهام صاحبي' };
String frequencyLabel(Frequency f) => switch (f) {
  Frequency.daily => 'يوميًا', Frequency.alternate => 'يوم ويوم',
  Frequency.weekly => 'أسبوعيًا', Frequency.saturday => 'كل سبت',
  Frequency.friday => 'كل جمعة', Frequency.once => 'مرة واحدة',
};
