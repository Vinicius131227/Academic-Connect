import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/turma_professor.dart';
import '../models/disciplina_frequencia.dart';
import '../l10n/app_localizations.dart';
import '../providers/provedor_autenticacao.dart';
import '../services/servico_firestore.dart';
import '../telas/aluno/tela_notas_avaliacoes.dart';
import '../telas/aluno/tela_detalhes_disciplina_aluno.dart'; // Hub da disciplina
import '../themes/app_theme.dart'; // Cores novas

// Provider local para ouvir as aulas dessa turma específica
final aulasStreamProvider = StreamProvider.family<QuerySnapshot, String>((ref, turmaId) {
  final servico = ref.watch(servicoFirestoreProvider);
  return servico.getAulasStream(turmaId);
});

class CardFrequencia extends ConsumerWidget {
  final TurmaProfessor turma;
  
  const CardFrequencia({required this.turma, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final alunoUid = ref.watch(provedorNotificadorAutenticacao).usuario?.uid;
    
    // Escuta as aulas em tempo real para calcular falta/presença
    final asyncAulas = ref.watch(aulasStreamProvider(turma.id));

    return asyncAulas.when(
      loading: () => Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e,s) => Text('Erro: $e', style: const TextStyle(color: Colors.red)),
      data: (querySnapshot) {
        
        // --- CÁLCULO DA FREQUÊNCIA ---
        // A lógica aqui considera:
        // Total de aulas = Número de documentos na coleção 'aulas'
        // Presença = Se o ID do aluno está no array 'inicio' OU 'fim'
        
        int totalAulas = querySnapshot.docs.length;
        int presencas = 0;
        
        if (alunoUid != null) {
          for (final doc in querySnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final presentesInicio = List<String>.from(data['presentes_inicio'] ?? []);
            final presentesFim = List<String>.from(data['presentes_fim'] ?? []);
            
            // Se o aluno marcou presença no início OU no fim, conta como presente na aula
            if (presentesInicio.contains(alunoUid) || presentesFim.contains(alunoUid)) {
              presencas++;
            }
          }
        }
        
        int faltas = totalAulas - presencas;
        double porcentagem = (totalAulas == 0) ? 100.0 : (presencas / totalAulas) * 100;
        
        // Define a cor da barra (Verde se > 75%, Vermelho se < 75%)
        final bool aprovado = porcentagem >= 75.0;
        final Color corStatus = aprovado ? AppColors.success : AppColors.error;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface, // Cinza escuro do tema
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho: Nome e Porcentagem
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          turma.nome, 
                          style: GoogleFonts.poppins(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${t.t('aluno_disciplinas_faltas')}: $faltas • Total: $totalAulas',
                          style: GoogleFonts.poppins(
                            fontSize: 12, 
                            color: AppColors.textGrey
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: corStatus.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${porcentagem.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: corStatus, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Barra de Progresso
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: porcentagem / 100,
                  backgroundColor: Colors.black26,
                  color: corStatus,
                  minHeight: 8,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Botões de Ação
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.analytics_outlined, size: 18),
                      label: const Text('Notas'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TelaNotasAvaliacoes(disciplinaInicial: turma.nome),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text('Acessar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        // Vai para o HUB (Chat, Materiais, Dicas)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TelaDetalhesDisciplinaAluno(turma: turma),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }
}