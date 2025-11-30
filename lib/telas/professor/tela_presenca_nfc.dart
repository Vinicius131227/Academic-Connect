// lib/telas/professor/tela_presenca_nfc.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../models/turma_professor.dart';
import '../../l10n/app_localizations.dart'; // Traduções
import '../../themes/app_theme.dart'; // Cores
import '../../providers/provedor_professor.dart'; // Lógica NFC

/// Caso de uso para o Widgetbook.
/// Simula a tela de chamada NFC para uma turma.
@UseCase(
  name: 'Chamada NFC',
  type: TelaPresencaNFC,
)
Widget buildTelaPresencaNFC(BuildContext context) {
  return ProviderScope(
    child: TelaPresencaNFC(
      turma: TurmaProfessor(
        id: 'mock', nome: 'Cálculo 1', horario: '', local: '', professorId: '', turmaCode: '', creditos: 4, alunosInscritos: []
      ),
    ),
  );
}

/// Tela de Chamada Automática via NFC.
/// 
/// Funcionalidades:
/// - Animação de radar enquanto escaneia.
/// - Feedback visual e sonoro ao ler um cartão.
/// - Lista em tempo real dos alunos presentes.
/// - Botão para finalizar e salvar a chamada (Início ou Fim).
class TelaPresencaNFC extends ConsumerStatefulWidget {
  final TurmaProfessor turma;
  const TelaPresencaNFC({super.key, required this.turma});

  @override
  ConsumerState<TelaPresencaNFC> createState() => _TelaPresencaNFCState();
}

class _TelaPresencaNFCState extends ConsumerState<TelaPresencaNFC> with SingleTickerProviderStateMixin {
  // Controlador para a animação de pulso (radar)
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Configura a animação de "respiração" do ícone
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    // Observa o estado do leitor NFC
    final estadoNFC = ref.watch(provedorPresencaNFC);
    final notifierNFC = ref.read(provedorPresencaNFC.notifier);
    
    // Configuração de Tema
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t.t('prof_presenca_nfc_titulo'), // "Registrar Presença (NFC)"
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor)
        ),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
        actions: [
          // Botão de Cancelar/Parar (só aparece se estiver lendo)
          if (estadoNFC.status == StatusNFC.lendo)
            TextButton(
              onPressed: () => notifierNFC.pausarLeitura(),
              child: Text(
                t.t('nfc_cadastro_cancelar').toUpperCase(), 
                style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)
              ),
            )
        ],
      ),
      body: Column(
        children: [
          // --- ÁREA DE STATUS E ESCANEAMENTO (RADAR) ---
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (estadoNFC.status == StatusNFC.lendo) ...[
                    // Animação de pulso
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryPurple.withOpacity(0.1),
                          border: Border.all(color: AppColors.primaryPurple, width: 2),
                        ),
                        child: const Icon(Icons.nfc, size: 60, color: AppColors.primaryPurple),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      t.t('nfc_cadastro_aguardando'), // "Aguardando cartão..."
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.t('nfc_cadastro_instrucao'), 
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)
                    ),
                  ] else ...[
                    // Estado Parado/Inicial
                    Icon(Icons.nfc, size: 80, color: isDark ? Colors.white24 : Colors.black12),
                    const SizedBox(height: 24),
                    Text(
                      t.t('prof_presenca_nfc_pausada_titulo'), // "Leitura Pausada"
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => notifierNFC.iniciarLeitura(widget.turma.id),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(t.t('nfc_cadastro_iniciar')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],

                  // Mensagem de Erro ou Sucesso temporária
                  if (estadoNFC.ultimoErroScan != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(estadoNFC.ultimoErroScan!, style: const TextStyle(color: AppColors.error)),
                    ),
                ],
              ),
            ),
          ),

          // --- LISTA DE ALUNOS REGISTRADOS ---
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho da lista
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.t('prof_presenca_registrados'), // "Alunos Registrados"
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primaryPurple, borderRadius: BorderRadius.circular(12)),
                        child: Text("${estadoNFC.presentes.length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Lista de cartões
                  Expanded(
                    child: estadoNFC.presentes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.list_alt, size: 48, color: isDark ? Colors.white10 : Colors.black12),
                                const SizedBox(height: 8),
                                Text(t.t('prof_presenca_nfc_vazio'), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: estadoNFC.presentes.length,
                            itemBuilder: (context, index) {
                              // Inverte a lista para mostrar os mais recentes no topo
                              final aluno = estadoNFC.presentes.reversed.toList()[index];
                              return Card(
                                color: cardColor,
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: AppColors.cardGreen,
                                    child: Icon(Icons.check, color: Colors.white, size: 16),
                                  ),
                                  title: Text(aluno.nome, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                                  trailing: Text(aluno.hora, style: const TextStyle(color: Colors.grey)),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // --- BOTÃO SALVAR (Finalizar Chamada) ---
          if (estadoNFC.presentes.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: ElevatedButton.icon(
                onPressed: () => _salvarPresenca(context, ref, estadoNFC.presentes),
                icon: const Icon(Icons.save),
                label: Text(t.t('prof_chamada_manual_salvar')), // "Salvar Chamada"
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Abre diálogo para escolher o tipo de chamada (Início/Fim) e salva no banco.
  Future<void> _salvarPresenca(BuildContext context, WidgetRef ref, List<AlunoPresenteNFC> presentes) async {
    final t = AppLocalizations.of(context)!;
    
    // Pergunta se é inicio ou fim da aula
    final tipoChamada = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.t('prof_chamada_tipo_titulo')), // "Tipo de Chamada"
        content: Text(t.t('prof_chamada_tipo_desc')), // "Início ou Fim?"
        actions: [
          TextButton(child: Text(t.t('prof_chamada_tipo_inicio')), onPressed: () => Navigator.pop(ctx, 'inicio')),
          ElevatedButton(child: Text(t.t('prof_chamada_tipo_fim')), onPressed: () => Navigator.pop(ctx, 'fim')),
        ],
      ),
    );

    if (tipoChamada == null) return;

    try {
      // Chama o provider para persistir os dados
      await ref.read(provedorPresencaNFC.notifier).salvarChamadaNFC(
        widget.turma.id, 
        tipoChamada, 
        DateTime.now()
      );
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.t('ca_presenca_salva_sucesso')), backgroundColor: Colors.green));
         Navigator.pop(context); // Fecha a tela
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    }
  }
}