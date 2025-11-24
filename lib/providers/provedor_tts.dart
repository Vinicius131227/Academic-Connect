import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  late FlutterTts _flutterTts;

  TtsService() {
    _flutterTts = FlutterTts();
    // Configura o idioma para Português do Brasil
    _flutterTts.setLanguage("pt-BR");
    _flutterTts.setSpeechRate(0.5); // Velocidade da fala
    _flutterTts.setPitch(1.0); // Tom
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }
}

// O provedor que os outros provedores vão usar para falar
final ttsProvider = Provider<TtsService>((ref) {
  return TtsService();
});