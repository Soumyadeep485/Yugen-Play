import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/colors/app_colors.dart';

class ReleaseCountdownCard extends StatefulWidget {
  final int episodeNumber;
  final DateTime targetDate;

  const ReleaseCountdownCard({
    super.key,
    required this.episodeNumber,
    required this.targetDate,
  });

  @override
  State<ReleaseCountdownCard> createState() => _ReleaseCountdownCardState();
}

class _ReleaseCountdownCardState extends State<ReleaseCountdownCard> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    // Update the UI exactly once every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateTimeLeft();
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    setState(() {
      _timeLeft = widget.targetDate.difference(now);
      if (_timeLeft.isNegative) {
        _timeLeft = Duration.zero;
        _timer.cancel(); // Stop ticking if it's already out
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft.isNegative || _timeLeft == Duration.zero) {
      return const SizedBox.shrink(); // Hide if somehow the date passed
    }

    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.2),
                AppColors.primary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Text(
                "EPISODE ${widget.episodeNumber} RELEASES IN",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${days}D ${hours}H ${minutes}M ${seconds}S",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}