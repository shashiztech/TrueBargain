import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<SettingsProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Settings')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () async {
                  await provider.save();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings saved')),
                    );
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Region
              _buildSectionHeader('Region'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: provider.selectedCountry,
                        decoration:
                            const InputDecoration(labelText: 'Country'),
                        items: provider.countries.map((c) {
                          return DropdownMenuItem(
                            value: c.countryCode,
                            child: Text(
                                '${c.countryName} (${c.currencySymbol})'),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) provider.setCountry(v);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Features
              _buildSectionHeader('Features'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Web Scraping'),
                      subtitle: const Text(
                          'Scrape product data from websites'),
                      value: provider.enableWebScraping,
                      onChanged: provider.setEnableWebScraping,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Public APIs'),
                      subtitle: const Text(
                          'Use public search engine APIs'),
                      value: provider.enablePublicApis,
                      onChanged: provider.setEnablePublicApis,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Local Stores'),
                      subtitle: const Text(
                          'Search nearby physical stores'),
                      value: provider.enableLocalStores,
                      onChanged: provider.setEnableLocalStores,
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Price Alerts'),
                      subtitle: const Text(
                          'Get notified on price drops'),
                      value: provider.enablePriceAlerts,
                      onChanged: provider.setEnablePriceAlerts,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // API Key Management
              _buildSectionHeader('API Key Management'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configure API keys for real product data. '
                        'Keys are stored securely on your device.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ..._buildApiKeyFields(provider),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // About
              _buildSectionHeader('About'),
              Card(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('True Bargain'),
                      subtitle: Text('Version 1.0.0'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore),
                      title: const Text('Reset to Defaults'),
                      onTap: () => _confirmReset(provider),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  List<Widget> _buildApiKeyFields(SettingsProvider provider) {
    final keys = [
      ('TB_RAPIDAPI_KEY', 'RapidAPI Key (rapidapi.com)'),
      ('TB_AMAZON_API_KEY', 'Amazon API Key'),
      ('TB_FLIPKART_API_KEY', 'Flipkart API Key'),
      ('TB_WALMART_API_KEY', 'Walmart API Key'),
      ('TB_BESTBUY_API_KEY', 'Best Buy API Key'),
      ('TB_EBAY_API_KEY', 'eBay API Key'),
    ];

    return keys.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _ApiKeyField(
          label: entry.$2,
          keyName: entry.$1,
          provider: provider,
        ),
      );
    }).toList();
  }

  void _confirmReset(SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Settings?'),
        content: const Text('This will restore all default settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.resetDefaults();
              Navigator.pop(ctx);
            },
            child:
                const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ApiKeyField extends StatefulWidget {
  final String label;
  final String keyName;
  final SettingsProvider provider;

  const _ApiKeyField({
    required this.label,
    required this.keyName,
    required this.provider,
  });

  @override
  State<_ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends State<_ApiKeyField> {
  final _controller = TextEditingController();
  bool _isObscured = true;
  bool _hasValue = false;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final value = await widget.provider.readApiKey(widget.keyName);
    if (value != null && value.isNotEmpty) {
      _controller.text = value;
      setState(() => _hasValue = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      obscureText: _isObscured,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isObscured = !_isObscured),
            ),
            IconButton(
              icon: Icon(
                _hasValue ? Icons.check_circle : Icons.save,
                color: _hasValue ? Colors.green : null,
              ),
              onPressed: () async {
                await widget.provider
                    .saveApiKey(widget.keyName, _controller.text);
                setState(() => _hasValue = true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${widget.label} saved')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
