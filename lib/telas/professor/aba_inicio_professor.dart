// lib/telas/professor/aba_inicio_professor.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Para datas
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/turma_professor.dart';
import '../../l10n/app_localizations.dart'; // Traduções
import '../../providers/provedor_autenticacao.dart';
import '../../providers/provedores_app.dart';
import '../comum/widget_carregamento.dart'; // Loading
import '../../themes/app_theme.dart'; // Cores
import '../comum/animacao_fadein_lista.dart'; // Animação de entrada

// Telas de navegação
import 'tela_criar_turma.dart';
import 'tela_detalhes_disciplina_prof.dart'; // Hub da disciplina

/// Caso de uso para o Widgetbook.
/// Simula a tela inicial do professor.
@UseCase(
  name: 'Home Professor',
  type: AbaInicioProfessor,
)
Widget buildAbaInicioProfessor(BuildContext context) {
  return ProviderScope(
    child: AbaInicioProfessor(
      onNavigateToTab: (index) {}, // Mock da navegação
    ),
  );
}

/// Aba Inicial do Professor (Dashboard).
///
/// Funcionalidades:
/// 1. Exibe saudação e resumo estatístico (Total de turmas/alunos).
/// 2. Acesso rápido para Criar Turma, Ver Histórico, etc.
/// 3. Lista automática das aulas agendadas para o dia atual ("Hoje").
class AbaInicioProfessor extends ConsumerWidget {
  /// Callback para navegar entre as abas da `TelaPrincipalProfessor` (0, 1, 2).
  final ValueSetter<int> onNavigateToTab;

  const AbaInicioProfessor({
    super.key, 
    required this.onNavigateToTab
  });

  /// Retorna a abreviação do dia da semana atual (ex: 'seg', 'ter')
  /// para filtrar as aulas do dia.
  String _getDiaSemanaAtual() {
    final int weekday = DateTime.now().weekday;
    switch (weekday) {
      case DateTime.monday: return 'seg';
      case DateTime.tuesday: return 'ter';
      case DateTime.wednesday: return 'qua';
      case DateTime.thursday: return 'qui';
      case DateTime.friday: return 'sex';
      case DateTime.saturday: return 'sab';
      case DateTime.sunday: return 'dom';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    // Obtém dados do usuário e das turmas via Riverpod
    final nomeProf = ref.watch(provedorNotificadorAutenticacao).usuario?.alunoInfo?.nomeCompleto.split(' ')[0] ?? 'Professor';
    final asyncTurmas = ref.watch(provedorStreamTurmasProfessor);

    // Configurações de Tema Dinâmico
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    
    // Cores dos elementos
    final cardBgColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.black12;

    // Lista de widgets para animação de entrada (FadeIn)
    final widgets = [
       // 1. CABEÇALHO
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text("👨‍🏫 ", style: TextStyle(fontSize: 24)),
                  Text(
                    "${t.t('inicio_ola')}, $nomeProf", // "Olá, [Nome]"
                    style: GoogleFonts.poppins(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: textColor
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                t.t('prof_resumo'), // "Gerencie suas turmas..."
                style: GoogleFonts.poppins(fontSize: 14, color: subTextColor),
              ),
            ],
          ),
          // Ícone decorativo
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cardBgColor, 
              shape: BoxShape.circle,
              border: Border.all(color: borderColor)
            ),
            child: Icon(Icons.school, color: textColor),
          ),
        ],
      ),

      const SizedBox(height: 24),

      // 2. CARD DE STATUS (Estatísticas Gerais)
      asyncTurmas.when(
        data: (turmas) {
          // Calcula total de alunos somando os inscritos de todas as turmas
          final totalAlunos = turmas.fold(0, (sum, t) => sum + t.alunosInscritos.length);
          
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              // Gradiente Roxo (Identidade Visual)
              gradient: const LinearGradient(
                colors: [Color(0xFF7B1FA2), Color(0xFFBA68C8)], 
                begin: Alignment.topLeft, end: Alignment.bottomRight
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem(
                  icon: Icons.class_, 
                  value: turmas.length.toString(), 
                  label: t.t('prof_turmas_titulo') // "Turmas"
                ),
                Container(width: 1, height: 40, color: Colors.white30), // Separador
                _buildStatusItem(
                  icon: Icons.people, 
                  value: totalAlunos.toString(), 
                  label: t.t('prof_ver_alunos') // "Alunos"
                ),
              ],
            ),
          );
        },
        loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
        error: (_,__) => const SizedBox.shrink(),
      ),

      const SizedBox(height: 32),

      // 3. ATALHOS RÁPIDOS (Grid de Ações)
      Text(
        t.t('inicio_acesso_rapido'), // "Acesso Rápido"
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)
      ),
      const SizedBox(height: 16),
      
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botão Criar Turma
          Expanded(child: _buildCategoryItem(
            context, 
            icon: Icons.add_circle_outline, 
            label: t.t('criar_turma_titulo'), 
            color: const Color(0xFFE3F2FD), 
            iconColor: Colors.blue, 
            textColor: subTextColor, 
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaCriarTurma()))
          )),
          const SizedBox(width: 8),
          
          // Botão Minhas Turmas (Navega para Tab 1)
          Expanded(child: _buildCategoryItem(
            context, 
            icon: Icons.list_alt, 
            label: t.t('prof_turmas_titulo'), 
            color: const Color(0xFFE8F5E9), 
            iconColor: Colors.green, 
            textColor: subTextColor, 
            onTap: () => onNavigateToTab(1)
          )), 
          const SizedBox(width: 8),
          
          // Botão Histórico (Navega para Tab 1, pois precisa selecionar turma)
          Expanded(child: _buildCategoryItem(
            context, 
            icon: Icons.history, 
            label: t.t('prof_historico'), 
            color: const Color(0xFFFFF3E0), 
            iconColor: Colors.orange, 
            textColor: subTextColor, 
            onTap: () => onNavigateToTab(1)
          )), 
          const SizedBox(width: 8),
          
          // Botão Perfil (Navega para Tab 2)
          Expanded(child: _buildCategoryItem(
            context, 
            icon: Icons.person, 
            label: t.t('perfil_titulo'), 
            color: const Color(0xFFF3E5F5), 
            iconColor: Colors.purple, 
            textColor: subTextColor, 
            onTap: () => onNavigateToTab(2)
          )), 
        ],
      ),

      const SizedBox(height: 32),

      // 4. AULAS DE HOJE (Lista Dinâmica)
      Text(
        t.t('prof_aulas_hoje'), // "Aulas de Hoje"
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)
      ),
      const SizedBox(height: 16),

      asyncTurmas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,s) => const SizedBox.shrink(),
        data: (turmas) {
          final diaAtual = _getDiaSemanaAtual();
          
          // Filtra as turmas que possuem o dia da semana atual na string de horário
          // Ex: "Seg 08:00" contém "seg"
          final aulasHoje = turmas.where((turma) => turma.horario.toLowerCase().contains(diaAtual)).toList();
          
          // Se não houver aulas hoje, mostra aviso amigável
          if (aulasHoje.isEmpty) {
             return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor)
              ),
              child: Column(
                children: [
                  Icon(Icons.event_available, size: 40, color: subTextColor),
                  const SizedBox(height: 8),
                  Text(t.t('prof_sem_aulas'), style: TextStyle(color: subTextColor)), // "Nenhuma aula hoje."
                ],
              ),
            );
          }
          
          // Lista de cartões das aulas
          return Column(
            children: aulasHoje.map((turma) => _buildClassCard(context, turma, isDark, textColor, subTextColor, cardBgColor, borderColor)).toList(),
          );
        },
      ),
      
      // Espaço extra para o final da rolagem
      const SizedBox(height: 80),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Usa animação de entrada para suavidade
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: FadeInListAnimation(children: widgets),
      ),
    );
  }

  /// Constrói um item de estatística (Ícone + Número + Rótulo).
  Widget _buildStatusItem({required IconData icon, required String value, required String label}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  /// Constrói um botão quadrado de acesso rápido.
  Widget _buildCategoryItem(BuildContext context, {
      required IconData icon, 
      required String label, 
      required Color color, 
      required Color iconColor, 
      required Color textColor, 
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 55, width: 55,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: GoogleFonts.poppins(color: textColor, fontSize: 11, fontWeight: FontWeight.w500), 
            textAlign: TextAlign.center, 
            maxLines: 2, 
            overflow: TextOverflow.ellipsis
          ),
        ],
      ),
    );
  }

  /// Constrói o cartão detalhado de uma aula de hoje.
  Widget _buildClassCard(BuildContext context, TurmaProfessor turma, bool isDark, Color? textColor, Color subTextColor, Color cardBg, Color borderColor) {
    // Tenta extrair a hora de início para exibir em destaque
    String hora = "";
    try {
       // Formato esperado: "Seg 08:00-10:00"
       hora = turma.horario.split(' ')[1].split('-')[0];
    } catch (e) {
       hora = "Hoje";
    }
    
    return GestureDetector(
      onTap: () {
         // Abre o Hub da Disciplina
         Navigator.push(context, MaterialPageRoute(builder: (_) => TelaDetalhesDisciplinaProf(turma: turma)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border(
            left: const BorderSide(color: AppColors.primaryPurple, width: 4), // Borda lateral roxa
            top: BorderSide(color: borderColor),
            right: BorderSide(color: borderColor),
            bottom: BorderSide(color: borderColor),
          ),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Coluna da Hora
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hora, style: GoogleFonts.poppins(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 18)),
                Text("Início", style: GoogleFonts.poppins(color: subTextColor, fontSize: 10)),
              ],
            ),
            const SizedBox(width: 16),
            // Divisor Vertical
            Container(height: 40, width: 1, color: borderColor == Colors.transparent ? Colors.white10 : Colors.black12),
            const SizedBox(width: 16),
            // Detalhes da Turma
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(turma.nome, style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(turma.local, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            // Seta
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}