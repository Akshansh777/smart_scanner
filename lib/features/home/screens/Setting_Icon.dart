import 'package:flutter/material.dart';

class SettingsIcon extends StatefulWidget {
  const SettingsIcon({super.key});

  @override
  State<SettingsIcon> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsIcon> {
  ThemeMode selectedTheme = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 25),

          // Fixed Profile Image
          const Center(
            child: CircleAvatar(
              radius: 55,
              backgroundImage: AssetImage(
                'assets/image/hutao.jpeg',
              ),
            ),
          ),

          const SizedBox(height: 15),

          Center(
            child: Text(
              'My Profile',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 35),

          // Appearance Section
          Text(
            'Appearance',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: Icon(
                selectedTheme == ThemeMode.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              title: const Text('Theme Mode'),
              subtitle: Text(
                selectedTheme == ThemeMode.dark
                    ? 'Dark Mode'
                    : selectedTheme == ThemeMode.light
                        ? 'Light Mode'
                        : 'System Default',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showThemeOptions,
            ),
          ),

          const SizedBox(height: 25),

          // About Section
          Text(
            'About',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: const ListTile(
              leading: Icon(Icons.document_scanner_outlined),
              title: Text('AI Document Scanner'),
              subtitle: Text('Scan, extract text and summarize documents'),
            ),
          ),

          const SizedBox(height: 25),

          Center(
            child: Text(
              'AI Document Scanner',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeOptions() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Choose Theme',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _themeTile(
                sheetContext,
                'Light Mode',
                Icons.light_mode,
                ThemeMode.light,
              ),
              _themeTile(
                sheetContext,
                'Dark Mode',
                Icons.dark_mode,
                ThemeMode.dark,
              ),
              _themeTile(
                sheetContext,
                'System Default',
                Icons.settings_brightness,
                ThemeMode.system,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _themeTile(
    BuildContext sheetContext,
    String title,
    IconData icon,
    ThemeMode mode,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: selectedTheme == mode
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : null,
      onTap: () {
        setState(() {
          selectedTheme = mode;
        });

        Navigator.pop(sheetContext);
      },
    );
  }
}

//'assets/image/hutao.jpeg',
