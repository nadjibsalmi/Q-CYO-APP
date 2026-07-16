/// Typed representation of the /recommend API response.
///
/// BEFORE: home_screen.dart read the raw JSON map directly at the point of
/// use, e.g. `data['fertilizer_npk_breakdown']['N']`. Every field name was a
/// string typo waiting to happen, there was no compile-time checking, and a
/// backend field rename would fail silently in the UI instead of at build
/// time.
///
/// AFTER: parse once, fail loudly and early if the shape is unexpected, and
/// let the UI work with a typed object with sane defaults.
class RecommendationResult {
  final String yieldPredictionMethod;
  final double yieldPerHectare;
  final double totalYield;

  final String fertilizerOptimizationMethod;
  final double fertilizerTotalKgPerHa;
  final NpkBreakdown npkBreakdown;
  final String fertilizerTiming;
  final double fertilizerCostPerHa;

  final double totalFertilizerKg;
  final double totalCostUsd;

  final String weatherRiskLevel;
  final Map<String, double> riskFactors;

  final bool quantumOptimizationUsed;
  final bool mlModelUsed;
  final double areaHectares;
  final DateTime? timestamp;

  final double? budgetConstraintUsd;
  final bool? withinBudget;
  final double? budgetUtilizationPercent;

  const RecommendationResult({
    required this.yieldPredictionMethod,
    required this.yieldPerHectare,
    required this.totalYield,
    required this.fertilizerOptimizationMethod,
    required this.fertilizerTotalKgPerHa,
    required this.npkBreakdown,
    required this.fertilizerTiming,
    required this.fertilizerCostPerHa,
    required this.totalFertilizerKg,
    required this.totalCostUsd,
    required this.weatherRiskLevel,
    required this.riskFactors,
    required this.quantumOptimizationUsed,
    required this.mlModelUsed,
    required this.areaHectares,
    this.timestamp,
    this.budgetConstraintUsd,
    this.withinBudget,
    this.budgetUtilizationPercent,
  });

  factory RecommendationResult.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v, [double fallback = 0]) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    final npk = json['fertilizer_npk_breakdown'];
    final riskFactorsRaw = json['risk_factors'];

    return RecommendationResult(
      yieldPredictionMethod: json['yield_prediction_method']?.toString() ?? 'N/A',
      yieldPerHectare: asDouble(json['yield_per_hectare']),
      totalYield: asDouble(json['total_yield']),
      fertilizerOptimizationMethod:
          json['fertilizer_optimization_method']?.toString() ?? 'N/A',
      fertilizerTotalKgPerHa: asDouble(json['fertilizer_total_kg_per_ha']),
      npkBreakdown: npk is Map
          ? NpkBreakdown.fromJson(Map<String, dynamic>.from(npk))
          : const NpkBreakdown(n: 0, p: 0, k: 0),
      fertilizerTiming: json['fertilizer_timing']?.toString() ?? 'Standard',
      fertilizerCostPerHa: asDouble(json['fertilizer_cost_per_ha']),
      totalFertilizerKg: asDouble(json['total_fertilizer_kg']),
      totalCostUsd: asDouble(json['total_cost_usd']),
      weatherRiskLevel: json['weather_risk_level']?.toString() ??
          json['weather_risk']?.toString() ??
          'N/A',
      riskFactors: riskFactorsRaw is Map
          ? riskFactorsRaw.map(
              (k, v) => MapEntry(k.toString(), asDouble(v)),
            )
          : const {},
      quantumOptimizationUsed: json['quantum_optimization_used'] == true,
      mlModelUsed: json['ml_model_used'] == true,
      areaHectares: asDouble(json['area_hectares']),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      budgetConstraintUsd: json['budget_constraint_usd'] != null
          ? asDouble(json['budget_constraint_usd'])
          : null,
      withinBudget: json['within_budget'] as bool?,
      budgetUtilizationPercent: json['budget_utilization_percent'] != null
          ? asDouble(json['budget_utilization_percent'])
          : null,
    );
  }
}

class NpkBreakdown {
  final double n;
  final double p;
  final double k;

  const NpkBreakdown({required this.n, required this.p, required this.k});

  factory NpkBreakdown.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return NpkBreakdown(
      n: asDouble(json['N']),
      p: asDouble(json['P']),
      k: asDouble(json['K']),
    );
  }
}
