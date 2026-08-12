import 'package:flutter/material.dart';

import '../../services/dream_interpreter.dart';
import '../../theme/stillow_theme.dart';
import '../../widgets/soft_ui.dart';

class DreamInterpretationScreen extends StatefulWidget {
  const DreamInterpretationScreen({super.key});

  @override
  State<DreamInterpretationScreen> createState() =>
      _DreamInterpretationScreenState();
}

class _DreamInterpretationScreenState extends State<DreamInterpretationScreen> {
  final _controller = TextEditingController();
  late final Future<DreamInterpreter> _interpreter =
      DreamInterpreter.loadAsset();
  List<DreamReading> _readings = const [];
  bool _hasRead = false;

  Future<void> _interpret() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    final interpreter = await _interpreter;
    if (!mounted) return;
    setState(() {
      _readings = interpreter.interpret(text);
      _hasRead = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: StillowBackdrop(
        padding: EdgeInsets.zero,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 34),
              sliver: SliverList.list(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: QuietIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: '返回',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '梦里发生了\n什么？',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '写下几个还记得的画面、人物或感受。',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    minLines: 4,
                    maxLines: 8,
                    maxLength: 600,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: '例如：我在一座陌生的房子里，窗外一直下雨……',
                      counterText: '',
                      filled: true,
                      fillColor: StillowColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: StillowColors.outline,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: StillowColors.outline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _interpret,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('看看这个梦'),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '文字只在当前页面内即时分析，退出后不保存。',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_hasRead) ...[
                    const SizedBox(height: 30),
                    Text(
                      '一种轻松的读法',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    for (final reading in _readings) ...[
                      _DreamCard(reading: reading),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: StillowColors.surface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '仅供休闲娱乐。梦没有统一答案，本解析不预测未来，也不代表心理诊断。',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DreamCard extends StatelessWidget {
  const _DreamCard({required this.reading});

  final DreamReading reading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StillowColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: StillowColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reading.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(reading.body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Text(
            reading.prompt,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: StillowColors.moon),
          ),
        ],
      ),
    );
  }
}
