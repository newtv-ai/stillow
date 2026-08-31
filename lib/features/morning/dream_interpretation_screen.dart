import 'package:flutter/material.dart';

import '../../services/dream_interpreter.dart';
import '../../l10n/l10n.dart';
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
  Future<DreamInterpreter>? _interpreter;
  String? _interpreterLanguage;
  List<DreamReading> _readings = const [];
  bool _hasRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode == 'zh'
        ? 'zh'
        : 'en';
    if (_interpreterLanguage == language) return;
    _interpreterLanguage = language;
    _interpreter = DreamInterpreter.loadAsset(
      path: language == 'zh'
          ? 'assets/content/dream_symbols.json'
          : 'assets/content/dream_symbols_en.json',
    );
  }

  Future<void> _interpret() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    final interpreter = await _interpreter!;
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
    final l10n = context.l10n;
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
                      tooltip: l10n.back,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.dreamTitle,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.dreamSubtitle,
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
                      hintText: l10n.dreamHint,
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
                    label: Text(l10n.dreamAction),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.dreamPrivacy,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_hasRead) ...[
                    const SizedBox(height: 30),
                    Text(
                      l10n.dreamReadingTitle,
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
                        l10n.dreamDisclaimer,
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
