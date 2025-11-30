// lib/telas/ca_projeto/aba_eventos_ca.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart'; // IMPORT ADICIONADO

// Importações de provedores e modelos
import '../../providers/provedores_app.dart';
import '../../models/evento_ca.dart';

// Importações de UI e Temas
import '../comum/widget_carregamento.dart';
import 'tela_presenca_evento.dart';
import 'tela_criar_evento.dart';
import '../../l10n/app_localizations.dart';
import '../comum/animacao_fadein_lista.dart';
import '../../themes/app_theme.dart';

/// Caso de uso do Widgetbook para visualizar a lista de eventos.
@UseCase(
  name: 'Lista de Eventos CA',
  type: AbaEventosCA,
)
Widget buildAbaEventosCA(BuildContext context) {
  return const ProviderScope(
    child: AbaEventosCA(),
  );
}

/// Aba que exibe a lista de eventos gerenciados pelo Centro Acadêmico (C.A.).
class AbaEventosCA extends ConsumerWidget {
  const AbaEventosCA({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    // Observa o stream de eventos do Firebase
    final asyncEventos = ref.watch(provedorStreamEventosCA);

    // Tema atual para cores consistentes
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      
      body: asyncEventos.when(
        loading: () => const WidgetCarregamento(texto: "Carregando eventos..."),
        error: (err, st) => Center(
          child: Text(
            '${t.t('erro_generico')}: $err', 
            style: TextStyle(color: textColor)
          )
        ),
        data: (eventos) {
          if (eventos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    t.t('ca_sem_eventos'), // "Nenhum evento agendado"
                    style: TextStyle(color: textColor?.withOpacity(0.7)),
                  ),
                ],
              ),
            );
          }

          // Cria a lista de cards com animação de entrada
          final widgets = eventos.map((evento) => _buildCardEvento(context, t, evento)).toList();
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: FadeInListAnimation(children: widgets),
          );
        },
      ),
      
      // Botão para adicionar novo evento
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TelaCriarEvento()),
          );
        },
        backgroundColor: AppColors.primaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Constrói o cartão individual de cada evento.
  Widget _buildCardEvento(BuildContext context, AppLocalizations t, EventoCA evento) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade300;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 8, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título do Evento
            Text(
              evento.nome, 
              style: GoogleFonts.poppins(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: theme.textTheme.bodyLarge?.color
              )
            ),
            const SizedBox(height: 12),
            
            // Detalhes (Data, Local, Participantes)
            _buildInfoLinha(
              context, 
              Icons.calendar_today_outlined, 
              DateFormat('dd/MM/yyyy \'às\' HH:mm').format(evento.data)
            ),
            _buildInfoLinha(
              context, 
              Icons.location_on_outlined, 
              evento.local
            ),
            _buildInfoLinha(
              context, 
              Icons.group_outlined, 
              '${evento.totalParticipantes} ${t.t('ca_participantes')}'
            ),
            
            const Divider(height: 24),
            
            // Botão de Ação (Iniciar Registro de Presença)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.nfc, size: 18),
                label: Text(t.t('ca_eventos_iniciar_registro')), 
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TelaPresencaEvento(evento: evento)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Helper para criar linhas de informação com ícone e texto.
  Widget _buildInfoLinha(BuildContext context, IconData icone, String texto) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icone, size: 16, color: theme.textTheme.bodySmall?.color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto, 
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8)
              )
            ),
          ),
        ],
      ),
    );
  }
}