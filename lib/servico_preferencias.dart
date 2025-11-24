// lib/servico_preferencias.dart
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <-- Importe adicionado
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/provedor_tema.dart'; // Necessário para o enum ModoSistemaTema

// O provedor é definido aqui, mas seu valor real é injetado no main.dart
final provedorPreferencias = Provider<ServicoPreferencias>((ref) {
  throw UnimplementedError(); 
});

class ServicoPreferencias {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- TEMA ---
  Future<void> salvarTema(ModoSistemaTema tema) async {
    await _prefs.setString('tema', tema.name);
  }

  ModoSistemaTema carregarTema() {
    final nome = _prefs.getString('tema');
    if (nome == null) return ModoSistemaTema.sistema;
    return ModoSistemaTema.values.firstWhere(
      (e) => e.name == nome, 
      orElse: () => ModoSistemaTema.sistema
    );
  }

  // --- IDIOMA ---
  Future<void> salvarLingua(String codigo) async {
    await _prefs.setString('idioma', codigo);
  }

  String carregarLingua() {
    return _prefs.getString('idioma') ?? 'pt';
  }

  // --- ONBOARDING ---
  Future<void> salvarOnboardingCompleto() async {
    await _prefs.setBool('onboarding_visto', true);
  }

  bool carregarStatusOnboarding() {
    return _prefs.getBool('onboarding_visto') ?? false;
  }

  // --- PERSISTÊNCIA DE NAVEGAÇÃO (Última Aba) ---
  Future<void> salvarUltimaAba(int index, String tipoUsuario) async {
    await _prefs.setInt('ultima_aba_$tipoUsuario', index);
  }

  int carregarUltimaAba(String tipoUsuario) {
    return _prefs.getInt('ultima_aba_$tipoUsuario') ?? 0;
  }
}