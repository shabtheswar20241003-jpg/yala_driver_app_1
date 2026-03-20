import 'package:flutter/material.dart';
import 'app_translations.dart';

class LanguageProvider extends ChangeNotifier {
  String _lang = 'en';

  String get lang => _lang;

  void changeLanguage(String langCode) {
    _lang = langCode;
    AppTranslations.currentLang = langCode;
    notifyListeners();
  }
}
