// lib/telas/aluno/aba_perfil_aluno.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provedor_autenticacao.dart';
import 'tela_editar_perfil.dart';
import 'tela_sugestoes.dart'; // IMPORTANTE
import '../../l10n/app_localizations.dart';

class AbaPerfilAluno extends ConsumerWidget {
  const AbaPerfilAluno({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final authState = ref.watch(provedorNotificadorAutenticacao);
    final usuario = authState.usuario;
    final theme = Theme.of(context);

    if (authState.carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (usuario == null) {
       return const Center(child: Text("Usuário não encontrado. Tente fazer login novamente."));
    }

    final alunoInfo = usuario.alunoInfo;
    if (alunoInfo == null) {
       return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             const Text("Perfil incompleto."),
             ElevatedButton(
               child: const Text("Completar Cadastro"),
               onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaEditarPerfil(isFromSignUp: true))),
             )
           ],
         ),
       );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.person, size: 60, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 16),
                  Text(alunoInfo.nomeCompleto, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                  Text('RA: ${alunoInfo.ra}', style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
                  Text('Curso: ${alunoInfo.curso}', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text(t.t('aluno_perfil_editar')),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaEditarPerfil()));
                    },
                  ),
                ],
              ),
            ),
          ),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                   _buildInfoRow(context, t.t('aluno_perfil_cr'), alunoInfo.cr.toStringAsFixed(2)),
                   _buildInfoRow(context, t.t('aluno_perfil_status'), alunoInfo.status,
                      valueColor: alunoInfo.status == 'Regular' ? Colors.green : Colors.red),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.feedback_outlined, color: Colors.purple),
              title: const Text('Enviar Sugestão / Reclamação'),
              subtitle: const Text('Ajude a melhorar o aplicativo.'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaSugestoes()));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
} 