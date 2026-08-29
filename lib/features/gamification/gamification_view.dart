
import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/theme/atari_theme.dart';
import '../../engine/gamification/gamification_engine.dart';
import '../../engine/orchestration/agent_orchestrator.dart';

/// RPG-style gamification view showing XP, level, streaks, quests, and
/// reward history.
///
/// See Plans/IMPLEMENTATION.md §4.7.
class GamificationView extends StatefulWidget {
  const GamificationView({super.key, required this.orchestrator});

  final AgentOrchestrator orchestrator;

  @override
  State<GamificationView> createState() => _GamificationViewState();
}

class _GamificationViewState extends State<GamificationView> {
  GamificationEngine get _engine => widget.orchestrator.gamification;

  @override
  void initState() {
    super.initState();
    widget.orchestrator.gamificationStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileCard(),
          const SizedBox(height: 24),
          Text('ACTIVE QUESTS',
              style: AtariTheme.subtitle.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildQuestList(),
          const SizedBox(height: 24),
          Text('RECENT REWARDS',
              style: AtariTheme.subtitle.copyWith(letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildRewardHistory(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AtariTheme.accentCardDecoration(AtariTheme.cyberViolet),
      child: Column(
        children: [
          Row(
            children: [
              // Level badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AtariTheme.cyberViolet, AtariTheme.electricCyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${_engine.level}',
                    style: AtariTheme.statNumber.copyWith(
                        fontSize: 28, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Level ${_engine.level}', style: AtariTheme.title),
                    const SizedBox(height: 4),
                    Text('${_engine.totalXp} XP total',
                        style: AtariTheme.bodySmall),
                  ],
                ),
              ),
              // Streak flame
              Column(
                children: [
                  Icon(Icons.local_fire_department,
                      color: AtariTheme.amberAlert, size: 28),
                  Text('${_engine.streak}',
                      style: AtariTheme.statNumber.copyWith(fontSize: 18)),
                  Text('streak', style: AtariTheme.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // XP progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _engine.levelProgress,
              minHeight: 8,
              backgroundColor: AtariTheme.surfaceHigh,
              valueColor: AlwaysStoppedAnimation(AtariTheme.cyberViolet),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${xpForLevel(_engine.level)} XP', style: AtariTheme.caption),
              Text('${xpForLevel(_engine.level + 1)} XP', style: AtariTheme.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestList() {
    final quests = _engine.quests;
    if (quests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: AtariTheme.cardDecoration,
        child: Column(
          children: [
            Icon(Icons.explore_outlined, color: AtariTheme.textMuted, size: 32),
            const SizedBox(height: 8),
            Text('No active quests', style: AtariTheme.bodySmall),
            Text('Complete actions to unlock quests', style: AtariTheme.caption),
          ],
        ),
      );
    }

    return Column(
      children: quests.map((quest) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: AtariTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    quest.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: quest.isCompleted ? AtariTheme.neonEmerald : AtariTheme.cyberViolet,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(quest.title, style: AtariTheme.body)),
                  Text('+${quest.xpReward} XP',
                      style: AtariTheme.caption.copyWith(color: AtariTheme.neonEmerald)),
                ],
              ),
              const SizedBox(height: 8),
              Text(quest.description, style: AtariTheme.bodySmall),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: quest.progress,
                  minHeight: 4,
                  backgroundColor: AtariTheme.surfaceHigh,
                  valueColor: AlwaysStoppedAnimation(
                    quest.isCompleted ? AtariTheme.neonEmerald : AtariTheme.cyberViolet,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('${quest.currentCount}/${quest.targetCount}', style: AtariTheme.caption),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRewardHistory() {
    final events = _engine.events;
    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: AtariTheme.cardDecoration,
        child: Text('No rewards yet — complete a focus session to earn XP!',
            style: AtariTheme.bodySmall),
      );
    }

    final recent = events.reversed.take(10).toList();
    return Column(
      children: recent.map((event) {
        final (label, icon, color) = switch (event.trigger) {
          GamificationTrigger.interventionWorked => ('Focus Session', Icons.shield, AtariTheme.electricCyan),
          GamificationTrigger.todoCompleted => ('Todo Completed', Icons.check_box, AtariTheme.neonEmerald),
          GamificationTrigger.healthTargetMet => ('Health Target', Icons.favorite, AtariTheme.roseWarning),
          GamificationTrigger.captureOrganized => ('Note Organized', Icons.note, AtariTheme.amberAlert),
        };
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: AtariTheme.cardDecoration,
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: AtariTheme.body)),
              Text('+${event.xpAwarded} XP',
                  style: AtariTheme.body.copyWith(
                      color: AtariTheme.neonEmerald, fontWeight: FontWeight.w700)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
