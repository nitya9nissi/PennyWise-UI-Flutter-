
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';

void main() => runApp(const PennyWise());

class PennyWise extends StatelessWidget {
  const PennyWise({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PennyWise',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF345B9A),
          primary: const Color(0xFF345B9A),
        ),
        fontFamily: 'Arial',
      ),
      home: const PennyHome(),
    );
  }
}

class Expense {
  String title, category, date, note;
  double amount;

  Expense(this.title, this.category, this.date, this.note, this.amount);

  Map<String, dynamic> toJson() => {
    'title': title, 'category': category,
    'date': date, 'note': note, 'amount': amount
  };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
    j['title'], j['category'], j['date'], j['note'],
    (j['amount'] as num).toDouble(),
  );
}

class PennyHome extends StatefulWidget {
  const PennyHome({super.key});

  @override
  State<PennyHome> createState() => _PennyHomeState();
}

class _PennyHomeState extends State<PennyHome> {
  final Color navy = const Color(0xFF243B64);
  final Color blue = const Color(0xFF527DBB);
  final Color pale = const Color(0xFFE8EFFB);

  bool started = false;
  int page = 0;
  double savingsGoal = 10000;
  final List<Expense> expenses = [];

  final titleCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final goalCtrl = TextEditingController();

  String category = 'Food';
  String expenseDate = DateTime.now().toString().substring(0, 10);

  final categories = ['Food', 'Travel', 'Shopping', 'Bills', 'Health', 'Education', 'Other'];

  @override
  void initState() {
    super.initState();
    try {
      final saved = html.window.localStorage['pennywise_expenses'];
      if (saved != null) {
        expenses.addAll((jsonDecode(saved) as List)
            .map((e) => Expense.fromJson(e)));
      }
      final goal = html.window.localStorage['pennywise_goal'];
      if (goal != null) savingsGoal = double.parse(goal);
    } catch (_) {}
  }

  void saveData() {
    html.window.localStorage['pennywise_expenses'] =
        jsonEncode(expenses.map((e) => e.toJson()).toList());
    html.window.localStorage['pennywise_goal'] = savingsGoal.toString();
  }

  double get total => expenses.fold(0, (s, e) => s + e.amount);
  String money(double n) => '₹${n.toStringAsFixed(2)}';

  void addExpense() {
    titleCtrl.clear();
    amountCtrl.clear();
    noteCtrl.clear();
    category = 'Food';
    expenseDate = DateTime.now().toString().substring(0, 10);
    setState(() => page = 1);
  }

  void saveExpense() {
    final amount = double.tryParse(amountCtrl.text);
    if (titleCtrl.text.trim().isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title and a valid amount.')),
      );
      return;
    }
    setState(() {
      expenses.insert(0, Expense(
        titleCtrl.text.trim(), category, expenseDate,
        noteCtrl.text.trim(), amount,
      ));
      page = 5;
    });
    saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense saved successfully!')),
    );
  }

  void editExpense(int index) {
    final e = expenses[index];
    titleCtrl.text = e.title;
    amountCtrl.text = e.amount.toString();
    noteCtrl.text = e.note;
    category = e.category;
    expenseDate = e.date;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount')),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Description')),
            DropdownButtonFormField<String>(
              value: category,
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => category = v!,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            final a = double.tryParse(amountCtrl.text);
            if (a == null || a <= 0 || titleCtrl.text.trim().isEmpty) return;
            setState(() {
              expenses[index] = Expense(titleCtrl.text.trim(), category, e.date, noteCtrl.text.trim(), a);
            });
            saveData();
            Navigator.pop(context);
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!started) return welcomePage();

    final pages = [
      dashboardPage(),
      addPage(),
      spendingPage(),
      chartPage(),
      savingsPage(),
      transactionsPage(),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: Colors.white,
            selectedIndex: page,
            onDestinationSelected: (i) => setState(() => page = i),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Icon(Icons.account_balance_wallet, color: blue, size: 34),
            ),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Home')),
              NavigationRailDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: Text('Add Expense')),
              NavigationRailDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: Text('My Spending')),
              NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: Text('Bar Graph')),
              NavigationRailDestination(icon: Icon(Icons.savings_outlined), selectedIcon: Icon(Icons.savings), label: Text('Savings')),
              NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Transactions')),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 72,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    children: [
                      Text('PennyWise', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: navy)),
                      const Spacer(),
                      const CircleAvatar(backgroundColor: Color(0xFFE8EFFB), child: Icon(Icons.person, color: Color(0xFF345B9A))),
                      const SizedBox(width: 10),
                      const Text('My Wallet', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(child: SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: pages[page],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget welcomePage() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF20385F), Color(0xFF527DBB), Color(0xFF9DB7DE)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(55),
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_rounded, size: 75, color: Colors.white),
                const SizedBox(height: 24),
                const Text('PennyWise', style: TextStyle(color: Colors.white, fontSize: 54, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                const Text('Spend wisely. Save smartly. Live freely.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 19)),
                const SizedBox(height: 35),
                const Text('Take control of your money, one smart decision at a time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 15)),
                const SizedBox(height: 40),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: Color(0xFF243B64),
                    padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 19),
                  ),
                  onPressed: () => setState(() => started = true),
                  child: const Text('Get Started  →', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 25),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 29, fontWeight: FontWeight.bold, color: navy)),
      const SizedBox(height: 7),
      Text(subtitle, style: const TextStyle(color: Colors.blueGrey, fontSize: 15)),
    ]),
  );

  Widget card(Widget child, {double? width}) => Container(
    width: width,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17),
      boxShadow: [BoxShadow(color: Colors.blueGrey.withOpacity(.07), blurRadius: 18, offset: const Offset(0, 5))]),
    child: child,
  );

  Widget stat(String label, String value, IconData icon, Color color) => Expanded(
    child: card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 27),
      const SizedBox(height: 16),
      Text(label, style: const TextStyle(color: Colors.blueGrey)),
      const SizedBox(height: 7),
      Text(value, style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: navy)),
    ])),
  );

  Widget dashboardPage() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    heading('Welcome back!', 'Here is your financial snapshot.'),
    Row(children: [
      stat('Total Expenses', money(total), Icons.account_balance_wallet, blue),
      const SizedBox(width: 17),
      stat('Transactions', '${expenses.length}', Icons.receipt_long, Colors.deepPurple),
      const SizedBox(width: 17),
      stat('Savings Goal', money(savingsGoal), Icons.savings, Colors.teal),
    ]),
    const SizedBox(height: 25),
    card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navy)),
      const SizedBox(height: 20),
      Wrap(spacing: 14, runSpacing: 14, children: [
        actionButton('Add Expense', Icons.add, 1),
        actionButton('My Spending', Icons.pie_chart, 2),
        actionButton('View Bar Graph', Icons.bar_chart, 3),
        actionButton('Savings Goals', Icons.savings, 4),
        actionButton('Transactions', Icons.receipt, 5),
      ]),
    ])),
    const SizedBox(height: 25),
    card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Recent Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navy)),
      const SizedBox(height: 12),
      if (expenses.isEmpty) const Text('No expenses yet. Add your first expense to get started.'),
      ...expenses.take(4).map((e) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(backgroundColor: pale, child: Icon(Icons.shopping_bag_outlined, color: blue)),
        title: Text(e.title),
        subtitle: Text('${e.category} • ${e.date}'),
        trailing: Text(money(e.amount), style: TextStyle(fontWeight: FontWeight.bold, color: navy)),
      )),
    ])),
  ]);

  Widget actionButton(String label, IconData icon, int destination) => OutlinedButton.icon(
    onPressed: () => setState(() => page = destination),
    icon: Icon(icon), label: Text(label),
    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17)),
  );

  Widget addPage() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    heading('Add Expense', 'Record where your money goes.'),
    card(ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: Column(children: [
        TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Expense title', hintText: 'e.g. Grocery shopping', prefixIcon: Icon(Icons.edit))),
        const SizedBox(height: 15),
        TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (₹)', hintText: 'Enter amount', prefixIcon: Icon(Icons.currency_rupee))),
        const SizedBox(height: 15),
        DropdownButtonFormField<String>(
          value: category,
          decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)),
          items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => category = v!),
        ),
        const SizedBox(height: 15),
        TextFormField(
          initialValue: expenseDate,
          decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', prefixIcon: Icon(Icons.calendar_today)),
          onChanged: (v) => expenseDate = v,
        ),
        const SizedBox(height: 15),
        TextField(controller: noteCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description (optional)', alignLabelWithHint: true, prefixIcon: Icon(Icons.notes))),
        const SizedBox(height: 25),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: saveExpense, icon: const Icon(Icons.save),
          label: const Text('Save Expense'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.all(17)),
        )),
      ]),
    )),
  ]);

  Widget spendingPage() {
    final Map<String, double> totals = {};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    final colors = [blue, Colors.deepPurple, Colors.teal, Colors.orange, Colors.pink, Colors.indigo, Colors.brown];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      heading('My Spending', 'Understand how your expenses are distributed.'),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Total spent', style: const TextStyle(color: Colors.blueGrey)),
        const SizedBox(height: 8),
        Text(money(total), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: navy)),
        const Divider(height: 30),
        if (totals.isEmpty) const Text('Your category breakdown will appear here after you add expenses.'),
        ...totals.entries.toList().asMap().entries.map((entry) {
          final c = colors[entry.key % colors.length];
          final item = entry.value;
          final percent = total == 0 ? 0.0 : item.value / total;
          return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Column(children: [
            Row(children: [CircleAvatar(radius: 6, backgroundColor: c), const SizedBox(width: 10),
              Expanded(child: Text(item.key)), Text('${(percent * 100).toStringAsFixed(1)}%  ', style: const TextStyle(color: Colors.blueGrey)),
              Text(money(item.value), style: TextStyle(fontWeight: FontWeight.bold, color: navy))]),
            const SizedBox(height: 9),
            LinearProgressIndicator(value: percent, minHeight: 9, backgroundColor: pale, color: c, borderRadius: BorderRadius.circular(10)),
          ]));
        }),
      ])),
    ]);
  }

  Widget chartPage() {
    final Map<String, double> totals = {};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    final entries = totals.entries.toList();
    final maxValue = entries.isEmpty ? 1.0 : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      heading('Bar Graph', 'Visualise your spending by category.'),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Category-wise expenses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navy)),
        const SizedBox(height: 25),
        if (entries.isEmpty) const Text('Add expenses to generate your bar graph.'),
        ...entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(e.key)), Text(money(e.value), style: const TextStyle(fontWeight: FontWeight.bold))]),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) => Container(
            height: 22, width: constraints.maxWidth * (e.value / maxValue),
            decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(7)),
          )),
        ]))),
      ])),
    ]);
  }

  Widget savingsPage() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    heading('Savings Goals', 'Keep track of the amount you want to save.'),
    card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Your savings target', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navy)),
      const SizedBox(height: 15),
      Text('Goal amount: ${money(savingsGoal)}'),
      const SizedBox(height: 8),
      Text('Expenses recorded: ${money(total)}'),
      const SizedBox(height: 8),
      Text('Goal remaining: ${money((savingsGoal - total).clamp(0, double.infinity))}'),
      const SizedBox(height: 20),
      LinearProgressIndicator(
        value: savingsGoal <= 0 ? 0 : (total / savingsGoal).clamp(0, 1),
        minHeight: 13, color: Colors.teal, backgroundColor: pale,
        borderRadius: BorderRadius.circular(10),
      ),
      const SizedBox(height: 20),
      TextField(controller: goalCtrl, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Set a new savings target (₹)', prefixIcon: Icon(Icons.flag))),
      const SizedBox(height: 15),
      FilledButton(onPressed: () {
        final g = double.tryParse(goalCtrl.text);
        if (g != null && g > 0) {
          setState(() => savingsGoal = g);
          saveData();
          goalCtrl.clear();
        }
      }, child: const Text('Update Goal')),
      const SizedBox(height: 12),
      const Text('Note: This progress compares your recorded expenses with your target. It is a simple tracker, not a bank balance.'),
    ])),
  ]);

  Widget transactionsPage() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    heading('Transactions', 'Review and manage all your recorded expenses.'),
    card(Column(children: [
      Row(children: [
        Expanded(child: Text('All Transactions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navy))),
        Text('${expenses.length} records', style: const TextStyle(color: Colors.blueGrey)),
      ]),
      const Divider(height: 25),
      if (expenses.isEmpty) const Padding(padding: EdgeInsets.all(25), child: Text('No transactions yet. Add an expense to see it here.')),
      ...expenses.asMap().entries.map((entry) {
        final i = entry.key;
        final e = entry.value;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundColor: pale, child: Icon(Icons.receipt_long, color: blue)),
          title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${e.category} • ${e.date}${e.note.isEmpty ? '' : '\n${e.note}'}'),
          isThreeLine: e.note.isNotEmpty,
          trailing: SizedBox(width: 125, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Flexible(child: Text(money(e.amount), style: TextStyle(fontWeight: FontWeight.bold, color: navy))),
            IconButton(tooltip: 'Edit', onPressed: () => editExpense(i), icon: const Icon(Icons.edit_outlined, size: 19)),
            IconButton(tooltip: 'Delete', onPressed: () {
              setState(() => expenses.removeAt(i));
              saveData();
            }, icon: const Icon(Icons.delete_outline, color: Colors.red, size: 19)),
          ])),
        );
      }),
    ])),
  ]);
}