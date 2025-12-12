import 'package:flutter/material.dart';
import 'pt.dart';
import 'en.dart';
import 'es.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('pt', ''),
    Locale('en', ''),
    Locale('es', ''),
  ];
  
  // Getters para Listas
  List<String> get universidades => ['UFSCar - Campus Sorocaba'];
  
  List<String> get cursos {
    if (locale.languageCode == 'en') {
      return [
        'Business Administration', 'Biological Sciences', 'Computer Science',
        'Economics', 'Production Engineering', 'Forest Engineering',
        'Physics', 'Geography', 'Mathematics', 'Pedagogy', 'Chemistry', 'Tourism'
      ];
    } else if (locale.languageCode == 'es') {
      return [
        'Administración', 'Ciencias Biológicas', 'Ciencias de la Computación',
        'Ciencias Económicas', 'Ingeniería de Producción', 'Ingeniería Forestal',
        'Física', 'Geografía', 'Matemáticas', 'Pedagogía', 'Química', 'Turismo'
      ];
    }
    return [
      'Administração', 'Ciências Biológicas', 'Ciência da Computação',
      'Ciências Econômicas', 'Engenharia de Produção', 'Engenharia Florestal',
      'Física', 'Geografia', 'Matemática', 'Pedagogia', 'Química', 'Turismo'
    ];
  }
  
  List<String> get predios {
    return ['ATLab', 'AT2', 'CCHB', 'CCTS', 'CCGT', 'FINEP 1', 'FINEP 2'];
  }
  
  List<String> get identificacaoProfessor {
    if (locale.languageCode == 'en') {
        return ['SIAPE ID', 'Teacher Registry', 'External ID'];
    } else if (locale.languageCode == 'es') {
        return ['Matrícula SIAPE', 'Registro Docente', 'ID Externo'];
    }
    return ['Matrícula SIAPE', 'Registro Docente', 'ID Externo'];
  }
  
  // Mapa de Traduções
  static const Map<String, Map<String, String>> _valores = {
    'pt': pt,
    'en': en,
    'es': es,
  };

  String t(String key, {List<String>? args}) {
    String? value = _valores[locale.languageCode]?[key];
    
    if (value == null) {
      // Fallback
      if (locale.languageCode.contains('_')) {
        value = _valores[locale.languageCode.split('_')[0]]?[key];
      }
    }

    if (value == null) return key; 

    if (args != null) {
      for (int i = 0; i < args.length; i++) {
        value = value!.replaceFirst('{}', args[i]);
      }
    }
    return value!;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['pt', 'en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}