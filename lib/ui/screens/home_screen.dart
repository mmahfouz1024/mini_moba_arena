import 'package:flutter/material.dart';
import '../../models/moba_models.dart';
import '../../services/localization_service.dart';
import '../../services/sound_service.dart';
import '../../services/storage_service.dart';
import 'arena_screen.dart';
import 'hero_select_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  PlayerMetaProfile _profile = PlayerMetaProfile();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await _storage.loadProfile();
    SoundService.instance.soundEnabled = loaded.soundEnabled;
    SoundService.instance.hapticsEnabled = loaded.hapticsEnabled;
    if (mounted) {
      setState(() {
        _profile = loaded;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    await _storage.saveProfile(_profile);
    if (mounted) setState(() {});
  }

  void _startMatch(ArenaMode mode) {
    SoundService.instance.playEffect('click.wav');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArenaScreen(
          profile: _profile,
          mode: mode,
          onSaveProfile: _save,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _openHeroes() {
    SoundService.instance.playEffect('click.wav');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HeroSelectScreen(
          profile: _profile,
          onSave: _save,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131A2D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isAr = _profile.isArabic;
          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    L10n.tr('settings', isAr),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SwitchListTile(
                    title: Text(L10n.tr('sound', isAr), style: const TextStyle(color: Colors.white)),
                    value: _profile.soundEnabled,
                    onChanged: (v) async {
                      _profile.soundEnabled = v;
                      SoundService.instance.soundEnabled = v;
                      await _save();
                      setSheetState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: Text(L10n.tr('haptics', isAr), style: const TextStyle(color: Colors.white)),
                    value: _profile.hapticsEnabled,
                    onChanged: (v) async {
                      _profile.hapticsEnabled = v;
                      SoundService.instance.hapticsEnabled = v;
                      await _save();
                      setSheetState(() {});
                    },
                  ),
                  SwitchListTile(
                    title: Text(L10n.tr('language', isAr), style: const TextStyle(color: Colors.white)),
                    subtitle: Text(isAr ? 'العربية' : 'English', style: const TextStyle(color: Colors.amber)),
                    value: _profile.isArabic,
                    onChanged: (v) async {
                      _profile.isArabic = v;
                      await _save();
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(L10n.tr('privacy', isAr), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    L10n.tr('privacy_body', isAr),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E1A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isAr = _profile.isArabic;
    final activeHero = HeroCatalog.byId(_profile.selectedHeroId);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatChip(icon: Icons.monetization_on, color: const Color(0xFFFACC15), text: '${_profile.accountGold}'),
                      _StatChip(icon: Icons.military_tech, color: const Color(0xFF38BDF8), text: _profile.rankName(isAr)),
                      _StatChip(icon: Icons.emoji_events, color: const Color(0xFF10B981), text: '${_profile.wins}W'),
                      IconButton(
                        onPressed: _showSettings,
                        icon: const Icon(Icons.settings, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [activeHero.primaryColor.withValues(alpha: 0.45), const Color(0xFF131A2D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: activeHero.primaryColor,
                          child: Text(
                            (isAr ? activeHero.nameAr : activeHero.nameEn).substring(0, 1),
                            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                L10n.tr('app_title', isAr),
                                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                              ),
                              Text(
                                '${L10n.tr('selected', isAr)}: ${isAr ? activeHero.nameAr : activeHero.nameEn} (${isAr ? activeHero.titleAr : activeHero.titleEn})',
                                style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _LobbyButton(
                    title: L10n.tr('play_3v3', isAr),
                    subtitle: L10n.tr('play_3v3_desc', isAr),
                    icon: Icons.sports_esports,
                    colors: const [Color(0xFFE11D48), Color(0xFF9F1239)],
                    onTap: () => _startMatch(ArenaMode.arena3v3),
                  ),
                  const SizedBox(height: 12),
                  _LobbyButton(
                    title: L10n.tr('play_1v1', isAr),
                    subtitle: L10n.tr('play_1v1_desc', isAr),
                    icon: Icons.flash_on,
                    colors: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    onTap: () => _startMatch(ArenaMode.duel1v1),
                  ),
                  const SizedBox(height: 12),
                  _LobbyButton(
                    title: L10n.tr('heroes_armory', isAr),
                    subtitle: '${_profile.unlockedHeroIds.length}/${HeroCatalog.heroes.length}',
                    icon: Icons.groups,
                    colors: const [Color(0xFFF59E0B), Color(0xFFB45309)],
                    onTap: _openHeroes,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    L10n.tr('controls_hint', isAr),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _StatChip({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF131A2D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _LobbyButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _LobbyButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
