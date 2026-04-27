import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/simVM.dart';
import 'appDrawer.dart';
import '../theme/game_theme.dart';
import '../widgets/app_nav.dart';
import '../widgets/results/results_step_bar.dart';
import '../widgets/results/results_match_list.dart';
import '../widgets/results/results_comparison.dart';
import '../widgets/results/results_nav_bar.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _step = 0; // 0 = your show, 1 = AI show, 2 = comparison

  @override
  Widget build(BuildContext context) {
    return Consumer<SimViewModel>(
      builder: (context, sim, _) {
        if (sim.weekResults.isEmpty) {
          return Scaffold(
            backgroundColor: GameTheme.bg,
            drawer: const AppDrawer(),
            appBar: AppBar(
              leading: AppNav.backButton(context),
              title: const Text('Results'),
              actions: [AppNav.menuButton()],
            ),
            body: const Center(
              child: Text('No results yet', style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        final summary = sim.history.isNotEmpty ? sim.history.last : null;

        return Scaffold(
          backgroundColor: GameTheme.bg,
          drawer: const AppDrawer(),
          appBar: AppBar(
            leading: AppNav.backButton(context),
            title: Text(_stepTitle),
            actions: [
              AppNav.menuButton(),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text('${_step + 1} / 3',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/arena_crowd.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.68),
                ),
              ),
              Column(
                children: [
                  ResultsStepIndicator(step: _step),
                  if (summary != null) ResultsSummaryBar(summary: summary),
                  Expanded(child: _buildPage(sim)),
                  ResultsNavBar(
                    step: _step,
                    sim: sim,
                    onNext: () => setState(() => _step++),
                    onBack: () => setState(() => _step--),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String get _stepTitle {
    switch (_step) {
      case 0: return 'Your Show';
      case 1: return 'AI\'s Show';
      default: return 'Comparison';
    }
  }

  Widget _buildPage(SimViewModel sim) {
    switch (_step) {
      case 0:
        return ResultsMatchList(results: sim.weekResults, promos: sim.promos);
      case 1:
        return sim.aiWeekResults.isEmpty
            ? const Center(
                child: Text('AI results unavailable',
                    style: TextStyle(color: Colors.grey)))
            : ResultsMatchList(results: sim.aiWeekResults, promos: const []);
      default:
        return ResultsComparisonChart(sim: sim);
    }
  }
}

// â”€â”€â”€ STEP INDICATOR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

