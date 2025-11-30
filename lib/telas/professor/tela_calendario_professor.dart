// lib/telas/professor/tela_calendario_professor.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart'; // Pacote de calendário
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../providers/provedores_app.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../themes/app_theme.dart';
import '../../models/prova_agendada.dart';
import '../comum/widget_carregamento.dart';

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Calendário Professor',
  type: TelaCalendarioProfessor,
)
Widget buildTelaCalendarioProf(BuildContext context) {
  return const ProviderScope(
    child: TelaCalendarioProfessor(),
  );
}

/// Modelo simples para feriados.
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

/// Provider que busca feriados nacionais da API Nager.Date.
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

/// Tela de Calendário exclusiva do Professor.
///
/// Diferença para o aluno: Filtra e exibe apenas eventos das turmas
/// onde o usuário logado é o professor responsável (campo `professorId`).
class TelaCalendarioProfessor extends ConsumerStatefulWidget {
  const TelaCalendarioProfessor({super.key});

  @override
  ConsumerState<TelaCalendarioProfessor> createState() => _TelaCalendarioProfessorState();
}

class _TelaCalendarioProfessorState extends ConsumerState<TelaCalendarioProfessor> {
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
    // 1. Carrega Turmas do Professor (para filtrar provas)
    final asyncTurmas = ref.watch(provedorStreamTurmasProfessor);
    
    // 2. Carrega Todas as Provas do sistema
    final asyncProvas = ref.watch(provedorStreamCalendario);
    
    // 3. Carrega Feriados
    final asyncFeriados = ref.watch(feriadosProvider);
    
    // Configuração de Tema
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final calendarBg = isDark ? AppColors.surfaceDark : Colors.white;
    final shadowColor = isDark ? Colors.transparent : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Agenda do Professor', 
          style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: asyncTurmas.when(
        loading: () => const WidgetCarregamento(texto: "Carregando turmas..."),
        error: (e, s) => Center(child: Text("Erro: $e")),
        data: (turmasDoProfessor) {
          // Lista de IDs das turmas que esse professor ministra
          final idsTurmasProfessor = turmasDoProfessor.map((t) => t.id).toList();

          return asyncProvas.when(
            loading: () => const WidgetCarregamento(texto: "Carregando agenda..."),
            error: (e, s) => Center(child: Text("Erro provas: $e")),
            data: (todasProvas) {
              // FILTRO: Mantém apenas provas das turmas deste professor
              final provasFiltradas = todasProvas.where((p) => idsTurmasProfessor.contains(p.turmaId)).toList();

              return asyncFeriados.when(
                loading: () => const WidgetCarregamento(),
                // Se falhar feriados, mostra só provas
                error: (_,__) => _buildBody(provasFiltradas, [], textColor, calendarBg, cardColor, shadowColor),
                data: (feriados) => _buildBody(provasFiltradas, feriados, textColor, calendarBg, cardColor, shadowColor),
              );
            },
          );
        },
      ),
    );
  }

  /// Constrói o corpo da tela com Calendário e Lista.
  Widget _buildBody(List<ProvaAgendada> provas, List<Feriado> feriados, Color? textColor, Color calendarBg, Color cardColor, Color shadowColor) {
    // Filtra eventos do dia selecionado
    final eventosDoDia = [
      ...provas.where((p) => _isSameDay(p.dataHora, _selectedDay)),
      ...feriados.where((f) => _isSameDay(f.data, _selectedDay)),
    ];

    return Column(
      children: [
        // WIDGET CALENDÁRIO
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
            
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: GoogleFonts.poppins(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
              leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.primaryPurple),
              rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.primaryPurple),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(color: textColor),
              weekendTextStyle: TextStyle(color: textColor?.withOpacity(0.6)),
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

            eventLoader: (day) {
              final temProva = provas.any((p) => _isSameDay(p.dataHora, day));
              final temFeriado = feriados.any((f) => _isSameDay(f.data, day));
              if (temProva && temFeriado) return [true, true]; // 2 pontos
              if (temProva || temFeriado) return [true];       // 1 ponto
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
        
        // LISTA DE EVENTOS DO DIA
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Agenda de ${_selectedDay!.day}/${_selectedDay!.month}",
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 16),
                
                if (eventosDoDia.isEmpty)
                  Center(child: Text("Nenhum evento para este dia.", style: TextStyle(color: textColor?.withOpacity(0.5))))
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
                              color: AppColors.cardBlue, // Azul para Provas
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.assignment_ind, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(evento.disciplina, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text(evento.titulo, style: GoogleFonts.poppins(color: Colors.white70)),
                                      Text(DateFormat('HH:mm').format(evento.dataHora), style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (evento is Feriado) {
                           return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardOrange, // Laranja para Feriados
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
                                      Text("Feriado", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text(evento.nome, style: GoogleFonts.poppins(color: Colors.white70)),
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