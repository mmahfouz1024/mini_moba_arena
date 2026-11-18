import 'package:flutter/material.dart';
import '../../models/moba_models.dart';
import '../../services/localization_service.dart';
import '../../services/sound_service.dart';

class HeroSelectScreen extends StatefulWidget {
  final PlayerMetaProfile profile;
  final Future<void> Function() onSave;

  const HeroSelectScreen({
    super.key,
    required this.profile,
    required this.onSave,
  });

  @override
  State<HeroSelectScreen> createState() => _HeroSelectScreenState();
}

class _HeroSelectScreenState extends State<HeroSelectScreen> {
  String _roleLabel(HeroRole role, bool isAr) {
    switch (role) {
      case HeroRole.fighter:
        return L10n.tr('fighter', isAr);
      case HeroRole.mage:
        return L10n.tr('mage', isAr);
      case HeroRole.tank:
        return L10n.tr('tank', isAr);
      case HeroRole.marksman:
        return L10n.tr('marksman', isAr);
    }
  }

  Future<void> _selectOrUnlock(HeroDef hero) async {
    final isAr = widget.profile.isArabic;
    final unlocked = widget.profile.unlockedHeroIds.contains(hero.id);

    if (unlocked) {
      SoundService.instance.playEffect('click.wav');
      setState(() => widget.profile.selectedHeroId = hero.id);
      await widget.onSave();
      return;
    }

    if (widget.profile.accountGold < hero.unlockCostGold) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.tr('not_enough_gold', isAr)),
          backgroundColor: const Color(0xFFBE123C),
        ),
      );
      return;
    }

    SoundService.instance.playEffect('levelup.wav');
    setState(() {
      widget.profile.accountGold -= hero.unlockCostGold;
      widget.profile.unlockedHeroIds.add(hero.id);
      widget.profile.selectedHeroId = hero.id;
    });
    await widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.profile.isArabic;
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF131A2D),
          foregroundColor: Colors.white,
          title: Text(L10n.tr('heroes_armory', isAr)),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Color(0xFFFACC15), size: 20),
                  const SizedBox(width: 5),
                  Text('${widget.profile.accountGold}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: HeroCatalog.heroes.length,
          itemBuilder: (context, index) {
            final hero = HeroCatalog.heroes[index];
            final unlocked = widget.profile.unlockedHeroIds.contains(hero.id);
            final selected = widget.profile.selectedHeroId == hero.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF131A2D),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? const Color(0xFFFACC15) : hero.primaryColor.withValues(alpha: 0.45),
                  width: selected ? 2.4 : 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? const Color(0xFFFACC15) : hero.primaryColor,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            hero.portraitAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => CircleAvatar(
                              backgroundColor: hero.primaryColor,
                              child: Text(
                                (isAr ? hero.nameAr : hero.nameEn).substring(0, 1),
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${isAr ? hero.nameAr : hero.nameEn} • ${isAr ? hero.titleAr : hero.titleEn}',
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${_roleLabel(hero.role, isAr)} | HP ${hero.maxHp.toInt()} | ATK ${hero.attackDamage.toInt()}',
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _selectOrUnlock(hero),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selected
                              ? const Color(0xFFF59E0B)
                              : (unlocked ? hero.primaryColor : const Color(0xFF10B981)),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          selected
                              ? L10n.tr('selected', isAr)
                              : (unlocked ? L10n.tr('select_hero', isAr) : '${L10n.tr('unlock', isAr)} (${hero.unlockCostGold})'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: hero.skills.map((s) {
                      return Chip(
                        backgroundColor: s.color.withValues(alpha: 0.16),
                        side: BorderSide(color: s.color.withValues(alpha: 0.5)),
                        label: Text(
                          isAr ? s.nameAr : s.nameEn,
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
