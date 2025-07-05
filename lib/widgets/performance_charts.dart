import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PerformanceCharts extends StatelessWidget {
  final Map<String, Map<String, dynamic>> weeklyPerformance;
  final Map<String, Map<String, dynamic>> monthlyPerformance;

  const PerformanceCharts({
    Key? key,
    required this.weeklyPerformance,
    required this.monthlyPerformance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildWeeklyChart(),
        SizedBox(height: 24),
        _buildMonthlyChart(),
        SizedBox(height: 24),
        _buildRankingChart(),
        SizedBox(height: 24),
        _buildDetailedPerformanceTable(),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kinerja Mingguan PIC (Technical + Non-Technical)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 300,
            child: weeklyPerformance.isEmpty
                ? Center(child: Text('Tidak ada data mingguan'))
                : BarChart(_buildBarChartData(weeklyPerformance)),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kinerja Bulanan PIC (Technical + Non-Technical)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 300,
            child: monthlyPerformance.isEmpty
                ? Center(child: Text('Tidak ada data bulanan'))
                : BarChart(_buildBarChartData(monthlyPerformance)),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingChart() {
    // Sort by performance for ranking
    final sortedWeekly = weeklyPerformance.entries.toList()
      ..sort((a, b) => (b.value['percentage'] as double).compareTo(a.value['percentage'] as double));

    final sortedMonthly = monthlyPerformance.entries.toList()
      ..sort((a, b) => (b.value['percentage'] as double).compareTo(a.value['percentage'] as double));

    return Row(
      children: [
        Expanded(child: _buildRankingList('Ranking Mingguan', sortedWeekly)),
        SizedBox(width: 16),
        Expanded(child: _buildRankingList('Ranking Bulanan', sortedMonthly)),
      ],
    );
  }

  Widget _buildRankingList(String title, List<MapEntry<String, Map<String, dynamic>>> sortedData) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 12),
          ...sortedData.take(5).map((entry) {
            final index = sortedData.indexOf(entry);
            final pic = entry.key;
            final data = entry.value;
            final percentage = data['percentage'] as double;
            final completed = data['completedTasks'] as int;
            final total = data['totalTasks'] as int;
            final technicalTasks = data['technicalTasks'] as int;
            final nonTechnicalTasks = data['nonTechnicalTasks'] as int;

            Color rankColor;
            IconData rankIcon;
            
            switch (index) {
              case 0:
                rankColor = Colors.amber;
                rankIcon = Icons.emoji_events;
                break;
              case 1:
                rankColor = Colors.grey.shade400;
                rankIcon = Icons.emoji_events;
                break;
              case 2:
                rankColor = Colors.orange.shade300;
                rankIcon = Icons.emoji_events;
                break;
              default:
                rankColor = Colors.grey.shade300;
                rankIcon = Icons.person;
            }

            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: index < 3 ? Border.all(color: rankColor, width: 1) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: rankColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(rankIcon, color: Colors.white, size: 12),
                            Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pic,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '$completed/$total (${percentage.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Tech: $technicalTasks',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Non-Tech: $nonTechnicalTasks',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDetailedPerformanceTable() {
    final sortedMonthly = monthlyPerformance.entries.toList()
      ..sort((a, b) => (b.value['percentage'] as double).compareTo(a.value['percentage'] as double));

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Performance Bulanan (Technical + Non-Technical)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.green.shade50),
              headingTextStyle: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.bold,
              ),
              columns: [
                DataColumn(label: Text('Rank')),
                DataColumn(label: Text('PIC')),
                DataColumn(label: Text('Total Tasks')),
                DataColumn(label: Text('Technical')),
                DataColumn(label: Text('Non-Technical')),
                DataColumn(label: Text('Completed')),
                DataColumn(label: Text('Performance')),
              ],
              rows: sortedMonthly.asMap().entries.map((entry) {
                final index = entry.key;
                final pic = entry.value.key;
                final data = entry.value.value;
                final percentage = data['percentage'] as double;
                final completed = data['completedTasks'] as int;
                final total = data['totalTasks'] as int;
                final technicalTasks = data['technicalTasks'] as int;
                final nonTechnicalTasks = data['nonTechnicalTasks'] as int;
                final technicalCompleted = data['technicalCompleted'] as int;
                final nonTechnicalCompleted = data['nonTechnicalCompleted'] as int;

                Color performanceColor;
                if (percentage >= 80) {
                  performanceColor = Colors.green;
                } else if (percentage >= 60) {
                  performanceColor = Colors.orange;
                } else if (percentage >= 40) {
                  performanceColor = Colors.amber;
                } else {
                  performanceColor = Colors.red;
                }

                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: index < 3 ? Colors.amber.shade100 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: index < 3 ? Colors.amber.shade700 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(pic, style: TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text('$total')),
                    DataCell(Text('$technicalTasks')),
                    DataCell(Text('$nonTechnicalTasks')),
                    DataCell(Text('$completed ($technicalCompleted + $nonTechnicalCompleted)')),
                    DataCell(
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: performanceColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: performanceColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  BarChartData _buildBarChartData(Map<String, Map<String, dynamic>> performanceData) {
    final entries = performanceData.entries.toList();
    
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 100,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < entries.length) {
                return Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    entries[value.toInt()].key,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              }
              return Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}%',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              );
            },
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value.value;
        final percentage = data['percentage'] as double;
        
        Color barColor;
        if (percentage >= 80) {
          barColor = Colors.green;
        } else if (percentage >= 60) {
          barColor = Colors.orange;
        } else if (percentage >= 40) {
          barColor = Colors.amber;
        } else {
          barColor = Colors.red;
        }
        
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: percentage,
              color: barColor,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }).toList(),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          );
        },
      ),
    );
  }
}