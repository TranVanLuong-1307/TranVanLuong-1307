import 'package:flutter/material.dart';
import '../models/test_scenario.dart';
import '../services/android_notification_poster.dart';

class SimulatorScreen extends StatefulWidget {
  final IAndroidNotificationPoster? poster;

  const SimulatorScreen({super.key, this.poster});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  late final IAndroidNotificationPoster _poster;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  SimulatorCategoryType _selectedCategory = SimulatorCategoryType.messaging;
  TestScenario? _selectedScenario;
  bool _isSending = false;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _poster = widget.poster ?? AndroidNotificationPoster();
    // Default to the first scenario
    _selectScenario(TestScenario.predefinedScenarios.first);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _selectScenario(TestScenario scenario) {
    setState(() {
      _selectedScenario = scenario;
      _selectedCategory = scenario.categoryType;
      _titleController.text = scenario.defaultTitle;
      _contentController.text = scenario.defaultContent;
    });
  }

  Future<void> _sendNotification() async {
    final title = _titleController.text;
    final content = _contentController.text;

    setState(() => _isSending = true);
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    try {
      final success = await _poster.postNotification(
        title: title.isEmpty ? null : title,
        content: content.isEmpty ? null : content,
      );

      setState(() {
        if (success) {
          _logs.insert(0, '[$timeStr] ĐÃ PHÁT NOTIFICATION THẬT: "${title.isNotEmpty ? title : '(No title)'}"');
        } else {
          _logs.insert(0, '[$timeStr] Lỗi khi phát notification');
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã phát Android Notification thật qua hệ điều hành!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _logs.insert(0, '[$timeStr] EXCEPTION: $e');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _sendRapidBatch() async {
    setState(() => _isSending = true);
    for (int i = 1; i <= 5; i++) {
      await _poster.postNotification(
        title: 'Rapid Msg #$i: ${_titleController.text}',
        content: 'Nội dung gói $i: ${_contentController.text}',
      );
      await Future.delayed(const Duration(milliseconds: 150));
    }
    setState(() {
      _isSending = false;
      _logs.insert(0, '[${DateTime.now().toString().split('.').first}] Đã phát 5 notifications siêu tốc (Rapid burst)');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Simulator'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Architecture reminder banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border.all(color: Colors.amber.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade900),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SIMULATOR KIỂM THỬ ĐỘC LẬP\n'
                    'Công cụ này phát Notification thật thông qua Android OS NotificationManager. '
                    'Notification Insight sẽ nhận diện qua NotificationListenerService và chạy qua toàn bộ pipeline.',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Scenario selector
          const Text(
            'CHỌN TEST SCENARIO (10 KỊCH BẢN)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TestScenario>(
                  isExpanded: true,
                  value: _selectedScenario,
                  items: TestScenario.predefinedScenarios.map((sc) {
                    return DropdownMenuItem<TestScenario>(
                      value: sc,
                      child: Text(sc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                  onChanged: (sc) {
                    if (sc != null) _selectScenario(sc);
                  },
                ),
              ),
            ),
          ),
          if (_selectedScenario != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
              child: Text(
                _selectedScenario!.description,
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
              ),
            ),
          const SizedBox(height: 16),

          // Category Selector
          const Text(
            'DANH MỤC THỬ NGHIỆM',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<SimulatorCategoryType>(
                  isExpanded: true,
                  value: _selectedCategory,
                  items: SimulatorCategoryType.values.map((cat) {
                    return DropdownMenuItem<SimulatorCategoryType>(
                      value: cat,
                      child: Text(cat.displayName),
                    );
                  }).toList(),
                  onChanged: (cat) {
                    if (cat != null) setState(() => _selectedCategory = cat);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title Input
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Tiêu đề thông báo (Title)',
              border: OutlineInputBorder(),
              hintText: 'Nhập tiêu đề hoặc để trống...',
            ),
          ),
          const SizedBox(height: 12),

          // Content Input
          TextField(
            controller: _contentController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Nội dung thông báo (Content)',
              border: OutlineInputBorder(),
              hintText: 'Nhập nội dung hoặc để trống...',
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade700,
                foregroundColor: Colors.white,
              ),
              icon: _isSending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: const Text('GỬI NOTIFICATION THẬT QUA ANDROID OS', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _isSending ? null : _sendNotification,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.repeat_rounded),
                  label: const Text('Phát lặp lại (x2)'),
                  onPressed: _isSending
                      ? null
                      : () async {
                          await _sendNotification();
                          await Future.delayed(const Duration(milliseconds: 300));
                          await _sendNotification();
                        },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.bolt_rounded),
                  label: const Text('Phát siêu tốc (x5)'),
                  onPressed: _isSending ? null : _sendRapidBatch,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Dispatch Logs
          const Text(
            'NHẬT KÝ PHÁT NOTIFICATION (DISPATCH LOG)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Container(
            height: 140,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có thông báo nào được phát.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          _logs[index],
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
