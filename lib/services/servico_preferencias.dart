// lib/services/servico_preferencias.dart

import 'dart:ui'; // Necessário para acessar o idioma do sistema
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/provedor_tema.dart'; 

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

  // --- IDIOMA (COM DETECÇÃO AUTOMÁTICA) ---
  Future<void> salvarLingua(String codigo) async {
    await _prefs.setString('idioma', codigo);
  }

  String carregarLingua() {
    // 1. Tenta carregar a escolha manual do usuário
    final salvo = _prefs.getString('idioma');
    if (salvo != null) return salvo;

    // 2. Se não houver escolha salva, pega o idioma do sistema
    // PlatformDispatcher.instance.locale.languageCode retorna 'pt', 'en', etc.
    final idiomaSistema = PlatformDispatcher.instance.locale.languageCode;

    // 3. Verifica se suportamos esse idioma
    const suportados = ['pt', 'en', 'es'];
    if (suportados.contains(idiomaSistema)) {
      return idiomaSistema;
    }

    // 4. Fallback: Se o celular estiver em Alemão/Japonês, usa Português
    return 'pt';
  }

  // --- ONBOARDING ---
  Future<void> salvarOnboardingCompleto() async {
    await _prefs.setBool('onboarding_visto', true);
  }

  bool carregarStatusOnboarding() {
    return _prefs.getBool('onboarding_visto') ?? false;
  }

  // --- PERSISTÊNCIA DE NAVEGAÇÃO ---
  Future<void> salvarUltimaAba(int index, String tipoUsuario) async {
    await _prefs.setInt('ultima_aba_$tipoUsuario', index);
  }

  int carregarUltimaAba(String tipoUsuario) {
    return _prefs.getInt('ultima_aba_$tipoUsuario') ?? 0;
  }
}