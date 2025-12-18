// lib/telas/aluno/tela_calendario.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../providers/provedores_app.dart';
import '../../themes/app_theme.dart';
import '../../models/prova_agendada.dart';
import '../../models/turma_professor.dart';
import '../comum/widget_carregamento.dart';
import '../../l10n/app_localizations.dart';

@UseCase(
  name: 'Calendário Acadêmico',
  type: TelaCalendario,
)
Widget buildTelaCalendario(BuildContext context) {
  return const ProviderScope(
    child: TelaCalendario(),
  );
}

// =============================================================================
// 1. PROVEDORES LOCAIS E AUXILIARES
// =============================================================================

/// Modelo simples para feriado
class Feriado {
  final DateTime data;
  final String nome;
  Feriado({required this.data, required this.nome});

  factory Feriado.fromJson(Map<String, dynamic> json) {
    return Feriado(
      data: DateTime.parse(json['date']),
      nome: json['localName'],
    );
  }
}

/// Busca feriados na API externa
final feriadosProvider = FutureProvider<List<Feriado>>((ref) async {
  final ano = DateTime.now().year;
  try {
    final response = await http.get(Uri.parse('https://date.nager.at/api/v3/publicholidays/$ano/BR'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Feriado.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// PROVEDOR FILTRADO: 
/// Combina "Todas as Provas" com "Minhas Turmas"
final provedorCalendarioFiltrado = Provider.autoDispose<AsyncValue<List<ProvaAgendada>>>((ref) {
  // 1. Ouve todas as provas (que vêm do banco)
  final asyncTodasProvas = ref.watch(provedorStreamCalendario);
  
  // 2. Ouve as turmas do aluno (IMPORTANTE: Você deve ter esse stream em provedores_app.dart)
  // Se não tiver, substitua por ref.watch(provedorStreamTurmasAluno) ou similar.
  // Estou assumindo que o provedorStreamTurmasAluno retorna List<Turma>
  final asyncMinhasTurmas = ref.watch(provedorStreamTurmasAluno); 

  // Se algum estiver carregando, retorna carregando
  if (asyncTodasProvas.isLoading || asyncMinhasTurmas.isLoading) {
    return const AsyncLoading();
  }

  // Se der erro, repassa o erro
  if (asyncTodasProvas.hasError) return AsyncError(asyncTodasProvas.error!, asyncTodasProvas.stackTrace!);
  if (asyncMinhasTurmas.hasError) return AsyncError(asyncMinhasTurmas.error!, asyncMinhasTurmas.stackTrace!);

  final todasProvas = asyncTodasProvas.value ?? [];
  final minhasTurmas = asyncMinhasTurmas.value ?? [];

  // Extrai apenas os IDs das turmas que o aluno participa
  final idsMinhasTurmas = minhasTurmas.map((t) => t.id).toList();

  // 3. FILTRO MÁGICO: Só mantém provas cujo turmaId esteja na lista do aluno
  final provasFiltradas = todasProvas.where((p) => idsMinhasTurmas.contains(p.turmaId)).toList();

  return AsyncData(provasFiltradas);
});

// =============================================================================
// 2. TELA CALENDÁRIO
// =============================================================================

class TelaCalendario extends ConsumerStatefulWidget {
  const TelaCalendario({super.key});

  @override
  ConsumerState<TelaCalendario> createState() => _TelaCalendarioState();
}

class _TelaCalendarioState extends ConsumerState<TelaCalendario> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    // AGORA USAMOS O PROVEDOR FILTRADO, NÃO O GERAL
    final asyncProvas = ref.watch(provedorCalendarioFiltrado);
    final asyncFeriados = ref.watch(feriadosProvider);
    final t = AppLocalizations.of(context)!;
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final calendarBg = isDark ? AppColors.surfaceDark : Colors.white;
    final shadowColor = isDark ? Colors.transparent : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t.t('calendario_titulo_screen'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: asyncProvas.when(
        loading: () => const WidgetCarregamento(),
        error: (e, s) => Center(child: Text('${t.t('erro_generico')}: $e', style: TextStyle(color: textColor))),
        data: (provas) {
          return asyncFeriados.when(
            loading: () => const WidgetCarregamento(),
            // Se falhar a API de feriados, mostra o calendário só com provas (lista vazia de feriados)
            error: (_,__) => _buildCalendarContent(provas, [], textColor, calendarBg, cardColor, shadowColor),
            data: (feriados) => _buildCalendarContent(provas, feriados, textColor, calendarBg, cardColor, shadowColor),
          );
        },
      ),
    );
  }

  Widget _buildCalendarContent(List<ProvaAgendada> provas, List<Feriado> feriados, Color textColor, Color calendarBg, Color cardColor, Color shadowColor) {
    final t = AppLocalizations.of(context)!;
    
    // Combina eventos filtrados com feriados
    final eventosDoDia = [
      ...provas.where((p) => _isSameDay(p.dataHora, _selectedDay)),
      ...feriados.where((f) => _isSameDay(f.data, _selectedDay)),
    ];

    // Ordena por horário (opcional, mas bom)
    eventosDoDia.sort((a, b) {
       DateTime dataA = (a is ProvaAgendada) ? a.dataHora : (a as Feriado).data;
       DateTime dataB = (b is ProvaAgendada) ? b.dataHora : (b as Feriado).data;
       return dataA.compareTo(dataB);
    });

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: calendarBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 4))
            ]
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            locale: t.locale.toString(), 
            
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
              leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.primaryPurple),
              rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.primaryPurple),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(color: textColor),
              weekendTextStyle: TextStyle(color: textColor.withOpacity(0.6)),
              todayDecoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(color: textColor),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primaryPurple,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppColors.cardOrange, 
                shape: BoxShape.circle,
              ),
            ),

            // Carrega as bolinhas marcadoras
            eventLoader: (day) {
              final temProva = provas.any((p) => _isSameDay(p.dataHora, day));
              final temFeriado = feriados.any((f) => _isSameDay(f.data, day));
              
              if (temProva && temFeriado) return [true, true];
              if (temProva || temFeriado) return [true];
              return [];
            },

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
          ),
        ),

        const SizedBox(height: 16),
        
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.t('calendario_eventos_dia', args: [DateFormat('dd/MM').format(_selectedDay!)]),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 16),
                
                if (eventosDoDia.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32.0),
                      child: Text(
                        t.t('calendario_vazio_dia'), 
                        style: TextStyle(color: textColor.withOpacity(0.5))
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: eventosDoDia.length,
                      itemBuilder: (context, index) {
                        final evento = eventosDoDia[index];
                        
                        if (evento is ProvaAgendada) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBlue, 
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.assignment, color: Colors.white),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.t('calendario_prova_prefixo', args: [evento.disciplina]), 
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                                      ),
                                      Text(evento.titulo, style: const TextStyle(color: Colors.white70)),
                                      Text(DateFormat('HH:mm').format(evento.dataHora), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        } 
                        else if (evento is Feriado) {
                           return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardOrange, 
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.beach_access, color: Colors.white),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.t('calendario_feriado_label'), 
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                                      ),
                                      Text(evento.nome, style: const TextStyle(color: Colors.white70)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}