class AppTranslations {
  static Map<String, Map<String, String>> translations = {
    'en': {
      'login': 'Login',
      'username': 'Username',
      'password': 'Password',
      'driver_dashboard': 'Driver Dashboard',
      'jeep_id': 'Jeep ID',
      'assigned_block': 'Assigned Block',
      'open_live_map': 'Open Live Map',
      'report_incident': 'Report Incident',
    },
    'si': {
      'login': 'පිවිසෙන්න',
      'username': 'පරිශීලක නාමය',
      'password': 'මුරපදය',
      'driver_dashboard': 'රියදුරු පුවරුව',
      'jeep_id': 'ජීප් අංකය',
      'assigned_block': 'අනුමත බ්ලොක්',
      'open_live_map': 'සජීවී සිතියම',
      'report_incident': 'සිද්ධිය වාර්තා කරන්න',
    },
    'ta': {
      'login': 'உள்நுழை',
      'username': 'பயனர் பெயர்',
      'password': 'கடவுச்சொல்',
      'driver_dashboard': 'ஓட்டுனர் பலகை',
      'jeep_id': 'ஜீப் ஐடி',
      'assigned_block': 'ஒத்துக்கொள்ளப்பட்ட பகுதி',
      'open_live_map': 'நேரடி வரைபடம்',
      'report_incident': 'சம்பவம் அறிக்கை',
    },
  };

  static String currentLang = 'en';

  static String t(String key) {
    return translations[currentLang]?[key] ?? key;
  }
}
