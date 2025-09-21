import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'data/workout_repository.dart';
import 'data/workout_session.dart';
import 'data/workout_set.dart';

// Analytics Data Provider
final analyticsDataProvider = FutureProvider<AnalyticsData>((ref) async {
  final workoutRepository = ref.read(workoutRepositoryProvider);
  return await workoutRepository.getAnalyticsData();
});

// Time Range Provider
final timeRangeProvider = StateProvider<TimeRange>((ref) => TimeRange.month);

enum TimeRange {
  week('Last 7 Days'),
  month('Last 30 Days'),
  quarter('Last 3 Months'),
  year('Last Year');

  const TimeRange(this.label);
  final String label;

  int get days {
    switch (this) {
      case TimeRange.week:
        return 7;
      case TimeRange.month:
        return 30;
      case TimeRange.quarter:
        return 90;
      case TimeRange.year:
        return 365;
    }
  }
}

class AnalyticsData {
  final int totalWorkouts;
  final double totalVolume;
  final Duration totalTime;
  final int totalSets;
  final int totalReps;
  final double averageRPE;
  final List<WorkoutSession> recentWorkouts;
  final Map<String, int> exerciseFrequency;
  final Map<String, double> muscleGroupVolume;
  final List<VolumeDataPoint> volumeHistory;
  final List<WorkoutFrequencyPoint> workoutFrequency;
  final Map<String, double> strengthProgress;

  AnalyticsData({
    required this.totalWorkouts,
    required this.totalVolume,
    required this.totalTime,
    required this.totalSets,
    required this.totalReps,
    required this.averageRPE,
    required this.recentWorkouts,
    required this.exerciseFrequency,
    required this.muscleGroupVolume,
    required this.volumeHistory,
    required this.workoutFrequency,
    required this.strengthProgress,
  });
}

class VolumeDataPoint {
  final DateTime date;
  final double volume;

  VolumeDataPoint({required this.date, required this.volume});
}

class WorkoutFrequencyPoint {
  final DateTime date;
  final int count;

  WorkoutFrequencyPoint({required this.date, required this.count});
}

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text(
          'Workout Analytics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Time Range Selector
          Consumer(builder: (context, ref, child) {
            final timeRange = ref.watch(timeRangeProvider);
            return PopupMenuButton<TimeRange>(
              icon: const Icon(LucideIcons.calendar, color: Colors.white),
              onSelected: (range) => ref.read(timeRangeProvider.notifier).state = range,
              itemBuilder: (context) => TimeRange.values.map((range) {
                return PopupMenuItem(
                  value: range,
                  child: Row(
                    children: [
                      Icon(
                        timeRange == range ? LucideIcons.check : LucideIcons.calendar,
                        size: 16,
                        color: timeRange == range ? const Color(0xFF00FF88) : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(range.label),
                    ],
                  ),
                );
              }).toList(),
            );
          }),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00FF88),
          labelColor: const Color(0xFF00FF88),
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Volume'),
            Tab(text: 'Strength'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildVolumeTab(),
          _buildStrengthTab(),
          _buildInsightsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer(builder: (context, ref, child) {
      final analyticsAsync = ref.watch(analyticsDataProvider);
      
      return analyticsAsync.when(
        data: (analytics) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Key Metrics Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Workouts',
                      analytics.totalWorkouts.toString(),
                      LucideIcons.activity,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Total Volume',
                      '${analytics.totalVolume.toStringAsFixed(0)} lbs',
                      LucideIcons.barChart3,
                      const Color(0xFF00FF88),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Total Time',
                      _formatDuration(analytics.totalTime),
                      LucideIcons.clock,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Avg RPE',
                      analytics.averageRPE.toStringAsFixed(1),
                      LucideIcons.zap,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Workout Frequency Chart
              const Text(
                'Workout Frequency',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildWorkoutFrequencyChart(analytics.workoutFrequency),
              ),
              const SizedBox(height: 24),
              
              // Exercise Frequency
              const Text(
                'Most Frequent Exercises',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              ...analytics.exerciseFrequency.entries
                  .take(5)
                  .map((entry) => _buildExerciseFrequencyItem(entry.key, entry.value)),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00FF88)),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading analytics',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildVolumeTab() {
    return Consumer(builder: (context, ref, child) {
      final analyticsAsync = ref.watch(analyticsDataProvider);
      
      return analyticsAsync.when(
        data: (analytics) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Volume Trend Chart
              const Text(
                'Volume Trend',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                height: 250,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildVolumeChart(analytics.volumeHistory),
              ),
              const SizedBox(height: 24),
              
              // Muscle Group Volume Distribution
              const Text(
                'Volume by Muscle Group',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildMuscleGroupChart(analytics.muscleGroupVolume),
              ),
              const SizedBox(height: 24),
              
              // Volume Statistics
              _buildVolumeStats(analytics),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00FF88)),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading volume data',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    });
  }

  Widget _buildStrengthTab() {
    return Consumer(builder: (context, ref, child) {
      final analyticsAsync = ref.watch(analyticsDataProvider);
      
      return analyticsAsync.when(
        data: (analytics) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Strength Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              ...analytics.strengthProgress.entries.map((entry) {
                return _buildStrengthProgressItem(entry.key, entry.value);
              }),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00FF88)),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading strength data',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    });
  }

  Widget _buildInsightsTab() {
    return Consumer(builder: (context, ref, child) {
      final analyticsAsync = ref.watch(analyticsDataProvider);
      
      return analyticsAsync.when(
        data: (analytics) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Workout Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildInsightCard(
                'Consistency Score',
                _calculateConsistencyScore(analytics),
                'Based on workout frequency and regularity',
                LucideIcons.target,
                Colors.green,
              ),
              
              _buildInsightCard(
                'Volume Trend',
                _getVolumeTrend(analytics.volumeHistory),
                'Your training volume over time',
                LucideIcons.trendingUp,
                const Color(0xFF00FF88),
              ),
              
              _buildInsightCard(
                'Recovery Balance',
                _calculateRecoveryBalance(analytics),
                'Balance between intensity and recovery',
                LucideIcons.heart,
                Colors.orange,
              ),
              
              _buildInsightCard(
                'Muscle Balance',
                _calculateMuscleBalance(analytics.muscleGroupVolume),
                'Distribution across muscle groups',
                LucideIcons.activity,
                Colors.blue,
              ),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00FF88)),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading insights',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    });
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutFrequencyChart(List<WorkoutFrequencyPoint> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No workout data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() < data.length) {
                  final date = data[value.toInt()].date;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                );
              },
              reservedSize: 28,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: data.length.toDouble() - 1,
        minY: 0,
        maxY: data.map((e) => e.count).reduce((a, b) => a > b ? a : b).toDouble() + 1,
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.count.toDouble());
            }).toList(),
            isCurved: true,
            color: const Color(0xFF00FF88),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF00FF88),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF00FF88).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeChart(List<VolumeDataPoint> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No volume data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1000,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() < data.length) {
                  final date = data[value.toInt()].date;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1000,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: data.length.toDouble() - 1,
        minY: 0,
        maxY: data.map((e) => e.volume).reduce((a, b) => a > b ? a : b) * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.volume);
            }).toList(),
            isCurved: true,
            color: const Color(0xFF00FF88),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF00FF88),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF00FF88).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleGroupChart(Map<String, double> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No muscle group data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final colors = [
      const Color(0xFF00FF88),
      Colors.blue,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.yellow,
    ];

    return PieChart(
      PieChartData(
        sections: data.entries.map((entry) {
          final index = data.keys.toList().indexOf(entry.key);
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: entry.value,
            title: '${(entry.value / data.values.reduce((a, b) => a + b) * 100).toStringAsFixed(0)}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildExerciseFrequencyItem(String exercise, int frequency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              exercise,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF88).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              frequency.toString(),
              style: const TextStyle(
                color: Color(0xFF00FF88),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeStats(AnalyticsData analytics) {
    final avgVolumePerWorkout = analytics.totalWorkouts > 0
        ? analytics.totalVolume / analytics.totalWorkouts
        : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Volume Statistics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Avg per Workout',
                '${avgVolumePerWorkout.toStringAsFixed(0)} lbs',
                LucideIcons.barChart,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Sets',
                analytics.totalSets.toString(),
                LucideIcons.layers,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Reps',
                analytics.totalReps.toString(),
                LucideIcons.repeat,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Avg RPE',
                analytics.averageRPE.toStringAsFixed(1),
                LucideIcons.zap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthProgressItem(String exercise, double progress) {
    final isPositive = progress > 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Progress over time period',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                '${isPositive ? '+' : ''}${progress.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    String title,
    String value,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _calculateConsistencyScore(AnalyticsData analytics) {
    // Simple consistency calculation based on workout frequency
    final daysWithWorkouts = analytics.workoutFrequency
        .where((point) => point.count > 0)
        .length;
    
    final totalDays = analytics.workoutFrequency.length;
    final consistency = totalDays > 0 ? (daysWithWorkouts / totalDays) * 100 : 0;
    
    return '${consistency.toStringAsFixed(0)}%';
  }

  String _getVolumeTrend(List<VolumeDataPoint> volumeHistory) {
    if (volumeHistory.length < 2) return 'Insufficient Data';
    
    final recent = volumeHistory.takeLast(7).map((e) => e.volume).toList();
    final previous = volumeHistory.take(volumeHistory.length - 7).map((e) => e.volume).toList();
    
    if (previous.isEmpty) return 'Trending Up';
    
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final previousAvg = previous.reduce((a, b) => a + b) / previous.length;
    
    if (recentAvg > previousAvg * 1.05) {
      return 'Trending Up';
    } else if (recentAvg < previousAvg * 0.95) {
      return 'Trending Down';
    } else {
      return 'Stable';
    }
  }

  String _calculateRecoveryBalance(AnalyticsData analytics) {
    // Simple recovery balance based on RPE and workout frequency
    if (analytics.averageRPE < 6) {
      return 'Well Recovered';
    } else if (analytics.averageRPE < 8) {
      return 'Moderate';
    } else {
      return 'High Intensity';
    }
  }

  String _calculateMuscleBalance(Map<String, double> muscleGroupVolume) {
    if (muscleGroupVolume.isEmpty) return 'No Data';
    
    final values = muscleGroupVolume.values.toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    
    final ratio = max > 0 ? min / max : 0;
    
    if (ratio > 0.7) {
      return 'Well Balanced';
    } else if (ratio > 0.4) {
      return 'Moderate Balance';
    } else {
      return 'Imbalanced';
    }
  }
}

// Extension to get last N elements
extension ListExtension<T> on List<T> {
  List<T> takeLast(int count) {
    if (count >= length) return this;
    return sublist(length - count);
  }
}