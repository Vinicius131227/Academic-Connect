// lib/telas/aluno/tela_calendario.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart'; // Pacote de calendário
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../providers/provedores_app.dart';
import '../../themes/app_theme.dart';
import '../../models/prova_agendada.dart';
import '../comum/widget_carregamento.dart';
import '../../l10n/app_localizations.dart'; // Import da localização

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Calendário Acadêmico',
  type: TelaCalendario,
)
Widget buildTelaCalendario(BuildContext context) {
  return const ProviderScope(
    child: TelaCalendario(),
  );
}

/// Modelo simples para representar um feriado vindo da API externa.
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

/// Provedor que busca os feriados nacionais do Brasil para o ano atual.
/// Usa a API pública Nager.Date.
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
    return []; // Retorna vazio se falhar (sem internet)
  }
});

/// Tela de Calendário que mostra eventos acadêmicos e feriados.
/// Permite ao aluno visualizar suas entregas e provas.
class TelaCalendario extends ConsumerStatefulWidget {
  const TelaCalendario({super.key});

  @override
  ConsumerState<TelaCalendario> createState() => _TelaCalendarioState();
}

class _TelaCalendarioState extends ConsumerState<TelaCalendario> {
  // Configurações do calendário
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  /// Verifica se duas datas correspondem ao mesmo dia (ignora hora).
  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    // Busca dados assíncronos
    final asyncProvas = ref.watch(provedorStreamCalendario);
    final asyncFeriados = ref.watch(feriadosProvider);
    final t = AppLocalizations.of(context)!;
    
    // Tema Dinâmico
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
      // Carrega provas primeiro
      body: asyncProvas.when(
        loading: () => const WidgetCarregamento(),
        error: (e, s) => Center(child: Text('${t.t('erro_generico')}: $e', style: TextStyle(color: textColor))),
        data: (provas) {
          // Carrega feriados depois
          return asyncFeriados.when(
            loading: () => const WidgetCarregamento(),
            // Se falhar feriados, mostra só provas
            error: (_,__) => _buildCalendarContent(provas, [], textColor, calendarBg, cardColor, shadowColor),
            data: (feriados) => _buildCalendarContent(provas, feriados, textColor, calendarBg, cardColor, shadowColor),
          );
        },
      ),
    );
  }

  /// Constrói o conteúdo principal: Calendário + Lista de Eventos do Dia.
  Widget _buildCalendarContent(List<ProvaAgendada> provas, List<Feriado> feriados, Color textColor, Color calendarBg, Color cardColor, Color shadowColor) {
    final t = AppLocalizations.of(context)!;
    
    // Filtra eventos para o dia selecionado
    final eventosDoDia = [
      ...provas.where((p) => _isSameDay(p.dataHora, _selectedDay)),
      ...feriados.where((f) => _isSameDay(f.data, _selectedDay)),
    ];

    return Column(
      children: [
        // --- WIDGET DE CALENDÁRIO ---
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
            // Define o locale do calendário de acordo com o AppLocalizations
            locale: t.locale.toString(), 
            
            // Estilização
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
                color: AppColors.cardOrange, // Bolinha indicadora de evento
                shape: BoxShape.circle,
              ),
            ),

            // Carrega os eventos para mostrar as bolinhas nos dias
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
        
        // --- LISTA DE DETALHES DO DIA ---
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // TRADUZIDO: "Eventos do Dia 25/12"
                  t.t('calendario_eventos_dia', args: [DateFormat('dd/MM').format(_selectedDay!)]),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 16),
                
                if (eventosDoDia.isEmpty)
                  Center(
                    child: Text(
                      // TRADUZIDO: "Nada agendado para este dia."
                      t.t('calendario_vazio_dia'), 
                      style: TextStyle(color: textColor.withOpacity(0.5))
                    )
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: eventosDoDia.length,
                      itemBuilder: (context, index) {
                        final evento = eventosDoDia[index];
                        
                        // Card de Prova
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
                                      // TRADUZIDO: "Prova: Matemática"
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
                        // Card de Feriado
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
                                      // TRADUZIDO: "Feriado"
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