import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll2;
import '../models/site.dart';
import '../models/weather_data.dart';
import '../services/weather_api.dart';
import '../utils/unit_converter.dart';

class LiveWindScreen extends StatefulWidget {
  final Site site;
  const LiveWindScreen({super.key, required this.site});
  @override
  State<LiveWindScreen> createState() => _LiveWindScreenState();
}

class _LiveWindScreenState extends State<LiveWindScreen> {
  final WeatherApi _weatherApi = WeatherApi();
  WeatherData? _currentWeather;
  bool _isLoading = true;
  Timer? _refreshTimer;
  String _errorMessage = '';
  @override
  void initState() {
    super.initState();
    _fetchData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchData(isBackground: true);
    });
    WeatherSettings.selectedModel.addListener(_fetchData);
  }

  @override
  void dispose() {
    WeatherSettings.selectedModel.removeListener(_fetchData);
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({bool isBackground = false}) async {
    if (!isBackground) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }
    try {
      final forecast = await _weatherApi.fetchForecast(widget.site);
      if (forecast.isNotEmpty) {
        if (mounted) {
          setState(() {
            _currentWeather = forecast.first;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to update wind data: $e';
          if (!isBackground) _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final arrowColor = isDark ? Colors.blue[300]! : Colors.indigo[900]!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.site.name} Live Wind'),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: ValueListenableBuilder<WeatherModel>(
                valueListenable: WeatherSettings.selectedModel,
                builder: (context, model, _) => Text(
                  model.displayName,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty && _currentWeather == null
          ? Center(child: Text(_errorMessage))
          : Stack(
              children: [
                _buildMapBackground(),
                if (_currentWeather != null)
                  WindAnimationOverlay(
                    windSpeed: _currentWeather!.windSpeed,
                    windDirection: _currentWeather!.windDirection,
                    color: arrowColor,
                  ),
                _buildContent(isDark),
              ],
            ),
    );
  }

  Widget _buildMapBackground() {
    return FlutterMap(
      options: MapOptions(
        initialCenter: ll2.LatLng(widget.site.latitude, widget.site.longitude),
        initialZoom: 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.alienexbit.parawind',
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark) {
    if (_currentWeather == null) return const SizedBox.shrink();
    final windSpeed = _currentWeather!.windSpeed;
    final windDirection = _currentWeather!.windDirection;
    final gradientColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    return ValueListenableBuilder<SpeedUnit>(
      valueListenable: UnitSettings.selectedUnit,
      builder: (context, unit, _) {
        final convertedSpeed = UnitSettings.convertKmh(windSpeed);
        final unitStr = UnitSettings.unitString;
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  gradientColor.withValues(alpha: 0.6),
                  Colors.transparent,
                  gradientColor.withValues(alpha: 0.6),
                ],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildDirectionCompass(
                    windDirection,
                    convertedSpeed,
                    unitStr,
                    textColor,
                  ),
                  const SizedBox(height: 40),
                  _buildRefreshIndication(textColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDirectionCompass(
    double direction,
    double speed,
    String unit,
    Color textColor,
  ) {
    return Column(
      children: [
        SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(250, 250),
                painter: CompassPainter(
                  optimalRanges: widget.site.optimalWindDirections,
                  color: textColor,
                ),
              ),
              Transform.rotate(
                angle: (direction - 180) * (math.pi / 180),
                child: const Icon(
                  Icons.navigation,
                  size: 80,
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          UnitSettings.degreesToCompass(direction),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          'DIRECTION',
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            color: textColor.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${speed.toStringAsFixed(1)} $unit',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshIndication(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(
          'Auto-refreshing every 30s...',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class CompassPainter extends CustomPainter {
  final List<WindDirectionRange> optimalRanges;
  final Color color;
  CompassPainter({required this.optimalRanges, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 10.0;
    // Outer circle
    final trackPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius - strokeWidth / 2, trackPaint);
    // Optimal Infills
    final optimalPaint = Paint()
      ..color = Colors.deepPurple.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (var range in optimalRanges) {
      double startAngle = (range.min - 90) * (math.pi / 180);
      double sweepAngle = (range.max - range.min);
      if (sweepAngle < 0) sweepAngle += 360; // handle wrap
      sweepAngle = sweepAngle * (math.pi / 180);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        optimalPaint,
      );
    }
    // Cardinals (N, E, S, W)
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    final textStyle = TextStyle(
      color: color.withValues(alpha: 0.5),
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
    void drawLabel(String text, double angleDeg) {
      textPainter.text = TextSpan(text: text, style: textStyle);
      textPainter.layout();
      final rad = (angleDeg - 90) * (math.pi / 180);
      final offsetRadius = radius - strokeWidth - 15;
      final x =
          center.dx + offsetRadius * math.cos(rad) - textPainter.width / 2;
      final y =
          center.dy + offsetRadius * math.sin(rad) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(x, y));
    }

    drawLabel('N', 0);
    drawLabel('E', 90);
    drawLabel('S', 180);
    drawLabel('W', 270);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WindAnimationOverlay extends StatefulWidget {
  final double windSpeed;
  final double windDirection;
  final Color color;
  const WindAnimationOverlay({
    super.key,
    required this.windSpeed,
    required this.windDirection,
    required this.color,
  });
  @override
  State<WindAnimationOverlay> createState() => _WindAnimationOverlayState();
}

class _WindAnimationOverlayState extends State<WindAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<WindParticle> _particles = [];
  final math.Random _random = math.Random();
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    for (int i = 0; i < 30; i++) {
      _particles.add(WindParticle(_random));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: WindArrowPainter(
            particles: _particles,
            windSpeed: widget.windSpeed,
            windDirection: widget.windDirection,
            progress: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class WindParticle {
  double x;
  double y;
  double opacity;
  double size;
  WindParticle(math.Random rand)
    : x = rand.nextDouble(),
      y = rand.nextDouble(),
      opacity =
          rand.nextDouble() * 0.5 +
          0.4, // Increased base opacity for darker arrows
      size = rand.nextDouble() * 10 + 10;
  void update(double speedKmh, double direction, double dt) {
    // direction is 'from', so particles blow to 'direction + 180'
    // Math angle = Compass - 90. So rad = (direction + 180 - 90) = direction + 90
    final rad = (direction + 90) * (math.pi / 180);
    // Convert km/h to mph for thresholds
    final speedMph = speedKmh / 1.60934;
    double animationSpeed;
    if (speedMph <= 5.0) {
      animationSpeed = 0.15; // slow
    } else if (speedMph <= 10.0) {
      animationSpeed = 0.3; // medium slow
    } else if (speedMph <= 15.0) {
      animationSpeed = 0.5; // medium
    } else {
      animationSpeed = 0.8; // medium fast
    }
    final vx = math.cos(rad) * animationSpeed;
    final vy = math.sin(rad) * animationSpeed;
    x += vx * dt;
    y += vy * dt;
    if (x < -0.1) x = 1.1;
    if (x > 1.1) x = -0.1;
    if (y < -0.1) y = 1.1;
    if (y > 1.1) y = -0.1;
  }
}

class WindArrowPainter extends CustomPainter {
  final List<WindParticle> particles;
  final double windSpeed;
  final double windDirection;
  final double progress;
  final Color color;
  WindArrowPainter({
    required this.particles,
    required this.windSpeed,
    required this.windDirection,
    required this.progress,
    required this.color,
  });
  @override
  void paint(Canvas canvas, Size size) {
    final arrowPath = Path();
    arrowPath.moveTo(0, 0);
    arrowPath.lineTo(-10, -5);
    arrowPath.moveTo(0, 0);
    arrowPath.lineTo(-10, 5);
    arrowPath.moveTo(0, 0);
    arrowPath.lineTo(-20, 0);
    // direction is 'from', so arrows point to 'direction + 180'
    // Math angle = Compass - 90. So rad = (direction + 180 - 90) = direction + 90
    final rad = (windDirection + 90) * (math.pi / 180);
    for (var p in particles) {
      p.update(windSpeed, windDirection, 0.016);
      canvas.save();
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(rad);
      final pPaint = Paint()
        ..color = color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(arrowPath, pPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(WindArrowPainter oldDelegate) => true;
}
