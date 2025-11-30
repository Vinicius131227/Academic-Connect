import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ServicoTTS {
  final FlutterTts _flutterTts = FlutterTts();

  ServicoTTS() {
    _flutterTts.setLanguage("pt-BR");
    _flutterTts.setSpeechRate(0.5);
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }
}

final provedorTTS = Provider<ServicoTTS>((ref) => ServicoTTS());
// Alias para compatibilidade com código anterior
final ttsProvider = provedorTTS;