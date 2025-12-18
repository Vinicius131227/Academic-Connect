import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'provedor_localizacao.dart';

class ServicoTTS {
  final FlutterTts _flutterTts = FlutterTts();
  
  // Variável para guardar o código atual (padrão pt-BR)
  String _currentTtsCode = 'pt-BR'; 

  ServicoTTS() {
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setPitch(1.0);
    _flutterTts.awaitSpeakCompletion(true);
  }

  /// Define qual idioma DEVE ser usado (apenas guarda a intenção e tenta configurar)
  Future<void> setLanguage(Locale locale) async {
    String ttsCode;
    switch (locale.languageCode) {
      case 'pt':
        ttsCode = 'pt-BR';
        break;
      case 'es':
        ttsCode = 'es-ES';
        break;
      case 'en':
        ttsCode = 'en-US';
        break;
      default:
        ttsCode = 'pt-BR';
    }

    // 1. Atualiza a variável local
    _currentTtsCode = ttsCode;

    // 2. Tenta configurar imediatamente (mas não confiamos só nisso)
    await _flutterTts.setLanguage(_currentTtsCode);
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      // 3. Garante a linguagem logo antes de falar.
      await _flutterTts.setLanguage(_currentTtsCode);
      
      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}

final provedorTTS = Provider<ServicoTTS>((ref) {
  final servico = ServicoTTS();
  final localeAtual = ref.watch(provedorLocalizacao);
  
  // Chama a configuração, mas agora o método speak() é quem garante a execução
  servico.setLanguage(localeAtual);

  return servico;
});

final ttsProvider = provedorTTS;