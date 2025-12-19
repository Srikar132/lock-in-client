import 'package:flutter/material.dart';
import 'dart:math' as math;

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  // --- Static sample data ---
  static const Duration _todayScreenTime = Duration(hours: 4, minutes: 26);
  static const int _focusSessions = 3;
  static const int _blocksToday = 47;
  static const double _avgDailyHours = 4.6;
  static const double _goalHours = 4.0;

  static const List<double> _weeklyUsageHours = [
    3.2,
    3.8,
    4.5,
    4.8,
    5.2,
    4.8,
    5.5,
  ];
  static const List<String> _weekDays = [
    'Mon',
    'Mon',
    'Tue',
    'Tue',
    'Wed',
    'Wed',
    'Thu',
    'Thu',
    'Fri',
    'Fri',
    'Sat',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            const SizedBox(height: 20),

            // Hero card - Today's Screen Time
            _HeroCard(
              title: "Today's Screen Time",
              value: _formatDuration(_todayScreenTime),
              subtitle: 'Keep it balanced',
            ),

            const SizedBox(height: 16),

            // Two stat cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Focus Sessions',
                    value: _focusSessions.toString(),
                    icon: Icons.access_time,
                    color: Colors.cyan,
                    borderColor: Colors.cyan.withOpacity(0.3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Blocks Today',
                    value: _blocksToday.toString(),
                    icon: Icons.block,
                    color: Colors.orange,
                    borderColor: Colors.orange.withOpacity(0.3),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const _SectionTitle('Weekly Usage'),
            const SizedBox(height: 12),

            // Line chart
            _WeeklyUsageChart(
              data: _weeklyUsageHours,
              avgHours: _avgDailyHours,
              goalHours: _goalHours,
              days: _weekDays,
            ),

            const SizedBox(height: 24),
            const _SectionTitle('Advanced Insights'),
            const SizedBox(height: 12),

            // Circular progress cards
            Row(
              children: [
                Expanded(
                  child: _CircularProgressCard(
                    value: 75,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CircularProgressCard(
                    value: 62,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Risk Assessment Cards
            Row(
              children: [
                Expanded(
                  child: _RiskCard(
                    title: 'Doom-scroll\nRisk',
                    level: 'High',
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RiskCard(
                    title: 'Sleep\nImpact',
                    level: 'Moderate',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Balance Score Card
            const _BalanceScoreCard(score: 32, rating: 'Fair'),

            const SizedBox(height: 24),
            const _SectionTitle('Focus Recap'),
            const SizedBox(height: 12),

            // Before/After Comparison
            Row(
              children: [
                Expanded(
                  child: _FocusRecapCard(
                    title: 'Before',
                    color: Colors.red,
                    metrics: const [
                      {'label': 'App Switches', 'value': '14', 'change': ''},
                      {'label': 'Avg. Duration', 'value': '6m', 'change': ''},
                      {'label': 'Scroll Events', 'value': '30', 'change': ''},
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FocusRecapCard(
                    title: 'After',
                    color: Colors.green,
                    metrics: const [
                      {
                        'label': 'App Switches',
                        'value': '10',
                        'change': '↓ 28%',
                      },
                      {
                        'label': 'Avg. Duration',
                        'value': '12m',
                        'change': '↑ 71%',
                      },
                      {
                        'label': 'Scroll Events',
                        'value': '5',
                        'change': '↓ 83%',
                      },
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const _SectionTitle('Small Wins to Try'),
            const SizedBox(height: 12),

            // Suggestions
            const _SuggestionTile(
              icon: Icons.nightlight_round,
              iconColor: Colors.green,
              title: 'Wind-down at 11:00 PM',
              description: 'Dim screen + avoid feeds 45 mins before bed.',
            ),
            const SizedBox(height: 12),
            const _SuggestionTile(
              icon: Icons.timer_outlined,
              iconColor: Colors.green,
              title: '15-min Feed Limit',
              description: 'One short window; then auto-enter Focus Mode.',
            ),
            const SizedBox(height: 12),
            const _SuggestionTile(
              icon: Icons.directions_walk,
              iconColor: Colors.green,
              title: 'Micro-breaks',
              description: 'Stand up every 45 mins; reset attention.',
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Start Focus Mode',
                    icon: Icons.spa_outlined,
                    backgroundColor: Colors.green.shade700,
                    textColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'Set Bedtime',
                    icon: Icons.access_time,
                    backgroundColor: Colors.grey.shade900,
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }
}

// --- UI Pieces ---

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.favorite, color: cs.primary, size: 24),
            const SizedBox(width: 10),
            const Text(
              'Digital Health',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Text(
          'Awareness first',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _HeroCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.phone_android,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color borderColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class _WeeklyUsageChart extends StatelessWidget {
  final List<double> data;
  final double avgHours;
  final double goalHours;
  final List<String> days;

  const _WeeklyUsageChart({
    required this.data,
    required this.avgHours,
    required this.goalHours,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 18,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Avg ${avgHours}h / day',
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Week',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(
                data: data,
                avgLine: avgHours,
                goalLine: goalHours,
                primaryColor: Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) {
              return Text(
                day,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CircularProgressCard extends StatelessWidget {
  final int value;
  final Color color;

  const _CircularProgressCard({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _CircularProgressPainter(
                progress: value / 100,
                color: color,
                backgroundColor: cs.outline.withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for line chart
class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final double avgLine;
  final double goalLine;
  final Color primaryColor;

  _LineChartPainter({
    required this.data,
    required this.avgLine,
    required this.goalLine,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final dashedPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final maxValue = data.reduce(math.max);
    final minValue = data.reduce(math.min);
    final range = maxValue - minValue;

    final path = Path();
    final fillPath = Path();

    // Draw dashed lines for avg and goal
    final avgY = size.height - ((avgLine - minValue) / range) * size.height;
    final goalY = size.height - ((goalLine - minValue) / range) * size.height;

    _drawDashedLine(
      canvas,
      dashedPaint,
      Offset(0, avgY),
      Offset(size.width, avgY),
    );
    _drawDashedLine(
      canvas,
      dashedPaint,
      Offset(0, goalY),
      Offset(size.width, goalY),
    );

    // Draw line chart
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - ((data[i] - minValue) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - ((data[i] - minValue) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    // Draw labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: 'avg ${avgLine}h',
      style: const TextStyle(color: Colors.grey, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - 60, avgY - 20));

    textPainter.text = TextSpan(
      text: 'goal ${goalLine}h',
      style: const TextStyle(color: Colors.grey, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - 60, goalY + 8));
  }

  void _drawDashedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    const dashWidth = 5;
    const dashSpace = 5;
    double distance = (end - start).distance;
    double dashCount = distance / (dashWidth + dashSpace);

    for (int i = 0; i < dashCount; i++) {
      double startX =
          start.dx +
          (end.dx - start.dx) * (i * (dashWidth + dashSpace) / distance);
      double startY =
          start.dy +
          (end.dy - start.dy) * (i * (dashWidth + dashSpace) / distance);
      double endX =
          start.dx +
          (end.dx - start.dx) *
              ((i * (dashWidth + dashSpace) + dashWidth) / distance);
      double endY =
          start.dy +
          (end.dy - start.dy) *
              ((i * (dashWidth + dashSpace) + dashWidth) / distance);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for circular progress
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 5, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Risk Card Widget
class _RiskCard extends StatelessWidget {
  final String title;
  final String level;
  final Color color;

  const _RiskCard({
    required this.title,
    required this.level,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.7),
              fontSize: 14,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            level,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Balance Score Card
class _BalanceScoreCard extends StatelessWidget {
  final int score;
  final String rating;

  const _BalanceScoreCard({required this.score, required this.rating});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'Balance Score',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _CircularProgressPainter(
                    progress: score / 100,
                    color: Colors.purple,
                    backgroundColor: cs.outline.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      score.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rating,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Overall Health',
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Focus Recap Card
class _FocusRecapCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<Map<String, String>> metrics;

  const _FocusRecapCard({
    required this.title,
    required this.color,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                title == 'Before' ? Icons.trending_down : Icons.trending_up,
                color: color,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...metrics.map(
            (metric) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    metric['label']!,
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        metric['value']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (metric['change']!.isNotEmpty)
                        Text(
                          metric['change']!,
                          style: TextStyle(
                            fontSize: 11,
                            color: metric['change']!.startsWith('↓')
                                ? Colors.green
                                : Colors.blue,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Suggestion Tile
class _SuggestionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _SuggestionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Action Button
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
