import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_moba_arena/engine/moba_arena_engine.dart';
import 'package:mini_moba_arena/main.dart';
import 'package:mini_moba_arena/models/moba_models.dart';

void main() {
  group('MobaArenaEngine', () {
    test('initializes 3v3 teams and turrets properly', () {
      final engine = MobaArenaEngine(
        mode: ArenaMode.arena3v3,
        playerHeroDef: HeroCatalog.heroes.first,
        rng: Random(1),
      );
      expect(engine.heroes.where((h) => h.team == Team.blue).length, 3);
      expect(engine.heroes.where((h) => h.team == Team.red).length, 3);
      expect(engine.turrets.length, 6);
      expect(engine.bosses.length, 2);
    });

    test('basic attack and skills deal damage and trigger cooldowns', () {
      final engine = MobaArenaEngine(
        mode: ArenaMode.duel1v1,
        playerHeroDef: HeroCatalog.byId('kael'),
        rng: Random(2),
      );
      final enemy = engine.heroes.firstWhere((h) => h.team == Team.red);
      enemy.pos = Vec2(engine.player.pos.x + 50, engine.player.pos.y);
      final initialHp = enemy.hp;

      engine.performBasicAttack(engine.player);
      expect(enemy.hp, lessThan(initialHp));
      expect(engine.player.basicCooldown, greaterThan(0));

      final afterBasic = enemy.hp;
      engine.castSkill(engine.player, 1); // Whirlwind Edge AoE
      expect(enemy.hp, lessThan(afterBasic));
      expect(engine.player.skillCooldowns[1], greaterThan(0));
    });

    test('buying shop item increases stats and deducts gold', () {
      final engine = MobaArenaEngine(
        mode: ArenaMode.duel1v1,
        playerHeroDef: HeroCatalog.byId('lyra'),
      );
      engine.player.gold = 500;
      final baseAtk = engine.player.attackDamage;

      final bought = engine.buyShopItem(engine.player, 'crimson_blade');
      expect(bought, isTrue);
      expect(engine.player.attackDamage, greaterThan(baseAtk));
      expect(engine.player.gold, 500 - 280);
    });

    test('spawns minion waves and declares winner when red nexus falls', () {
      final engine = MobaArenaEngine(
        mode: ArenaMode.duel1v1,
        playerHeroDef: HeroCatalog.heroes.first,
      );
      for (var i = 0; i < 60; i++) {
        engine.update(0.05);
      }
      expect(engine.minions.isNotEmpty, isTrue);

      final redNexus = engine.turrets.firstWhere((t) => t.uid == 'red_nexus');
      redNexus.hp = 0;
      engine.update(0.016);
      expect(engine.winner, Team.blue);
    });
  });

  testWidgets('LegendsArenaApp renders lobby cleanly', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const LegendsArenaApp());
    await tester.pumpAndSettle();
    expect(find.text('ساحة الأساطير'), findsOneWidget);
  });
}
