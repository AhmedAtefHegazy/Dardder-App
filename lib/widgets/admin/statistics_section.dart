import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/statistics_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsSection extends StatelessWidget {
  const StatisticsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<StatisticsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error loading statistics: ${provider.error}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadStatistics(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Statistics Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildSummaryCards(context, provider),
            const SizedBox(height: 24),
            _buildCharts(context, provider),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCards(BuildContext context, StatisticsProvider provider) {
    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _StatCard(
            title: 'Total Users',
            value: provider.totalUsers.toString(),
            subtitle: '${provider.activeUsers} active',
            icon: Icons.people,
            color: Colors.blue,
          ),
          _StatCard(
            title: 'Products',
            value: provider.totalProducts.toString(),
            subtitle: '${provider.lowStockProducts} low stock',
            icon: Icons.inventory,
            color: Colors.green,
          ),
          _StatCard(
            title: 'Orders',
            value: provider.totalOrders.toString(),
            subtitle: '${provider.totalOrders} pending',
            icon: Icons.shopping_cart,
            color: Colors.orange,
          ),
          _StatCard(
            title: 'Revenue',
            value: '\$${provider.totalRevenue.toStringAsFixed(2)}',
            subtitle:
                '\$${provider.monthlyRevenue.toStringAsFixed(2)} this month',
            icon: Icons.attach_money,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(BuildContext context, StatisticsProvider provider) {
    return Column(
      children: [
        if (provider.revenueChart.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revenue Last 7 Days',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 &&
                                      value.toInt() <
                                          provider.revenueChart.length) {
                                    final date = DateTime.parse(provider
                                        .revenueChart[value.toInt()]['Date']);
                                    return Text(
                                      '${date.month}/${date.day}',
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: provider.revenueChart
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final revenue = entry.value['Revenue'];
                                return FlSpot(
                                  entry.key.toDouble(),
                                  revenue != null
                                      ? (revenue as num).toDouble()
                                      : 0.0,
                                );
                              }).toList(),
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.blue.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (provider.orderStatusChart.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Status Distribution',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: provider.orderStatusChart
                              .asMap()
                              .entries
                              .map((entry) {
                            final colors = [
                              Colors.blue,
                              Colors.green,
                              Colors.orange,
                              Colors.red
                            ];
                            final count = entry.value['Count'];
                            return PieChartSectionData(
                              color: colors[entry.key % colors.length],
                              value: count != null
                                  ? (count as num).toDouble()
                                  : 0.0,
                              title:
                                  '${entry.value['Status'] ?? 'Unknown'}\n${count ?? 0}',
                              radius: 100,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
