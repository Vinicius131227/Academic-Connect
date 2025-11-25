// lib/telas/aluno/tela_calendario.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/provedores_app.dart';
import '../../themes/app_theme.dart';
import '../../models/prova_agendada.dart';
import '../comum/widget_carregamento.dart';

// --- MODELO PARA A API DE FERIADOS ---
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

// --- PROVIDER DA API (FERIADOS BRASIL) ---
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

  // Helper para verificar se duas datas são o mesmo dia
  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final asyncProvas = ref.watch(provedorStreamCalendario);
    final asyncFeriados = ref.watch(feriadosProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Calendário Acadêmico')),
      body: asyncProvas.when(
        loading: () => const WidgetCarregamento(),
        error: (e, s) => Center(child: Text('Erro: $e')),
        data: (provas) {
          return asyncFeriados.when(
            loading: () => const WidgetCarregamento(),
            error: (_,__) => _buildCalendarContent(provas, []), // Mostra provas mesmo sem feriados
            data: (feriados) => _buildCalendarContent(provas, feriados),
          );
        },
      ),
    );
  }

  Widget _buildCalendarContent(List<ProvaAgendada> provas, List<Feriado> feriados) {
    // Eventos do dia selecionado
    final eventosDoDia = [
      ...provas.where((p) => _isSameDay(p.dataHora, _selectedDay)),
      ...feriados.where((f) => _isSameDay(f.data, _selectedDay)),
    ];

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            
            // Estilo do Calendário
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.primaryPurple),
              rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.primaryPurple),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(color: Colors.white),
              weekendTextStyle: const TextStyle(color: Colors.white70),
              todayDecoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primaryPurple,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppColors.cardYellow, // Bolinha amarela para eventos
                shape: BoxShape.circle,
              ),
            ),

            // Carrega os eventos (bolinhas)
            eventLoader: (day) {
              final temProva = provas.any((p) => _isSameDay(p.dataHora, day));
              final temFeriado = feriados.any((f) => _isSameDay(f.data, day));
              if (temProva && temFeriado) return [true, true]; // Duas bolinhas
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
        
        // LISTA DE EVENTOS DO DIA
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Eventos do Dia",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                if (eventosDoDia.isEmpty)
                  const Center(child: Text("Nada agendado para este dia.", style: TextStyle(color: Colors.white54)))
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: eventosDoDia.length,
                      itemBuilder: (context, index) {
                        final evento = eventosDoDia[index];
                        
                        // Verifica se é Prova ou Feriado para mudar o card
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
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.assignment, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Prova: ${evento.disciplina}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      Text(evento.titulo, style: const TextStyle(color: Colors.white70)),
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
                              color: AppColors.cardOrange,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.beach_access, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Feriado", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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