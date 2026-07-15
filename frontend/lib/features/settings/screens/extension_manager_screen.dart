import 'package:flutter/material.dart';
import 'package:frontend/core/colors/app_colors.dart';
import 'package:frontend/core/radius/app_radius.dart';
import 'package:frontend/features/player/data/registry/plugin_registry.dart';
import 'package:frontend/features/player/models/plugin_meta.dart';
import 'package:frontend/service_locator.dart';

class ExtensionManagerScreen extends StatefulWidget {
  const ExtensionManagerScreen({super.key});

  @override
  State<ExtensionManagerScreen> createState() => _ExtensionManagerScreenState();
}

class _ExtensionManagerScreenState extends State<ExtensionManagerScreen> {
  final TextEditingController _repoController = TextEditingController();
  late final PluginRegistry _registry;

  List<PluginMeta> _installedPlugins = [];

  @override
  void initState() {
    super.initState();
    _registry = locator<PluginRegistry>();
    _loadPlugins();
  }

  void _loadPlugins() {
    setState(() {
      _installedPlugins = _registry.getInstalledPlugins();
    });
  }

  Future<void> _handleToggle(String pluginName, bool isActive) async {
    await _registry.togglePlugin(pluginName, isActive);
    // Trigger a rebuild to reflect the new visual state
    setState(() {});
  }

  @override
  void dispose() {
    _repoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0F),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "Extension Settings",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSectionHeader("Extensions"),
          _buildSettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "List of URLs to load sources from. While extensions are sandboxed, it is not recommended to add untrusted extensions.",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: TextField(
                          controller: _repoController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Enter extension URL...",
                            hintStyle: TextStyle(color: Colors.white30),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: () {
                          // Phase 3: URL Fetching logic goes here
                        },
                        child: const Text(
                          "Add",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "yugen-official-scrapers",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      InkWell(
                        onTap: () {},
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader("Sources"),
          const Padding(
            padding: EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              "List of sources to discover media from.",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),

          // Dynamic rendering of installed plugins
          ..._installedPlugins.map((plugin) {
            final isActive = _registry.isPluginActive(plugin.id);
            final isTorrent =
                plugin.name.toLowerCase().contains('nyaa') ||
                plugin.name.toLowerCase().contains('torrent');

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildSourceToggle(
                title: plugin.name,
                description: isTorrent
                    ? "A BitTorrent community focused on Eastern Asian media. Provides high accuracy searches."
                    : "Standard HTTP scraper for direct mp4 and HLS streams. Fast and reliable.",
                badgeText: isTorrent ? "P2P" : "HTTP",
                badgeColor: isTorrent ? Colors.green : AppColors.primary,
                isActive: isActive,
                onChanged: (val) => _handleToggle(plugin.id, val),
              ),
            );
          }),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: child,
    );
  }

  Widget _buildSourceToggle({
    required String title,
    required String description,
    required String badgeText,
    required bool isActive,
    required ValueChanged<bool> onChanged,
    Color badgeColor = AppColors.primary,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isActive ? "Status: Active" : "Status: Disabled",
                style: TextStyle(
                  color: isActive ? Colors.white70 : Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(
                height: 24,
                child: Switch(
                  value: isActive,
                  onChanged: onChanged,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.primary,
                  inactiveThumbColor: Colors.white54,
                  inactiveTrackColor: Colors.black26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
