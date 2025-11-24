// lib/telas/professor/tela_historico_chamadas.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/turma_professor.dart';
import '../../services/servico_firestore.dart';
import 'tela_editar_chamada_antiga.dart'; 

class TelaHistoricoChamadas extends ConsumerWidget {
  final TurmaProfessor turma;
  const TelaHistoricoChamadas({super.key, required this.turma});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streamDatas = StreamProvider.autoDispose((ref) => 
      ref.read(servicoFirestoreProvider).getDatasChamadas(turma.id)
    );
    final datasAsync = ref.watch(streamDatas);

    return Scaffold(
      appBar: AppBar(title: const Text("Histórico de Chamadas")),
      body: datasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Erro: $e")),
        data: (datas) {
          if (datas.isEmpty) return const Center(child: Text("Nenhuma chamada registrada."));
          
          final datasOrdenadas = List<String>.from(datas)..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            itemCount: datasOrdenadas.length,
            itemBuilder: (ctx, i) {
              final data = datasOrdenadas[i]; 
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.blue),
                  title: Text("Aula: $data"),
                  subtitle: const Text("Toque para editar presença"),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => TelaEditarChamadaAntiga(turma: turma, dataId: data)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}