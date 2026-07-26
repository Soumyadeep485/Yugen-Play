import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/colors/app_colors.dart';

class ReleaseCountdownCard extends StatefulWidget {
  final int nextEpisodeNumber;
  final DateTime targetReleaseTime;

  const ReleaseCountdownCard({
    super.key,
    required this.nextEpisodeNumber,
    required this.targetReleaseTime,
  });

  @override
  State<ReleaseCountdownCard> createState() => _ReleaseCountdownCardState();
}

class _ReleaseCountdownCardState extends State<ReleaseCountdownCard> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _calculateTimeLeft(),
    );
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    if (widget.targetReleaseTime.isAfter(now)) {
      setState(() {
        _timeLeft = widget.targetReleaseTime.difference(now);
      });
    } else {
      setState(() {
        _timeLeft = Duration.zero;
      });
      _timer.cancel();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration() {
    if (_timeLeft == Duration.zero) return "RELEASED";

    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours.remainder(24);
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);

    return "$days DAYS $hours HRS $minutes MINS $seconds SECS";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "EPISODE ${widget.nextEpisodeNumber} RELEASES IN",
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _formatDuration(),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}