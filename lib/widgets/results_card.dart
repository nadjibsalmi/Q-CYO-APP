import 'package:flutter/material.dart';
import '../models/recommendation_result.dart';
import '../theme/app_theme.dart';

class ResultsCard extends StatelessWidget {
  final RecommendationResult result;

  const ResultsCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: colorScheme.primary, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '📊 Quantum-Optimized Recommendations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _QuantumStatusBanner(active: result.quantumOptimizationUsed),
            const SizedBox(height: 20),
            _SectionHeader('🌾 Yield Prediction'),
            _ResultRow('Prediction Method', result.yieldPredictionMethod),
            _ResultRow('Yield per Hectare', '${result.yieldPerHectare.toStringAsFixed(2)} tons'),
            _ResultRow('Total Yield', '${result.totalYield.toStringAsFixed(2)} tons'),
            const SizedBox(height: 20),
            _SectionHeader('🧪 Fertilizer Recommendations'),
            _ResultRow('Total Fertilizer', '${result.fertilizerTotalKgPerHa.toStringAsFixed(2)} kg/ha'),
            const SizedBox(height: 8),
            Text('NPK Breakdown:', style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NpkChip('N', result.npkBreakdown.n, Colors.blue),
                _NpkChip('P', result.npkBreakdown.p, Colors.orange),
                _NpkChip('K', result.npkBreakdown.k, Colors.red),
              ],
            ),
            _ResultRow('Timing', result.fertilizerTiming),
            _ResultRow('Cost per Hectare', '\$${result.fertilizerCostPerHa.toStringAsFixed(2)}'),
            _ResultRow('Total Cost', '\$${result.totalCostUsd.toStringAsFixed(2)}', isHighlighted: true),
            if (result.budgetConstraintUsd != null) ...[
              const SizedBox(height: 8),
              _BudgetBanner(
                withinBudget: result.withinBudget ?? false,
                budget: result.budgetConstraintUsd!,
                utilizationPercent: result.budgetUtilizationPercent,
              ),
            ],
            const SizedBox(height: 20),
            _SectionHeader('⚠️ Weather Risk Assessment'),
            _RiskBanner(level: result.weatherRiskLevel),
            if (result.riskFactors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Risk Factors:', style: TextStyle(fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: result.riskFactors.entries.map((e) {
                  return Chip(
                    label: Text('${e.key.replaceAll('_', ' ')}: ${e.value.toStringAsFixed(3)}'),
                    backgroundColor: e.value > 0.3
                        ? Colors.orange.withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            _SectionHeader('🤖 Model Information'),
            _ResultRow('ML Model Used', result.mlModelUsed ? '✅ Active' : '⚠️ Not Active'),
            _ResultRow('Area Processed', '${result.areaHectares.toStringAsFixed(2)} hectares'),
            if (result.timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Generated: ${_formatTimestamp(result.timestamp!)}',
                  style: TextStyle(fontSize: 12, color: colorScheme.outline, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }
}

class _QuantumStatusBanner extends StatelessWidget {
  final bool active;
  const _QuantumStatusBanner({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: Colors.purple),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quantum Optimization', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                Text(active ? '✅ Active' : '⚠️ Classical Only', style: const TextStyle(color: Colors.purple)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetBanner extends StatelessWidget {
  final bool withinBudget;
  final double budget;
  final double? utilizationPercent;
  const _BudgetBanner({
    required this.withinBudget,
    required this.budget,
    this.utilizationPercent,
  });

  @override
  Widget build(BuildContext context) {
    final color = withinBudget ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(withinBudget ? Icons.check_circle : Icons.warning, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  withinBudget
                      ? '✅ Within budget (\$${budget.toStringAsFixed(2)})'
                      : '⚠️ Over budget (\$${budget.toStringAsFixed(2)})',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          if (utilizationPercent != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (utilizationPercent! / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${utilizationPercent!.toStringAsFixed(1)}% of budget used',
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ],
      ),
    );
  }
}

class _RiskBanner extends StatelessWidget {
  final String level;
  const _RiskBanner({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RiskColors.forLevel(level),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Risk Level: $level',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;
  const _ResultRow(this.label, this.value, {this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _NpkChip extends StatelessWidget {
  final String nutrient;
  final double value;
  final Color color;
  const _NpkChip(this.nutrient, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        '$nutrient: ${value.toStringAsFixed(2)} kg',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color,
    );
  }
}
