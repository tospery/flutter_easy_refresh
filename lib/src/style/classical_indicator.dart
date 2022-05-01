part of easyrefresh;

/// Classical indicator.
/// Base widget for [ClassicalHeader] and [ClassicalFooter].
class _ClassicalIndicator extends StatefulWidget {
  /// Indicator properties and state.
  final IndicatorState state;

  /// The location of the widget.
  /// Only supports [MainAxisAlignment.center],
  /// [MainAxisAlignment.start] and [MainAxisAlignment.end].
  final MainAxisAlignment mainAxisAlignment;

  /// Background color.
  final Color backgroundColor;

  /// Text on [IndicatorMode.drag].
  final String dragText;

  /// Text on [IndicatorMode.armed].
  final String armedText;

  /// Text on [IndicatorMode.ready].
  final String readyText;

  /// Text on [IndicatorMode.processing].
  final String processingText;

  /// Text on [IndicatorMode.processed].
  final String processedText;

  /// Text on [IndicatorResult.noMore].
  final String noMoreText;

  /// Text on [IndicatorMode.failed].
  final String failedText;

  /// Whether to display text.
  final bool showText;

  /// Message text.
  /// %T will be replaced with the last time.
  final String messageText;

  /// Whether to display message.
  final bool showMessage;

  /// The dimension of the text area.
  /// When less than 0, calculate the length of the text widget.
  final double? textDimension;

  /// The dimension of the icon area.
  final double iconDimension;

  /// Spacing between text and icon.
  final double spacing;

  /// True for up and left.
  /// False for down and right.
  final bool reverse;

  const _ClassicalIndicator({
    Key? key,
    required this.state,
    required this.mainAxisAlignment,
    this.backgroundColor = Colors.transparent,
    required this.dragText,
    required this.armedText,
    required this.readyText,
    required this.processingText,
    required this.processedText,
    required this.noMoreText,
    required this.failedText,
    this.showText = true,
    required this.messageText,
    required this.reverse,
    this.showMessage = true,
    this.textDimension,
    this.iconDimension = 24,
    this.spacing = 16,
  })  : assert(
            mainAxisAlignment == MainAxisAlignment.start ||
                mainAxisAlignment == MainAxisAlignment.center ||
                mainAxisAlignment == MainAxisAlignment.end,
            'Only supports [MainAxisAlignment.center], [MainAxisAlignment.start] and [MainAxisAlignment.end].'),
        super(key: key);

  @override
  State<_ClassicalIndicator> createState() => _ClassicalIndicatorState();
}

class _ClassicalIndicatorState extends State<_ClassicalIndicator>
    with TickerProviderStateMixin<_ClassicalIndicator> {
  /// Icon [AnimatedSwitcher] switch key.
  final _iconAnimatedSwitcherKey = GlobalKey();

  /// Update time.
  late DateTime _updateTime;

  /// Icon animation controller.
  late AnimationController _iconAnimationController;

  MainAxisAlignment get _mainAxisAlignment => widget.mainAxisAlignment;

  Axis get _axis => widget.state.axis;

  double get _offset => widget.state.offset;

  double get _actualTriggerOffset => widget.state.actualTriggerOffset;

  double get _triggerOffset => widget.state.triggerOffset;

  double get _safeOffset => widget.state.safeOffset;

  IndicatorMode get _mode => widget.state.mode;

  IndicatorResult get _result => widget.state.result;

  @override
  void initState() {
    super.initState();
    _updateTime = DateTime.now();
    _iconAnimationController = AnimationController(
      value: 0,
      vsync: this,
      duration: const Duration(microseconds: 200),
    );
    _iconAnimationController.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(_ClassicalIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update time.
    if (widget.state.mode == IndicatorMode.processed &&
        oldWidget.state.mode != IndicatorMode.processed) {
      _updateTime = DateTime.now();
    }
    if (widget.state.mode == IndicatorMode.armed &&
        oldWidget.state.mode == IndicatorMode.drag) {
      // Armed animation.
      _iconAnimationController.animateTo(1,
          duration: const Duration(milliseconds: 200));
    } else if (widget.state.mode == IndicatorMode.drag &&
        oldWidget.state.mode == IndicatorMode.armed) {
      // Recovery animation.
      _iconAnimationController.animateBack(0,
          duration: const Duration(milliseconds: 200));
    } else if (widget.state.mode == IndicatorMode.processing &&
        oldWidget.state.mode != IndicatorMode.processing) {
      // Reset animation.
      _iconAnimationController.reset();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _iconAnimationController.dispose();
  }

  /// The text of the current state.
  String get _currentText {
    if (_result == IndicatorResult.noMore) {
      return widget.noMoreText;
    }
    switch (_mode) {
      case IndicatorMode.drag:
        return widget.dragText;
      case IndicatorMode.armed:
        return widget.armedText;
      case IndicatorMode.ready:
        return widget.readyText;
      case IndicatorMode.processing:
        return widget.processingText;
      case IndicatorMode.processed:
      case IndicatorMode.done:
        if (_result == IndicatorResult.failed) {
          return widget.failedText;
        } else {
          return widget.processedText;
        }
      default:
        return '';
    }
  }

  /// Message text.
  String get _messageText {
    if (widget.messageText.contains('%T')) {
      String fillChar = _updateTime.minute < 10 ? "0" : "";
      return widget.messageText.replaceAll(
          "%T", "${_updateTime.hour}:$fillChar${_updateTime.minute}");
    }
    return widget.messageText;
  }

  /// Build icon.
  Widget _buildIcon() {
    Widget icon;
    if (_result == IndicatorResult.noMore) {
      icon = const Icon(
        Icons.inbox_outlined,
        key: ValueKey(IndicatorResult.noMore),
      );
    } else if (_mode == IndicatorMode.processing ||
        _mode == IndicatorMode.ready) {
      icon = SizedBox(
        key: const ValueKey(IndicatorMode.processing),
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).iconTheme.color,
        ),
      );
    } else if (_mode == IndicatorMode.processed ||
        _mode == IndicatorMode.done) {
      if (_result == IndicatorResult.failed) {
        icon = const Icon(
          Icons.error_outline,
          key: ValueKey(IndicatorResult.failed),
        );
      } else {
        icon = const Icon(
          Icons.done,
          key: ValueKey(IndicatorResult.succeeded),
        );
      }
    } else {
      icon = Transform.rotate(
        key: const ValueKey(IndicatorMode.drag),
        angle: pi * _iconAnimationController.value * (widget.reverse ? 1 : -1),
        child: Icon(widget.reverse ? Icons.arrow_upward : Icons.arrow_downward),
      );
    }
    return AnimatedSwitcher(
      key: _iconAnimatedSwitcherKey,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return FadeTransition(
            child: ScaleTransition(
              child: child,
              scale: animation,
            ),
            opacity: animation);
      },
      child: icon,
    );
  }

  /// When the list direction is vertically.
  Widget _buildVerticalWidget() {
    return Stack(
      children: [
        if (_mainAxisAlignment == MainAxisAlignment.center)
          Positioned(
            left: 0,
            right: 0,
            top: _offset < _actualTriggerOffset
                ? -(_actualTriggerOffset -
                        _offset +
                        (widget.reverse ? _safeOffset : -_safeOffset)) /
                    2
                : (!widget.reverse ? _safeOffset : 0),
            bottom: _offset < _actualTriggerOffset
                ? null
                : (widget.reverse ? _safeOffset : 0),
            height:
                _offset < _actualTriggerOffset ? _actualTriggerOffset : null,
            child: Center(
              child: _buildVerticalBody(),
            ),
          ),
        if (_mainAxisAlignment != MainAxisAlignment.center)
          Positioned(
            left: 0,
            right: 0,
            top: _mainAxisAlignment == MainAxisAlignment.start
                ? (!widget.reverse ? _safeOffset : 0)
                : null,
            bottom: _mainAxisAlignment == MainAxisAlignment.end
                ? (widget.reverse ? _safeOffset : 0)
                : null,
            child: _buildVerticalBody(),
          ),
      ],
    );
  }

  /// The body when the list is vertically direction.
  Widget _buildVerticalBody() {
    Widget textWidget = Text(
      _currentText,
      style: Theme.of(context).textTheme.titleMedium,
    );
    Widget messageWidget = Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        _messageText,
        style: Theme.of(context).textTheme.caption,
      ),
    );
    return Container(
      alignment: Alignment.center,
      height: _triggerOffset,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            alignment: Alignment.center,
            width: widget.iconDimension,
            child: _buildIcon(),
          ),
          if (widget.showText)
            Container(
              margin: EdgeInsets.only(left: widget.spacing),
              width: widget.textDimension,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textWidget,
                  if (widget.showMessage) messageWidget,
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// When the list direction is horizontally.
  Widget _buildHorizontalWidget() {
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      width: _axis == Axis.vertical ? double.infinity : _offset,
      height: _axis == Axis.horizontal ? double.infinity : _offset,
      child: _axis == Axis.vertical
          ? _buildVerticalWidget()
          : _buildHorizontalWidget(),
    );
  }
}