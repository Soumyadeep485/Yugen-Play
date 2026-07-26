import 'package:flutter/material.dart';

import '../../../../core/colors/app_colors.dart';
import '../../../../service_locator.dart';
import '../../../player/services/plugin_registry.dart';

class ExtensionManagerScreen extends StatefulWidget {
  const ExtensionManagerScreen({super.key});

  @override
  State<ExtensionManagerScreen> createState() => _ExtensionManagerScreenState();
}

class _ExtensionManagerScreenState extends State<ExtensionManagerScreen> {
  late final PluginRegistry _pluginRegistry;

  @override
  void initState() {
    super.initState();
    _pluginRegistry = locator<PluginRegistry>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Extension Manager")),
      body: Center(
        child: Text(
          "Installed Extensions: ${_pluginRegistry.plugins.length}",
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
