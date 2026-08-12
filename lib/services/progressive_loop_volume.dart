import 'dart:math' as math;

class ProgressiveLoopVolume {
  const ProgressiveLoopVolume({
    this.decayPerLoop = 0.96,
    this.minimumGain = 0.22,
  });

  final double decayPerLoop;
  final double minimumGain;

  double gainForCompletedLoops(int completedLoops) {
    if (completedLoops <= 0) return 1;
    return math.max(
      minimumGain,
      math.pow(decayPerLoop, completedLoops).toDouble(),
    );
  }

  static bool didPositionWrap(Duration previous, Duration current) {
    return previous >= const Duration(seconds: 2) &&
        current <= const Duration(seconds: 2) &&
        previous - current >= const Duration(seconds: 1);
  }
}
