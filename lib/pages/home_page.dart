import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/flight_providers.dart';
import '../widgets/flight_card.dart';
import 'recording_page.dart';
import 'flight_detail_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flights = ref.watch(flightListProvider);
    final isRecording = ref.watch(recordingStateProvider);
    final recentFlights = flights.take(3).toList();
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      top: -40,
                      child: Icon(Icons.flight, size: 180, color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Icon(Icons.flight, size: 120, color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Welcome back,', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text('Pilot Logbook', style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: isRecording
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade50, Colors.red.shade100],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const _PulsingDot(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Recording in progress', style: theme.textTheme.titleSmall?.copyWith(color: Colors.red.shade800, fontWeight: FontWeight.w600)),
                              Text('Tap to view recording', style: theme.textTheme.bodySmall?.copyWith(color: Colors.red.shade600)),
                            ],
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordingPage())),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Open'),
                          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red.shade800),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordingPage())),
                      icon: const Icon(Icons.fiber_manual_record, size: 22),
                      label: const Text('Start Recording'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Flights', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  if (flights.length > 3)
                    TextButton(
                      onPressed: () {},
                      child: const Text('See all'),
                    ),
                ],
              ),
            ),
          ),
          if (recentFlights.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flight, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('No flights yet', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Text('Start recording your first flight!', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => FlightCard(
                  flight: recentFlights[index],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FlightDetailPage(flight: recentFlights[index])),
                  ),
                ),
                childCount: recentFlights.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}
class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animation = Tween<double>(begin: 1.0, end: 0.3).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: Container(
      width: 12, height: 12,
      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
    ));
  }
}
