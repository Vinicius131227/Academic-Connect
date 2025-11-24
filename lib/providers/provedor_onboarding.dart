import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../servico_preferencias.dart';

class OnboardingNotifier extends StateNotifier<bool> {
  final ServicoPreferencias _prefs;
  
  OnboardingNotifier(this._prefs) : super(_prefs.carregarStatusOnboarding());

  /// Esta função é chamada quando o usuário clica em "Começar"
  Future<void> completeOnboarding() async {
    await _prefs.salvarOnboardingCompleto();
    state = false; // Define que o onboarding foi concluído
  }
}

final provedorOnboarding = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final prefs = ref.watch(provedorPreferencias); 
  return OnboardingNotifier(prefs);
});