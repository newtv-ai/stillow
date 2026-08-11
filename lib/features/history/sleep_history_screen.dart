import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/sleep_history_store.dart';
import '../../domain/sleep_history.dart';
import '../../domain/stillow_models.dart';
import '../../services/sleep_health_gateway.dart';
import '../../theme/stillow_theme.dart';
import '../../widgets/soft_ui.dart';

class SleepHistoryScreen extends StatefulWidget {
  const SleepHistoryScreen({
    super.key,
    required this.historyStore,
    required this.healthGateway,
  });

  final SleepHistoryStore historyStore;
  final SleepHealthGateway healthGateway;

  @override
  State<SleepHistoryScreen> createState() => _SleepHistoryScreenState();
}

class _SleepHistoryScreenState extends State<SleepHistoryScreen> {
  SleepHistorySnapshot _snapshot = const SleepHistorySnapshot();
  SleepHealthAvailability? _availability;
  bool _loading = true;
  bool _syncing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait<Object>([
      widget.historyStore.load(),
      widget.healthGateway.checkAvailability(),
    ]);
    if (!mounted) return;
    setState(() {
      _snapshot = results[0] as SleepHistorySnapshot;
      _availability = results[1] as SleepHealthAvailability;
      _loading = false;
    });
  }

  Future<void> _syncHealth() async {
    if (_syncing) return;
    final confirmed = await _confirmHealthRead();
    if (!confirmed || !mounted) return;
    setState(() {
      _syncing = true;
      _message = null;
    });
    final result = await widget.healthGateway.requestAndRead();
    if (result.state == SleepHealthSyncState.synced ||
        result.state == SleepHealthSyncState.noData) {
      await widget.historyStore.replaceHealthSamples(
        result.samples,
        DateTime.now(),
      );
    }
    final snapshot = await widget.historyStore.load();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _syncing = false;
      _message = result.message;
    });
  }

  Future<bool> _confirmHealthRead() async =>
      await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: StillowColors.surface,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '只读最近的睡眠记录',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  '接下来系统会询问是否允许读取睡眠时段和睡眠阶段。'
                  'Stillow 不读取心率或 HRV，不写入健康数据，也不在后台同步。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('先不连接'),
                    ),
                    const Spacer(),
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('继续'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;

  Future<void> _installHealthConnect() async {
    await widget.healthGateway.openInstallOrUpdate();
    if (!mounted) return;
    setState(() => _message = '安装或更新完成后，回到这里再连接就好。');
  }

  Future<void> _disconnectHealth() async {
    final confirmed = await _confirm(
      title: '断开健康数据？',
      body: widget.healthGateway.hostPlatform == HealthHostPlatform.ios
          ? '会清除 Stillow 保存的健康记录。Apple 健康的读取权限仍需在系统“健康”中管理。'
          : '会撤销 Stillow 的 Health Connect 权限，并清除 App 中保存的健康记录。',
      action: '断开并清除',
    );
    if (!confirmed) return;
    try {
      await widget.healthGateway.disconnect();
    } finally {
      await widget.historyStore.clearHealthData();
    }
    final snapshot = await widget.historyStore.load();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _message = widget.healthGateway.hostPlatform == HealthHostPlatform.ios
          ? 'App 内的健康记录已清除；系统授权可在 Apple 健康中管理。'
          : 'Health Connect 已断开，本机缓存也已清除。';
    });
  }

  Future<void> _deleteLocalDay(String dayKey) async {
    final confirmed = await _confirm(
      title: '移除这晚的本地记录？',
      body: '只会移除 Stillow 的声音陪伴记录和晨间感受，不会影响系统健康数据。',
      action: '移除',
    );
    if (!confirmed) return;
    await widget.historyStore.deleteLocalDay(dayKey);
    final snapshot = await widget.historyStore.load();
    if (mounted) setState(() => _snapshot = snapshot);
  }

  Future<void> _clearAll() async {
    final confirmed = await _confirm(
      title: '清除 Stillow 中的全部记录？',
      body: '声音陪伴、晨间感受和已同步的健康记录都会从这台设备中移除。收藏和个性化偏好不会受影响。',
      action: '全部清除',
    );
    if (!confirmed) return;
    await widget.historyStore.clearAll();
    if (!mounted) return;
    setState(() {
      _snapshot = const SleepHistorySnapshot();
      _message = '这台设备中的睡眠记录已经清除。';
    });
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
  }) async =>
      await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: StillowColors.surface,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 18),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('先留着'),
                    ),
                    const Spacer(),
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(action),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final summaries = summarizeSleepNights(_snapshot.healthSamples);
    final localNights = _groupLocalNights(_snapshot);
    return Scaffold(
      body: StillowBackdrop(
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
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
            Text('最近的夜晚', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 12),
            Text(
              '只帮助你回顾，不给睡眠打分。记录最多保留 30 天。',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 26),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              _HealthConnectionCard(
                availability: _availability!,
                lastSyncAt: _snapshot.lastHealthSyncAt,
                hasCachedData: _snapshot.healthSamples.isNotEmpty,
                syncing: _syncing,
                message: _message,
                onSync: _syncHealth,
                onInstall: _installHealthConnect,
                onDisconnect: _disconnectHealth,
              ),
              if (summaries.isNotEmpty) ...[
                const SizedBox(height: 18),
                _SleepTrendCard(summaries: summaries),
                const SizedBox(height: 18),
                _HealthNightList(summaries: summaries.take(7).toList()),
              ],
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Stillow 本地记录',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (!_snapshot.isEmpty)
                    TextButton(onPressed: _clearAll, child: const Text('清除全部')),
                ],
              ),
              const SizedBox(height: 10),
              if (localNights.isEmpty)
                const _SoftEmpty(text: '还没有本地记录。播放一段声音，或在醒来后选一下感受，这里才会慢慢出现内容。')
              else
                for (final night in localNights.take(14)) ...[
                  _LocalNightCard(
                    night: night,
                    onDelete: () => _deleteLocalDay(night.dayKey),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ],
        ),
      ),
    );
  }
}

class _HealthConnectionCard extends StatelessWidget {
  const _HealthConnectionCard({
    required this.availability,
    required this.lastSyncAt,
    required this.hasCachedData,
    required this.syncing,
    required this.message,
    required this.onSync,
    required this.onInstall,
    required this.onDisconnect,
  });

  final SleepHealthAvailability availability;
  final DateTime? lastSyncAt;
  final bool hasCachedData;
  final bool syncing;
  final String? message;
  final VoidCallback onSync;
  final VoidCallback onInstall;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final status = switch (availability) {
      SleepHealthAvailability.available when lastSyncAt != null =>
        '上次更新：${_formatDateTime(lastSyncAt!)}',
      SleepHealthAvailability.available => '由你决定是否连接，不会在首次启动时询问。',
      SleepHealthAvailability.installRequired => '需要先安装或更新 Health Connect。',
      SleepHealthAvailability.unavailable => '这台设备暂时不支持系统睡眠数据。',
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StillowColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: StillowColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.watch_outlined, color: StillowColors.sage),
          const SizedBox(height: 10),
          Text('手表与系统睡眠记录', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(status, style: Theme.of(context).textTheme.bodyMedium),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 14),
          if (availability == SleepHealthAvailability.available)
            FilledButton.tonalIcon(
              onPressed: syncing ? null : onSync,
              icon: syncing
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded),
              label: Text(lastSyncAt == null ? '连接并同步' : '更新最近记录'),
            )
          else if (availability == SleepHealthAvailability.installRequired)
            FilledButton.tonal(
              onPressed: onInstall,
              child: const Text('安装或更新 Health Connect'),
            ),
          if (lastSyncAt != null || hasCachedData)
            TextButton(
              onPressed: syncing ? null : onDisconnect,
              child: const Text('断开并清除健康缓存'),
            ),
        ],
      ),
    );
  }
}

class _SleepTrendCard extends StatelessWidget {
  const _SleepTrendCard({required this.summaries});

  final List<NightSleepSummary> summaries;

  @override
  Widget build(BuildContext context) {
    final values = summaries.take(7).toList().reversed.toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StillowColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: StillowColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('睡眠记录时段走势', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 5),
          Text(
            '连接线表示设备记录的起止跨度，不是睡眠质量分数。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 118,
            width: double.infinity,
            child: CustomPaint(painter: _SleepTrendPainter(values)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final value in values)
                Expanded(
                  child: Text(
                    '${value.day.month}/${value.day.day}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SleepTrendPainter extends CustomPainter {
  const _SleepTrendPainter(this.values);

  final List<NightSleepSummary> values;

  @override
  void paint(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = StillowColors.outline
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = size.height * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guide);
    }
    if (values.isEmpty) return;
    final hours = values
        .map((item) => item.recordedWindow.inMinutes / 60)
        .toList();
    final maxHours = math.max(10.0, hours.reduce(math.max));
    final points = <Offset>[];
    for (var i = 0; i < hours.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * i / (values.length - 1);
      final normalized = (hours[i] / maxHours).clamp(0.0, 1.0);
      points.add(Offset(x, size.height * (1 - normalized)));
    }
    final line = Paint()
      ..color = StillowColors.moon
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, line);
    }
    final dot = Paint()..color = StillowColors.moon;
    for (final point in points) {
      canvas.drawCircle(point, 4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _SleepTrendPainter oldDelegate) =>
      oldDelegate.values != values;
}

class _HealthNightList extends StatelessWidget {
  const _HealthNightList({required this.summaries});

  final List<NightSleepSummary> summaries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('设备记录', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        for (final summary in summaries) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: StillowColors.surface.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: StillowColors.outline),
            ),
            child: Row(
              children: [
                const Icon(Icons.bedtime_outlined, color: StillowColors.sage),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDay(summary.day),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_formatClock(summary.startedAt)}–${_formatClock(summary.endedAt)} · '
                        '${_formatDuration(summary.recordedWindow)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (summary.stages.any(_isSpecificSleepStage))
                        Text(
                          '设备同时提供了睡眠阶段',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (summary.segments.any(_isVisibleSleepSegment)) ...[
                        const SizedBox(height: 9),
                        _SleepStageTimeline(summary: summary),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SleepStageTimeline extends StatelessWidget {
  const _SleepStageTimeline({required this.summary});

  final NightSleepSummary summary;

  @override
  Widget build(BuildContext context) {
    final totalMilliseconds = summary.recordedWindow.inMilliseconds;
    final segments = summary.segments.where(_isVisibleSleepSegment).toList();
    if (totalMilliseconds <= 0 || segments.isEmpty) {
      return const SizedBox.shrink();
    }
    return Semantics(
      label: '设备提供的睡眠阶段时间条，仅供回顾，不是睡眠评分',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 10,
            child: LayoutBuilder(
              builder: (context, constraints) => ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: StillowColors.backgroundSoft),
                    for (final segment in segments)
                      Positioned(
                        left:
                            constraints.maxWidth *
                            segment.startedAt
                                .difference(summary.startedAt)
                                .inMilliseconds
                                .clamp(0, totalMilliseconds) /
                            totalMilliseconds,
                        width:
                            constraints.maxWidth *
                            segment.duration.inMilliseconds.clamp(
                              1,
                              totalMilliseconds,
                            ) /
                            totalMilliseconds,
                        top: 0,
                        bottom: 0,
                        child: ColoredBox(color: _stageColor(segment.stage)),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '浅睡 · 深睡 · REM · 清醒（按设备记录展示）',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _LocalNightCard extends StatelessWidget {
  const _LocalNightCard({required this.night, required this.onDelete});

  final _LocalNight night;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
      decoration: BoxDecoration(
        color: StillowColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: StillowColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDay(night.day),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (night.checkIn != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    '醒来时：${_feelingLabel(night.checkIn!.feeling)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                for (final session in night.sessions) ...[
                  const SizedBox(height: 9),
                  Text(
                    session.sessionTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${session.context == SleepUseContext.nightAwake ? '夜醒陪伴' : '睡前陪伴'} · '
                    '${_formatDuration(Duration(seconds: session.listenedSeconds))}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: '移除这晚的本地记录',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            color: StillowColors.linenMuted,
          ),
        ],
      ),
    );
  }
}

class _SoftEmpty extends StatelessWidget {
  const _SoftEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: StillowColors.surface.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
  );
}

class _LocalNight {
  const _LocalNight({
    required this.dayKey,
    required this.day,
    required this.sessions,
    required this.checkIn,
  });

  final String dayKey;
  final DateTime day;
  final List<AppSleepSessionRecord> sessions;
  final MorningCheckIn? checkIn;
}

List<_LocalNight> _groupLocalNights(SleepHistorySnapshot snapshot) {
  final sessionsByDay = <String, List<AppSleepSessionRecord>>{};
  final checkInsByDay = <String, MorningCheckIn>{};
  for (final session in snapshot.appSessions) {
    sessionsByDay
        .putIfAbsent(sleepSessionNightKey(session.startedAt), () => [])
        .add(session);
  }
  for (final checkIn in snapshot.morningCheckIns) {
    checkInsByDay[sleepHistoryDayKey(checkIn.recordedAt)] = checkIn;
  }
  final keys = {...sessionsByDay.keys, ...checkInsByDay.keys}.toList()
    ..sort((a, b) => b.compareTo(a));
  return keys.map((key) {
    final parts = key.split('-').map(int.parse).toList();
    final sessions = List<AppSleepSessionRecord>.from(
      sessionsByDay[key] ?? const [],
    );
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return _LocalNight(
      dayKey: key,
      day: DateTime(parts[0], parts[1], parts[2]),
      sessions: List.unmodifiable(sessions),
      checkIn: checkInsByDay[key],
    );
  }).toList();
}

bool _isSpecificSleepStage(HealthSleepStage stage) => const {
  HealthSleepStage.deep,
  HealthSleepStage.light,
  HealthSleepStage.rem,
}.contains(stage);

bool _isVisibleSleepSegment(HealthSleepSample sample) => const {
  HealthSleepStage.deep,
  HealthSleepStage.light,
  HealthSleepStage.rem,
  HealthSleepStage.awake,
  HealthSleepStage.awakeInBed,
}.contains(sample.stage);

Color _stageColor(HealthSleepStage stage) => switch (stage) {
  HealthSleepStage.deep => const Color(0xFF48657A),
  HealthSleepStage.light => StillowColors.sage,
  HealthSleepStage.rem => StillowColors.moon,
  HealthSleepStage.awake ||
  HealthSleepStage.awakeInBed => StillowColors.linenMuted,
  _ => StillowColors.backgroundSoft,
};

String _feelingLabel(MorningFeeling feeling) => switch (feeling) {
  MorningFeeling.rested => '挺有精神',
  MorningFeeling.ordinary => '还算普通',
  MorningFeeling.tired => '还是有点累',
};

String _formatDay(DateTime value) => '${value.month} 月 ${value.day} 日';

String _formatDateTime(DateTime value) =>
    '${_formatDay(value.toLocal())} ${_formatClock(value)}';

String _formatClock(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _formatDuration(Duration value) {
  final minutes = math.max(1, value.inMinutes);
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '$rest 分钟';
  if (rest == 0) return '$hours 小时';
  return '$hours 小时 $rest 分钟';
}
