import 'package:flutter/material.dart';

import '../../domain/stillow_models.dart';
import '../../widgets/soft_ui.dart';

class SessionLibraryScreen extends StatelessWidget {
  const SessionLibraryScreen({
    super.key,
    required this.sessions,
    this.title = '换一种\n舒服的方式',
    this.subtitle = '不用坚持一种方法。',
  });

  final List<GuidedSession> sessions;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StillowBackdrop(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuietIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: '返回',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 28),
            Text(title, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 12),
            Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 26),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: sessions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return SoftChoiceCard(
                    title: session.title,
                    subtitle: session.subtitle,
                    icon: session.icon,
                    onTap: () => Navigator.of(context).pop(session),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
