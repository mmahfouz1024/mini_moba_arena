class L10n {
  static const Map<String, (String ar, String en)> _strings = {
    'app_title': ('ساحة الأساطير', 'Legends Arena'),
    'app_subtitle': ('معارك MOBA سريعة', 'Mini MOBA 3v3'),
    'play_3v3': ('معركة الساحة 3 ضد 3', 'Play 3v3 Arena'),
    'play_3v3_desc': ('أبراج، موجات جنود، وزعيم النهر', 'Turrets, minion waves & River Boss'),
    'play_1v1': ('تحدي 1 ضد 1', '1v1 Skill Duel'),
    'play_1v1_desc': ('مواجهة مباشرة سريعة', 'Fast head-to-head lane duel'),
    'heroes_armory': ('الأبطال', 'Heroes'),
    'settings': ('الإعدادات', 'Settings'),
    'gold': ('ذهب', 'Gold'),
    'rank': ('التصنيف', 'Rank'),
    'wins': ('فوز', 'Wins'),
    'select_hero': ('اختر بطلك', 'Select Hero'),
    'selected': ('مختار', 'Selected'),
    'unlock': ('فتح البطل', 'Unlock'),
    'shop': ('المتجر', 'Shop'),
    'recall': ('عودة للقاعدة', 'Recall'),
    'heal_spell': ('شفاء', 'Heal'),
    'attack': ('هجوم', 'ATK'),
    'victory': ('انتصار عظيم!', 'VICTORY!'),
    'defeat': ('هزيمة', 'DEFEAT'),
    'play_again': ('معركة جديدة', 'Play Again'),
    'back_lobby': ('العودة للوبي', 'Lobby'),
    'respawn_in': ('العودة خلال', 'Respawn in'),
    'sound': ('المؤثرات الصوتية', 'Sound Effects'),
    'haptics': ('الاهتزاز', 'Haptics'),
    'language': ('اللغة (العربية / English)', 'Language (العربية / English)'),
    'privacy': ('سياسة الخصوصية', 'Privacy Policy'),
    'privacy_body': (
      'تحفظ اللعبة تقدمك وإحصائياتك محلياً على جهازك ولا تجمع أي بيانات شخصية.',
      'Legends Arena stores your progress locally on your device and collects no personal data.'
    ),
    'not_enough_gold': ('الذهب غير كافٍ!', 'Not enough Gold!'),
    'fighter': ('مقاتل', 'Fighter'),
    'mage': ('ساحرة', 'Mage'),
    'tank': ('مدافع (تانك)', 'Tank'),
    'marksman': ('رامية', 'Marksman'),
    'turret_destroyed': ('تم تدمير برج!', 'Turret Destroyed!'),
    'boss_slain': ('تم القضاء على زعيم النهر!', 'River Boss Slain!'),
    'controls_hint': ('اسحب عصا التحكم للتحرك • اضغط أو اسحب المهارات للتصويب', 'Joystick to move • Tap or drag skills to aim'),
  };

  static String tr(String key, bool isArabic) {
    final pair = _strings[key];
    if (pair == null) return key;
    return isArabic ? pair.$1 : pair.$2;
  }
}
