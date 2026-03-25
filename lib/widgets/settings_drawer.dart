import 'package:flutter/material.dart';
import '../utils/unit_converter.dart';
import '../models/wind_band.dart';
import '../screens/admin_reports_screen.dart';
import '../screens/about_screen.dart';
import '../screens/disclaimer_screen.dart';

class SettingsDrawer extends StatelessWidget {
  final VoidCallback onWeatherModelChanged;
  const SettingsDrawer({super.key, required this.onWeatherModelChanged});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 120,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Color(0xFF1E88E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.only(left: 20, bottom: 20),
            alignment: Alignment.bottomLeft,
            child: const Text(
              'SETTINGS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _buildDrawerSection('UNITS'),
          _buildUnitTile(
            context,
            icon: Icons.speed,
            title: 'Wind Speed',
            listenable: UnitSettings.selectedUnit,
            options: SpeedUnit.values.map((v) => v.name.toUpperCase()).toList(),
            onChanged: (idx) =>
                UnitSettings.selectedUnit.value = SpeedUnit.values[idx],
            currentIdx: UnitSettings.selectedUnit.value.index,
          ),
          _buildUnitTile(
            context,
            icon: Icons.straighten,
            title: 'Distance',
            listenable: UnitSettings.selectedDistanceUnit,
            options: ['KM', 'MILES'],
            onChanged: (idx) => UnitSettings.selectedDistanceUnit.value =
                DistanceUnit.values[idx],
            currentIdx: UnitSettings.selectedDistanceUnit.value.index,
          ),
          _buildUnitTile(
            context,
            icon: Icons.height,
            title: 'Height',
            listenable: UnitSettings.selectedHeightUnit,
            options: ['METERS', 'FEET'],
            onChanged: (idx) =>
                UnitSettings.selectedHeightUnit.value = HeightUnit.values[idx],
            currentIdx: UnitSettings.selectedHeightUnit.value.index,
          ),
          _buildUnitTile(
            context,
            icon: Icons.compress,
            title: 'Pressure',
            listenable: UnitSettings.selectedPressureUnit,
            options: ['HPA', 'MBAR'],
            onChanged: (idx) => UnitSettings.selectedPressureUnit.value =
                PressureUnit.values[idx],
            currentIdx: UnitSettings.selectedPressureUnit.value.index,
          ),
          Divider(color: Theme.of(context).dividerColor, height: 32),
          _buildDrawerSection('SYSTEM'),
          _buildUnitTile(
            context,
            icon: Icons.brightness_medium,
            title: 'Theme',
            listenable: ThemeSettings.selectedTheme,
            options: ['AUTO', 'LIGHT', 'DARK'],
            onChanged: (idx) =>
                ThemeSettings.selectedTheme.value = ThemeMode.values[idx],
            currentIdx: ThemeSettings.selectedTheme.value.index,
          ),
          ListTile(
            leading: const Icon(Icons.cloud_queue, color: Colors.blueAccent),
            title: Text(
              'Weather Model',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            subtitle: ValueListenableBuilder<WeatherModel>(
              valueListenable: WeatherSettings.selectedModel,
              builder: (context, m, _) => Text(
                m.displayName,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () => _showModelPicker(context),
          ),
          ListTile(
            leading: const Icon(Icons.gavel, color: Colors.orangeAccent),
            title: Text(
              'Disclaimer',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const DisclaimerScreen()),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            title: Text(
              'About',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const AboutScreen()),
            ),
          ),
          Divider(color: Theme.of(context).dividerColor, height: 32),
          _buildDrawerSection('DEVELOPMENT'),
          ListTile(
            leading: const Icon(Icons.bug_report, color: Colors.purpleAccent),
            title: Text(
              'Admin / Debug Reports',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => AdminReportsScreen()),
            ),
          ),
          Divider(color: Theme.of(context).dividerColor, height: 32),
          _buildDrawerSection('WIND BANDS'),
          ValueListenableBuilder<List<WindBand>>(
            valueListenable: WindBandSettings.currentBands,
            builder: (context, bands, _) {
              return Column(
                children: [
                  ...bands.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final band = entry.value;
                    return ListTile(
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: band.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        band.label,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${band.min.toStringAsFixed(0)} - ${band.max.toStringAsFixed(0)} ${UnitSettings.unitString}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _showBandDialog(
                              context,
                              band: band,
                              index: idx,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              final newBands = List<WindBand>.from(bands)
                                ..removeAt(idx);
                              WindBandSettings.saveBands(newBands);
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  ListTile(
                    leading: const Icon(Icons.add, color: Colors.blueAccent),
                    title: const Text(
                      'Add Extra Band',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => _showBandDialog(context),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Builder(
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.blueAccent.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnitTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required ValueNotifier listenable,
    required List<String> options,
    required Function(int) onChanged,
    required int currentIdx,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).textTheme.bodyMedium?.color,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 15,
        ),
      ),
      trailing: ValueListenableBuilder(
        valueListenable: listenable,
        builder: (context, _, _) {
          return DropdownButton<int>(
            value: currentIdx,
            dropdownColor: Theme.of(context).colorScheme.surface,
            underline: const SizedBox(),
            items: List.generate(
              options.length,
              (i) => DropdownMenuItem(
                value: i,
                child: Text(
                  options[i],
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            onChanged: (val) => val != null ? onChanged(val) : null,
          );
        },
      ),
    );
  }

  void _showModelPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Select Model',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: ValueListenableBuilder<WeatherModel>(
          valueListenable: WeatherSettings.selectedModel,
          builder: (context, currentModel, _) {
            return RadioGroup<WeatherModel>(
              groupValue: currentModel,
              onChanged: (val) {
                if (val != null) {
                  WeatherSettings.selectedModel.value = val;
                  onWeatherModelChanged();
                  Navigator.pop(context);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: WeatherModel.values.map((m) {
                  return RadioListTile<WeatherModel>(
                    title: Text(
                      m.displayName,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 14,
                      ),
                    ),
                    value: m,
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showBandDialog(BuildContext context, {WindBand? band, int? index}) {
    final isEditing = band != null;
    final labelController = TextEditingController(text: band?.label ?? '');
    double min = band?.min ?? 0;
    double max = band?.max ?? 10;
    Color color = band?.color ?? Colors.blueAccent;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            isEditing ? 'Edit Wind Band' : 'Add Wind Band',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label (e.g. Prime)',
                  ),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Min Speed: ${min.round()} ${UnitSettings.unitString}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                Slider(
                  value: min,
                  min: 0,
                  max: 50,
                  onChanged: (v) => setState(() => min = v),
                ),
                Text(
                  'Max Speed: ${max.round()} ${UnitSettings.unitString}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                Slider(
                  value: max,
                  min: 0,
                  max: 100,
                  onChanged: (v) => setState(() => max = v),
                ),
                const SizedBox(height: 10),
                const Text('Color'),
                Wrap(
                  spacing: 8,
                  children:
                      [
                            Colors.redAccent,
                            Colors.orangeAccent,
                            Colors.amber,
                            Colors.greenAccent,
                            Colors.blueAccent,
                            Colors.teal,
                            Colors.purpleAccent,
                          ]
                          .map(
                            (c) => GestureDetector(
                              onTap: () => setState(() => color = c),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: color == c
                                      ? Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newBand = WindBand(
                  min: min,
                  max: max,
                  label: labelController.text,
                  color: color,
                );
                final bands = List<WindBand>.from(
                  WindBandSettings.currentBands.value,
                );
                if (isEditing && index != null) {
                  bands[index] = newBand;
                } else {
                  bands.add(newBand);
                }
                WindBandSettings.saveBands(bands);
                Navigator.pop(context);
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
