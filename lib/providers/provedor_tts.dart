import 'package:flutter/material.dart'; // Para Locale
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Importe o provedor de localização para saber qual língua está selecionada
import 'provedor_localizacao.dart'; 

class ServicoTTS {
  final FlutterTts _flutterTts = FlutterTts();

  ServicoTTS() {
    _flutterTts.setSpeechRate(0.5);
    // Configurações padrão de áudio (opcional)
    _flutterTts.setPitch(1.0);
    
    // Tenta aguardar a conclusão da fala antes de começar outra (evita sobreposição)
    _flutterTts.awaitSpeakCompletion(true);
  }

  /// Atualiza o idioma do motor de voz
  Future<void> setLanguage(Locale locale) async {
    // O TTS geralmente precisa do código de país (pt-BR, en-US, es-ES)
    // O nosso App usa apenas 'pt', 'en', 'es', então fazemos um mapa:
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

    await _flutterTts.setLanguage(ttsCode);
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }
  
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}

/// Provedor que observa a mudança de idioma e atualiza o TTS automaticamente
final provedorTTS = Provider<ServicoTTS>((ref) {
  final servico = ServicoTTS();

  // 1. Observa o idioma atual do app
  final localeAtual = ref.watch(provedorLocalizacao);

  // 2. Atualiza a língua do TTS imediatamente
  servico.setLanguage(localeAtual);

  return servico;
});

// Alias para compatibilidade
final ttsProvider = provedorTTS;