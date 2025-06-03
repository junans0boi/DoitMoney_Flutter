// lib/features/chart/screens/chart_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/chart_service.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({Key? key}) : super(key: key);

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final ChartService _chartService = ChartService();

  List<String> _monthLabels = [];
  List<double> _monthValues = [];
  Map<String, double> _categoryData = {};

  bool _loadingMonthly = true;
  bool _loadingCategory = false;

  @override
  void initState() {
    super.initState();
    _loadMonthlyData();
  }

  Future<void> _loadMonthlyData() async {
    setState(() => _loadingMonthly = true);
    try {
      final raw = await _chartService.fetchMonthlyExpenses(monthsBack: 3);
      _monthLabels = raw.keys.toList();
      _monthValues = raw.values.map((v) => (v as num).toDouble()).toList();

      if (_monthLabels.isNotEmpty) {
        final lastLabel = _monthLabels.last.split('-');
        final year = int.parse(lastLabel[0]);
        final month = int.parse(lastLabel[1]);
        await _loadCategoryData(year: year, month: month);
      }
    } catch (e) {
      debugPrint("월별 차트 데이터 로드 오류: $e");
    } finally {
      setState(() => _loadingMonthly = false);
    }
  }

  Future<void> _loadCategoryData({
    required int year,
    required int month,
  }) async {
    setState(() {
      _loadingCategory = true;
      _categoryData = {};
    });
    try {
      final raw = await _chartService.fetchCategoryExpenses(
        year: year,
        month: month,
      );
      _categoryData = raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (e) {
      debugPrint("카테고리 차트 데이터 로드 오류: $e");
    } finally {
      setState(() {
        _loadingCategory = false;
      });
    }
  }

  List<BarChartGroupData> _buildMonthlyBarGroups() {
    return List.generate(_monthValues.length, (idx) {
      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: _monthValues[idx] / 10000, // 만원 단위로 축소
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  List<PieChartSectionData> _buildCategoryPieSections() {
    final total = _categoryData.values.fold<double>(0, (a, b) => a + b);
    int idx = 0;
    final colors = [
      Colors.blueAccent,
      Colors.redAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.brown,
      Colors.cyanAccent,
    ];

    return _categoryData.entries.map((e) {
      final value = e.value;
      final percent = total == 0 ? 0.0 : (value / total) * 100;
      final section = PieChartSectionData(
        value: value,
        color: colors[idx % colors.length],
        title: "${percent.toStringAsFixed(1)}%",
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
      idx++;
      return section;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('거래 데이터 차트')),
      body:
          _loadingMonthly
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '최근 3개월 월별 지출',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 250,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY:
                                (_monthValues.isEmpty
                                    ? 1.0
                                    : (_monthValues.reduce(
                                          (a, b) => a > b ? a : b,
                                        ) /
                                        10000)) *
                                1.1,
                            barGroups: _buildMonthlyBarGroups(),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  getTitlesWidget: (val, meta) {
                                    return Text('${(val * 10000).toInt()}');
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, meta) {
                                    int idx = val.toInt();
                                    if (idx < 0 || idx >= _monthLabels.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      _monthLabels[idx].split('-')[1] + '월',
                                    );
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(show: true),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 특정 월의 카테고리별 파이 차트
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '카테고리별 지출 비중',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DropdownButton<String>(
                            value:
                                _monthLabels.isEmpty ? null : _monthLabels.last,
                            items:
                                _monthLabels
                                    .map(
                                      (label) => DropdownMenuItem(
                                        value: label,
                                        child: Text(
                                          label.replaceAll('-', '년 ') + '월',
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (sel) async {
                              if (sel == null) return;
                              final parts = sel.split('-');
                              final y = int.parse(parts[0]);
                              final m = int.parse(parts[1]);
                              await _loadCategoryData(year: y, month: m);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _loadingCategory
                          ? const Center(child: CircularProgressIndicator())
                          : (_categoryData.isEmpty
                              ? const Center(child: Text('해당 월에 기록된 지출이 없습니다.'))
                              : SizedBox(
                                height: 250,
                                child: PieChart(
                                  PieChartData(
                                    sections: _buildCategoryPieSections(),
                                    centerSpaceRadius: 40,
                                    sectionsSpace: 2,
                                  ),
                                ),
                              )),
                    ],
                  ),
                ),
              ),
    );
  }
}
