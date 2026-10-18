import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../pets/domain/entities/pet.dart';
import '../../domain/entities/health_measurement.dart';
import '../../domain/entities/vaccination.dart';
import '../providers/health_controller.dart';

class HealthAnalyticsPage extends StatefulWidget {
  const HealthAnalyticsPage({
    required this.pet,
    required this.controller,
    super.key,
  });

  final Pet pet;
  final HealthController controller;

  @override
  State<HealthAnalyticsPage> createState() => _HealthAnalyticsPageState();
}

class _HealthAnalyticsPageState extends State<HealthAnalyticsPage> {
  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_onControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadRecords();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadRecords() async {
    await widget.controller.loadHealthRecords(widget.pet.petId);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final petId = widget.pet.petId;

    final conditions = controller.medicalConditions
        .where((record) => record.petId == petId)
        .toList();

    final vaccinations = controller.vaccinations
        .where((record) => record.petId == petId)
        .toList();

    final treatments = controller.treatments
        .where((record) => record.petId == petId)
        .toList();

    final measurements = controller.healthMeasurements
        .where((record) => record.petId == petId)
        .toList();

    final hasRecords =
        conditions.isNotEmpty ||
        vaccinations.isNotEmpty ||
        treatments.isNotEmpty ||
        measurements.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Health Analytics')),
      body: RefreshIndicator(
        onRefresh: _loadRecords,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            _AnalyticsPetHeader(pet: widget.pet),
            const SizedBox(height: 22),
            if (controller.isLoading && !hasRecords)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (controller.errorMessage != null)
                _AnalyticsErrorCard(
                  message: controller.errorMessage!,
                  onRetry: _loadRecords,
                ),
              _AnalyticsSectionHeading(
                title: 'Health Overview',
                subtitle:
                    'A summary of your pet’s recorded health information.',
              ),
              const SizedBox(height: 12),
              _AnalyticsMetricGrid(
                items: [
                  _AnalyticsMetric(
                    title: 'Medical Conditions',
                    count: conditions.length,
                    icon: Icons.medical_information_outlined,
                  ),
                  _AnalyticsMetric(
                    title: 'Vaccinations',
                    count: vaccinations.length,
                    icon: Icons.vaccines_outlined,
                  ),
                  _AnalyticsMetric(
                    title: 'Treatments',
                    count: treatments.length,
                    icon: Icons.medication_outlined,
                  ),
                  _AnalyticsMetric(
                    title: 'Measurements',
                    count: measurements.length,
                    icon: Icons.monitor_heart_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              _AnalyticsSectionHeading(
                title: 'Vaccination Status',
                subtitle: 'Review recorded vaccination schedules.',
              ),
              const SizedBox(height: 12),
              _VaccinationAnalytics(vaccinations: vaccinations),
              const SizedBox(height: 26),
              _AnalyticsSectionHeading(
                title: 'Medical Conditions',
                subtitle: 'Distribution of recorded condition statuses.',
              ),
              const SizedBox(height: 12),
              _StatusBreakdown(
                records: conditions.map((record) => record.status).toList(),
                emptyMessage: 'No medical conditions have been recorded.',
              ),
              const SizedBox(height: 26),
              _AnalyticsSectionHeading(
                title: 'Treatment Analytics',
                subtitle: 'Distribution of recorded treatment statuses.',
              ),
              const SizedBox(height: 12),
              _StatusBreakdown(
                records: treatments.map((record) => record.status).toList(),
                emptyMessage: 'No treatments have been recorded.',
              ),
              const SizedBox(height: 26),
              _AnalyticsSectionHeading(
                title: 'Weight Trends',
                subtitle: 'Review changes across recorded weight measurements.',
              ),
              const SizedBox(height: 12),
              _WeightTrendSection(measurements: measurements),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.secondary.withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppTheme.deepBrown),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'These analytics are calculated from the health '
                        'records saved for this pet. They are intended to '
                        'help monitor records and do not replace veterinary '
                        'advice.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Pet header
// -----------------------------------------------------------------------------

class _AnalyticsPetHeader extends StatelessWidget {
  const _AnalyticsPetHeader({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: pet.imageUrl.isEmpty
                ? const Icon(
                    Icons.pets_rounded,
                    size: 30,
                    color: AppTheme.deepBrown,
                  )
                : Image.network(
                    pet.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return const Icon(
                        Icons.pets_rounded,
                        size: 30,
                        color: AppTheme.deepBrown,
                      );
                    },
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pet.species} • ${pet.breed}',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.deepBrown),
                ),
                const SizedBox(height: 4),
                Text(
                  'Personal health analytics',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.deepBrown.withValues(alpha: 0.7),
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

// -----------------------------------------------------------------------------
// Section heading
// -----------------------------------------------------------------------------

class _AnalyticsSectionHeading extends StatelessWidget {
  const _AnalyticsSectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(color: AppTheme.espresso, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppTheme.deepBrown.withValues(alpha: 0.75)),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Overview metrics
// -----------------------------------------------------------------------------

class _AnalyticsMetric {
  const _AnalyticsMetric({
    required this.title,
    required this.count,
    required this.icon,
  });

  final String title;
  final int count;
  final IconData icon;
}

class _AnalyticsMetricGrid extends StatelessWidget {
  const _AnalyticsMetricGrid({required this.items});

  final List<_AnalyticsMetric> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: cardWidth,
              child: _AnalyticsMetricCard(item: item),
            );
          }).toList(),
        );
      },
    );
  }
}

class _AnalyticsMetricCard extends StatelessWidget {
  const _AnalyticsMetricCard({required this.item});

  final _AnalyticsMetric item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 142,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: AppTheme.deepBrown),
          ),
          const Spacer(),
          Text(
            '${item.count}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.deepBrown,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Vaccination analytics
// -----------------------------------------------------------------------------

class _VaccinationAnalytics extends StatelessWidget {
  const _VaccinationAnalytics({required this.vaccinations});

  final List<Vaccination> vaccinations;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());

    var overdue = 0;
    var dueToday = 0;
    var upcoming = 0;
    var unscheduled = 0;

    for (final vaccination in vaccinations) {
      final dueDate = vaccination.nextDueDate;

      if (dueDate == null) {
        unscheduled++;
        continue;
      }

      final date = DateUtils.dateOnly(dueDate);

      if (date.isBefore(today)) {
        overdue++;
      } else if (date.isAtSameMomentAs(today)) {
        dueToday++;
      } else {
        upcoming++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          _VaccinationStatusRow(
            title: 'Overdue',
            subtitle: 'Past the recorded due date',
            count: overdue,
            icon: Icons.warning_amber_rounded,
            color: Colors.red.shade700,
          ),
          const Divider(height: 24),
          _VaccinationStatusRow(
            title: 'Due today',
            subtitle: 'Scheduled for today',
            count: dueToday,
            icon: Icons.today_rounded,
            color: Colors.orange.shade800,
          ),
          const Divider(height: 24),
          _VaccinationStatusRow(
            title: 'Upcoming',
            subtitle: 'Scheduled for a future date',
            count: upcoming,
            icon: Icons.event_available_outlined,
            color: Colors.green.shade700,
          ),
          const Divider(height: 24),
          _VaccinationStatusRow(
            title: 'Unscheduled',
            subtitle: 'No next due date recorded',
            count: unscheduled,
            icon: Icons.event_note_outlined,
            color: AppTheme.deepBrown,
          ),
        ],
      ),
    );
  }
}

class _VaccinationStatusRow extends StatelessWidget {
  const _VaccinationStatusRow({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.espresso,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.deepBrown.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(color: color, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Medical condition and treatment status breakdown
// -----------------------------------------------------------------------------

class _StatusBreakdown extends StatelessWidget {
  const _StatusBreakdown({required this.records, required this.emptyMessage});

  final List<String> records;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return _AnalyticsEmptyCard(message: emptyMessage);
    }

    final counts = <String, int>{};

    for (final record in records) {
      final normalized = record.trim().isEmpty ? 'Unknown' : record.trim();

      counts.update(normalized, (count) => count + 1, ifAbsent: () => 1);
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: entries.map((entry) {
          final proportion = entry.value / records.length;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatStatus(entry.key),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.deepBrown,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value} (${(proportion * 100).round()}%)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.espresso,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: proportion,
                    minHeight: 9,
                    backgroundColor: AppTheme.secondary.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.deepBrown,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatStatus(String status) {
    if (status.isEmpty) {
      return 'Unknown';
    }

    return '${status[0].toUpperCase()}${status.substring(1)}';
  }
}

// -----------------------------------------------------------------------------
// Weight trends
// -----------------------------------------------------------------------------

class _WeightTrendSection extends StatelessWidget {
  const _WeightTrendSection({required this.measurements});

  final List<HealthMeasurement> measurements;

  @override
  Widget build(BuildContext context) {
    final weightReadings = measurements.where((measurement) {
      return measurement.type.trim().toLowerCase().contains('weight') &&
          measurement.value.isFinite &&
          measurement.value > 0;
    }).toList()..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    if (weightReadings.isEmpty) {
      return const _AnalyticsEmptyCard(
        message:
            'No weight measurements have been recorded for this pet yet. '
            'Record measurements using the Health Measurements screen to '
            'start building a weight history.',
      );
    }

    // Keep different measurement units separate.
    final groups = <String, List<HealthMeasurement>>{};

    for (final reading in weightReadings) {
      final unitKey = reading.unit.trim().isEmpty
          ? 'unit not specified'
          : reading.unit.trim().toLowerCase();

      groups.putIfAbsent(unitKey, () => []).add(reading);
    }

    return Column(
      children: groups.values.map((readings) {
        final unit = readings.first.unit.trim().isEmpty
            ? 'Unit not specified'
            : readings.first.unit.trim();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _WeightTrendCard(readings: readings, unit: unit),
        );
      }).toList(),
    );
  }
}

class _WeightTrendCard extends StatelessWidget {
  const _WeightTrendCard({required this.readings, required this.unit});

  final List<HealthMeasurement> readings;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final latest = readings.last;
    final latestText = '${_formatNumber(latest.value)} $unit';

    final difference = readings.length >= 2
        ? latest.value - readings[readings.length - 2].value
        : null;

    final values = readings.map((reading) => reading.value).toList();
    final minimum = values.reduce((a, b) => a < b ? a : b);
    final maximum = values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.monitor_weight_outlined,
                color: AppTheme.deepBrown,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Weight ($unit)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.espresso,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${readings.length} '
                '${readings.length == 1 ? 'record' : 'records'}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppTheme.deepBrown),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            latestText,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.espresso,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Latest reading • ${_formatDate(latest.recordedAt)}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppTheme.deepBrown.withValues(alpha: 0.75)),
          ),
          if (difference != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    difference > 0
                        ? Icons.trending_up_rounded
                        : difference < 0
                        ? Icons.trending_down_rounded
                        : Icons.trending_flat_rounded,
                    size: 20,
                    color: AppTheme.deepBrown,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${difference > 0 ? '+' : ''}'
                      '${_formatNumber(difference)} $unit '
                      'since previous reading',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.deepBrown,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (readings.length >= 2) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Min: ${_formatNumber(minimum)} $unit',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.deepBrown),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Max: ${_formatNumber(maximum)} $unit',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.deepBrown),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 170,
              child: CustomPaint(
                painter: _WeightTrendPainter(
                  values: values,
                  lineColor: AppTheme.deepBrown,
                  gridColor: AppTheme.secondary.withValues(alpha: 0.4),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDate(readings.first.recordedAt),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.deepBrown),
                  ),
                ),
                Expanded(
                  child: Text(
                    _formatDate(readings.last.recordedAt),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppTheme.deepBrown),
                  ),
                ),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Add another weight reading to display a trend chart.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.deepBrown.withValues(alpha: 0.75),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeightTrendPainter extends CustomPainter {
  const _WeightTrendPainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) {
      return;
    }

    const horizontalPadding = 12.0;
    const verticalPadding = 14.0;

    final chartWidth = size.width - horizontalPadding * 2;
    final chartHeight = size.height - verticalPadding * 2;

    if (chartWidth <= 0 || chartHeight <= 0) {
      return;
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var index = 0; index < 4; index++) {
      final y = verticalPadding + chartHeight * index / 3;

      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        gridPaint,
      );
    }

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    final points = <Offset>[];

    for (var index = 0; index < values.length; index++) {
      final x = horizontalPadding + chartWidth * index / (values.length - 1);

      final normalized = range == 0 ? 0.5 : (maxValue - values[index]) / range;

      final y = verticalPadding + chartHeight * normalized;

      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);

    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = AppTheme.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final point in points) {
      canvas.drawCircle(point, 4.5, pointPaint);
      canvas.drawCircle(point, 4.5, pointBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightTrendPainter oldDelegate) {
    return !identical(oldDelegate.values, values) ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}

// -----------------------------------------------------------------------------
// Empty and error states
// -----------------------------------------------------------------------------

class _AnalyticsEmptyCard extends StatelessWidget {
  const _AnalyticsEmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.insert_chart_outlined_rounded,
            size: 38,
            color: AppTheme.deepBrown,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppTheme.deepBrown),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsErrorCard extends StatelessWidget {
  const _AnalyticsErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.espresso),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Formatting helpers
// -----------------------------------------------------------------------------

String _formatNumber(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final localDate = date.toLocal();

  return '${localDate.day} ${months[localDate.month - 1]} '
      '${localDate.year}';
}
