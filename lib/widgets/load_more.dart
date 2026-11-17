import 'package:flutter/material.dart';

/// How many rows a paged list loads at a time.
const loadMorePageSize = 20;

/// A list that loads its next page as the user scrolls to its end.
///
/// [builder] gets the controller to give its scroll view. Whenever that view
/// is within [threshold] pixels of its end, or too short to scroll at all,
/// and the list [hasMore] rows while not [loading] them, [onLoadMore] is
/// called once. Show a [LoadMoreIndicator] at the end of the list while it
/// [hasMore], so the user sees the next page coming.
class LoadMoreScrollView extends StatefulWidget {
  const LoadMoreScrollView({
    super.key,
    required this.hasMore,
    required this.loading,
    required this.onLoadMore,
    required this.builder,
    this.threshold = 200,
    this.controller,
  });

  final bool hasMore;
  final bool loading;
  final VoidCallback onLoadMore;
  final Widget Function(BuildContext context, ScrollController controller)
  builder;
  final double threshold;

  /// The scroll view's controller, when the caller needs it too (e.g. to
  /// scroll back to the top); otherwise one is made here.
  final ScrollController? controller;

  @override
  State<LoadMoreScrollView> createState() => _LoadMoreScrollViewState();
}

class _LoadMoreScrollViewState extends State<LoadMoreScrollView> {
  late final ScrollController _controller =
      widget.controller ?? ScrollController();

  /// Set once [LoadMoreScrollView.onLoadMore] is called, so scrolling on
  /// doesn't ask again before the parent has rebuilt with the request.
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_check);
  }

  @override
  void didUpdateWidget(LoadMoreScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _requested = false;
  }

  @override
  void dispose() {
    _controller.removeListener(_check);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _check() {
    if (!mounted || _requested || !widget.hasMore || widget.loading) return;
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (!position.hasContentDimensions) return;
    if (position.extentAfter <= widget.threshold) {
      _requested = true;
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // A page that doesn't fill the screen can't be scrolled to its end, so
    // look again once it is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    return widget.builder(context, _controller);
  }
}

/// The spinner at the end of a paged list while more rows are coming.
class LoadMoreIndicator extends StatelessWidget {
  const LoadMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}
