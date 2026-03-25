import 'package:flutter/material.dart';
import '../utils/unit_converter.dart';

class StatusHeader extends StatelessWidget {
  final DateTime? lastRefreshed;

  const StatusHeader({super.key, required this.lastRefreshed});

  @override
  Widget build(BuildContext context) {
    if (lastRefreshed == null) return const SizedBox.shrink();

    return ValueListenableBuilder<WeatherModel>(
      valueListenable: WeatherSettings.selectedModel,
      builder: (context, model, _) {
        final timeStr =
            "${lastRefreshed!.hour.toString().padLeft(2, '0')}:${lastRefreshed!.minute.toString().padLeft(2, '0')}";
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "MODEL: ${model.shortName}",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                "UPDATED: $timeStr",
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
