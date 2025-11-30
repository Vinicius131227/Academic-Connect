// lib/services/servico_preferencias.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/provedor_tema.dart'; // Importa o enum ModoSistemaTema

/// Provedor global para acessar o serviço de preferências.
///
/// Inicialmente, ele lança um erro [UnimplementedError] porque precisa ser
/// inicializado assincronamente no [main.dart] antes de ser usado.
/// Lá, usamos `overrideWithValue` para injetar a instância pronta.
final provedorPreferencias = Provider<ServicoPreferencias>((ref) {
  throw UnimplementedError(); 
});

/// Serviço responsável por persistir configurações do usuário no dispositivo.
/// Utiliza o pacote [shared_preferences] para salvar dados simples (chave-valor).
class ServicoPreferencias {
  late SharedPreferences _prefs;

  /// Inicializa o serviço carregando as preferências do disco.
  /// Deve ser chamado no `main()` antes do `runApp`.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ===========================================================================
  // SEÇÃO: TEMA (Claro / Escuro / Sistema)
  // ===========================================================================

  /// Salva a escolha do tema (Claro, Escuro ou Sistema) no disco.
  Future<void> salvarTema(ModoSistemaTema tema) async {
    await _prefs.setString('tema', tema.name);
  }

  /// Carrega o tema salvo.
  /// Se não houver nada salvo, retorna [ModoSistemaTema.sistema] como padrão.
  ModoSistemaTema carregarTema() {
    final nome = _prefs.getString('tema');
    if (nome == null) return ModoSistemaTema.sistema;
    
    // Converte a String salva de volta para o Enum
    return ModoSistemaTema.values.firstWhere(
      (e) => e.name == nome, 
      orElse: () => ModoSistemaTema.sistema
    );
  }

  // ===========================================================================
  // SEÇÃO: IDIOMA (Internacionalização)
  // ===========================================================================

  /// Salva o código do idioma escolhido (ex: 'pt', 'en', 'es').
  Future<void> salvarLingua(String codigo) async {
    await _prefs.setString('idioma', codigo);
  }

  /// Carrega o idioma salvo.
  /// Se não houver, retorna 'pt' (Português) como padrão.
  String carregarLingua() {
    return _prefs.getString('idioma') ?? 'pt';
  }

  // ===========================================================================
  // SEÇÃO: ONBOARDING (Boas-vindas)
  // ===========================================================================

  /// Marca que o usuário já completou o tutorial inicial (Onboarding).
  Future<void> salvarOnboardingCompleto() async {
    await _prefs.setBool('onboarding_visto', true);
  }

  /// Verifica se o usuário já viu o Onboarding.
  /// Retorna `false` se for a primeira vez que o app é aberto.
  bool carregarStatusOnboarding() {
    return _prefs.getBool('onboarding_visto') ?? false;
  }

  // ===========================================================================
  // SEÇÃO: NAVEGAÇÃO (Estado da Aba)
  // ===========================================================================

  /// Salva o índice da última aba visitada na BottomNavigationBar.
  /// Útil para quando o usuário fecha e reabre o app, ele voltar onde estava.
  ///
  /// [index]: O índice da aba (0, 1, 2...).
  /// [tipoUsuario]: Chave para diferenciar abas de Aluno, Professor, etc.
  Future<void> salvarUltimaAba(int index, String tipoUsuario) async {
    await _prefs.setInt('ultima_aba_$tipoUsuario', index);
  }

  /// Carrega a última aba visitada. Retorna 0 (Início) se não houver registro.
  int carregarUltimaAba(String tipoUsuario) {
    return _prefs.getInt('ultima_aba_$tipoUsuario') ?? 0;
  }
}