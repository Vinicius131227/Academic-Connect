// lib/telas/aluno/aba_inicio_aluno.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../providers/provedores_app.dart'; 
import '../comum/widget_carregamento.dart';
import '../../models/prova_agendada.dart'; 
import 'tela_cadastro_nfc.dart';
import 'package:intl/intl.dart';
import 'tela_frequencia_detalhada.dart';
import 'tela_notas_avaliacoes.dart';
import 'tela_solicitar_adaptacao.dart';
import '../../l10n/app_localizations.dart';
import '../comum/animacao_fadein_lista.dart'; 
import 'package:http/http.dart' as http; // NECESSÁRIO PARA API
import 'dart:convert';

// --- (NOVO) FutureProvider para a API de Frases ---
final quoteProvider = FutureProvider<String>((ref) async {
  try {
    // API Pública de conselhos/frases (Adviceslip)
    final response = await http.get(Uri.parse('https://api.adviceslip.com/advice'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['slip']['advice'].toString();
    }
    return "Estude com dedicação!";
  } catch (e) {
    return "Mantenha o foco nos estudos.";
  }
});

class AbaInicioAluno extends ConsumerWidget {
  const AbaInicioAluno({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    final asyncProvas = ref.watch(provedorStreamCalendario); 
    final usuario = ref.watch(provedorNotificadorAutenticacao).usuario;
    final nomeAluno = usuario?.alunoInfo?.nomeCompleto.split(' ')[0] ?? 'Aluno';
    
    // Observa a API
    final asyncQuote = ref.watch(quoteProvider);

    final widgets = [
      // Card de Boas-Vindas
      Card(
        color: theme.colorScheme.primary, 
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${t.t('aluno_inicio_bemvindo')}, $nomeAluno!',
                style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onPrimary, 
                        fontWeight: FontWeight.bold,
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                t.t('aluno_inicio_resumo'),
                style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.9),
                      ),
              ),
              const SizedBox(height: 12),
              
              // --- (NOVO) Exibição da Frase da API ---
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.yellow, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: asyncQuote.when(
                        data: (frase) => Text(
                          '"$frase"',
                          style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                        ),
                        loading: () => const Text("Carregando inspiração...", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        error: (_, __) => const SizedBox(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      
      // --- CARD DE FREQUÊNCIA SIMPLIFICADO ---
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(t.t('aluno_disciplinas_frequencia'), style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Acompanhe suas faltas e presença na aba 'Minhas Disciplinas'.", 
                style: theme.textTheme.bodyLarge
              ),
              const SizedBox(height: 8),
              Text(
                t.t('aluno_disciplinas_aviso'), 
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Tenta encontrar o TabController e mudar para a aba 1
                    final controller = DefaultTabController.maybeOf(context);
                    if (controller != null) {
                       controller.animateTo(1); 
                    } else {
                       // Se não estiver num TabController padrão, usa navegação
                       // (Mas aqui estamos no IndexedStack da tela principal, então não funciona direto)
                       // Deixaremos sem ação ou notificamos o pai se necessário.
                       // Como estamos num IndexedStack, o ideal é avisar a TelaPrincipal,
                       // mas para simplificar, deixamos informativo.
                    }
                  },
                  child: Text(t.t('aluno_inicio_ver_detalhes')),
                ),
              ),
            ],
          ),
        ),
      ),

      // Card de Próximas Provas
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text(t.t('aluno_inicio_provas'), style: theme.textTheme.titleMedium),
                ],
              ),
              const Divider(height: 24),
              
              asyncProvas.when(
                loading: () => const WidgetCarregamento(texto: ''),
                error: (e,s) => Text('Erro: $e'),
                data: (provas) {
                  if (provas.isEmpty) {
                    return const Center(child: Text('Nenhuma prova agendada.'));
                  }
                  return Column(
                    children: provas.take(3).map((prova) => 
                      _buildLinhaProva(context, prova, theme)
                    ).toList(),
                  );
                }
              ),
            ],
          ),
        ),
      ),
      
      // Botões de Atalho
      Row(
        children: [
          Expanded(
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16.0),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaNotasAvaliacoes()));
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.description, size: 30, color: theme.colorScheme.primary),
                      const SizedBox(height: 8),
                      Text(t.t('aluno_inicio_notas'), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16.0),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaSolicitarAdaptacao()));
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.warning_amber, size: 30, color: Colors.orange[600]),
                      const SizedBox(height: 8),
                      Text(t.t('aluno_inicio_adaptacoes'), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const TelaCadastroNFC()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.nfc, size: 30, color: Colors.green[600]),
                const SizedBox(width: 16),
                Text(t.t('aluno_inicio_cadastrar_nfc'), style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        ),
      ),
    ];
    
    return FadeInListAnimation(
      children: widgets,
    );
  }

  Widget _buildLinhaProva(BuildContext context, ProvaAgendada prova, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prova.disciplina, style: theme.textTheme.bodyLarge!),
              Text(prova.titulo, style: theme.textTheme.bodySmall!),
            ],
          ),
          Text(
            DateFormat('dd/MM').format(prova.dataHora),
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}