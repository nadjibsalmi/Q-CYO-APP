import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/recommendation_result.dart';
import '../widgets/farm_form.dart';
import '../widgets/results_card.dart';

/// BEFORE: this single file was 600+ lines mixing form state, API calls,
/// error handling, and results rendering all in one giant build() method.
/// AFTER: this screen only orchestrates - the form lives in FarmForm, the
/// results display lives in ResultsCard, and the API contract is a typed
/// RecommendationResult instead of a raw Map. Much easier to test, read,
/// and modify each piece independently.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  RecommendationResult? _recommendation;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isConnectionError = false;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() => _isLoading = true);
    final isConnected = await ApiService.testConnection();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isConnectionError = !isConnected;
      _errorMessage = isConnected
          ? ''
          : 'Cannot connect to API. Make sure the backend server is running at ${ApiService.baseUrl}';
    });
  }

  Future<void> _handleSubmit(FarmFormData data) async {
    setState(() {
      _isLoading = true;
      _recommendation = null;
      _errorMessage = '';
      _isConnectionError = false;
    });

    try {
      final result = await ApiService.getRecommendation(
        rainfall: data.rainfall,
        temperature: data.temperature,
        soilType: data.soilType,
        cropType: data.cropType,
        area: data.area,
        budget: data.budget,
      );
      if (!mounted) return;
      setState(() {
        _recommendation = result;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.psychology, color: colorScheme.primary),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Q-CYO: Quantum Crop Yield Optimizer',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // BEFORE: fixed-width Padding with no max-width constraint,
            // meaning the form would stretch edge-to-edge and look broken
            // on tablets, desktop, and the web/Linux/macOS/Windows targets
            // this project already ships (see pubspec.yaml platforms).
            final maxWidth = constraints.maxWidth > 700 ? 700.0 : double.infinity;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isConnectionError) ...[
                        _ConnectionErrorBanner(
                          message: _errorMessage,
                          onRetry: _testConnection,
                        ),
                        const SizedBox(height: 10),
                      ],
                      FarmForm(
                        initialData: FarmFormData(),
                        isLoading: _isLoading,
                        onSubmit: _handleSubmit,
                      ),
                      const SizedBox(height: 20),
                      // BEFORE: results and errors just popped in instantly
                      // with no transition, which feels abrupt after a
                      // loading spinner. AnimatedSwitcher gives a smooth
                      // fade+slight-scale entrance instead.
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.97, end: 1.0).animate(animation),
                            child: child,
                          ),
                        ),
                        child: Column(
                          key: ValueKey(
                            '${_errorMessage.isNotEmpty && !_isConnectionError}-${_recommendation != null}',
                          ),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_errorMessage.isNotEmpty && !_isConnectionError)
                              _ErrorBanner(message: _errorMessage),
                            if (_recommendation != null)
                              ResultsCard(result: _recommendation!),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ConnectionErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ConnectionErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'API Connection Required',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: Colors.orange)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Error', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 4),
                  Text(message, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
