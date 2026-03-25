import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.paragliding, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 24),
            const Text(
              'Paragliding Weather',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Author: Steve Watkins', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              'Version 1.0',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
