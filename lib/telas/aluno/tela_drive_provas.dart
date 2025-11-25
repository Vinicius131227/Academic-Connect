// lib/telas/aluno/tela_drive_provas.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/servico_firestore.dart';
import '../comum/widget_carregamento.dart';
import '../comum/tela_webview.dart';
import '../../themes/app_theme.dart';
import '../../models/material_aula.dart'; // Certifique-se de importar

// Provedor que busca TODOS os materiais do tipo 'prova' (query global)
final driveProvasProvider = StreamProvider<List<MaterialAula>>((ref) {
  // Precisamos de um novo método no serviço: getTodosMateriaisTipoProva
  // Como workaround rápido, usamos o stream de materiais antigos passando uma string vazia ou ajustamos o serviço
  // Vamos assumir que você adicionou getMateriaisGlobais no serviço ou usar um filtro manual.
  // Melhor: Criar um método específico no serviço.
  return ref.watch(servicoFirestoreProvider).getTodosMateriaisTipoProva();
});

class TelaDriveProvas extends ConsumerWidget {
  const TelaDriveProvas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProvas = ref.watch(driveProvasProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Drive de Provas Antigas")),
      body: asyncProvas.when(
        loading: () => const WidgetCarregamento(),
        error: (e, s) => Center(child: Text("Erro: $e")),
        data: (materiais) {
          if (materiais.isEmpty) return const Center(child: Text("O drive está vazio.", style: TextStyle(color: Colors.white)));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: materiais.length,
            itemBuilder: (context, index) {
              final material = materiais[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.folder_zip, color: Colors.orange, size: 32),
                  title: Text(material.titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(material.descricao.isNotEmpty ? material.descricao : "Sem descrição", style: const TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.download_rounded, color: Colors.white),
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => TelaWebView(url: material.url, titulo: material.titulo)));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           // Alunos podem fazer upload? Se sim, abre tela de upload. 
           // Se não, removemos. Vamos assumir que podem contribuir.
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Upload de provas em breve!")));
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}