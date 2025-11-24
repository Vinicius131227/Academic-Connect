// lib/telas/comum/tela_configuracoes.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provedor_autenticacao.dart';
import '../../l10n/app_localizations.dart';

class TelaConfiguracoes extends ConsumerStatefulWidget {
  const TelaConfiguracoes({super.key});

  @override
  ConsumerState<TelaConfiguracoes> createState() => _TelaConfiguracoesState();
}

class _TelaConfiguracoesState extends ConsumerState<TelaConfiguracoes> {
  // Simulação de configuração de notificação
  bool _notificacoesAtivas = true;
  String _idiomaSelecionado = 'pt';
  
  // Simulação de lista de idiomas
  final Map<String, String> _idiomas = {
    'pt': 'Português',
    'en': 'English',
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final user = ref.watch(provedorNotificadorAutenticacao).usuario;
    final papel = user?.papel;
    
    String _getPapelTraduzido(String? papel) {
      if (papel == 'aluno') return t.t('papel_aluno');
      if (papel == 'professor') return t.t('papel_professor');
      if (papel == 'ca_projeto') return t.t('papel_ca');
      return t.t('papel_desconhecido');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('config_titulo')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Seção de Perfil ---
            Text(t.t('config_perfil_titulo'), style: theme.textTheme.titleLarge),
            const Divider(),
            
            ListTile(
              title: Text(t.t('cadastro_nome_label')),
              subtitle: Text(user?.alunoInfo?.nomeCompleto ?? 'N/A'),
              leading: const Icon(Icons.person),
            ),
            ListTile(
              title: Text(t.t('config_email')),
              subtitle: Text(user?.email ?? 'N/A'),
              leading: const Icon(Icons.email),
            ),
            ListTile(
              title: Text(t.t('config_papel')),
              subtitle: Text(_getPapelTraduzido(papel)),
              leading: const Icon(Icons.work),
            ),
            
            const SizedBox(height: 24),

            // --- Seção de Configurações Gerais ---
            Text(t.t('config_geral_titulo'), style: theme.textTheme.titleLarge),
            const Divider(),
            
            // Notificações
            SwitchListTile(
              title: Text(t.t('config_notif_titulo')),
              subtitle: Text(t.t('config_notif_desc')),
              value: _notificacoesAtivas,
              onChanged: (bool value) {
                setState(() {
                  _notificacoesAtivas = value;
                });
                // Lógica para salvar a preferência
              },
              secondary: const Icon(Icons.notifications),
            ),
            
            // Idioma
            ListTile(
              title: Text(t.t('config_idioma')),
              leading: const Icon(Icons.language),
              trailing: DropdownButton<String>(
                value: _idiomaSelecionado,
                items: _idiomas.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _idiomaSelecionado = newValue;
                    });
                    // Lógica para mudar o idioma (precisa de um provedor de localização real)
                  }
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // --- Seção de Ação ---
            Text(t.t('config_acoes_titulo'), style: theme.textTheme.titleLarge),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(t.t('config_logout'), style: const TextStyle(color: Colors.red)),
              onTap: () {
                // CORRIGIDO: O método está definido no NotificadorAutenticacao
                ref.read(provedorNotificadorAutenticacao.notifier).logout();
              },
            ),

            if (papel == 'professor')
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: Text(t.t('config_vincular_nfc')),
                onTap: () {
                  // TODO: Implementar navegação para tela de vincular NFC
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile<T>(BuildContext context, {required String title, String? subtitle, IconData? icon, required T value, required T groupValue, required ValueChanged<T?> onChanged}) {
    return RadioListTile<T>(
      title: Row(children: [ if (icon != null) Icon(icon, size: 20), if (icon != null) const SizedBox(width: 8), Text(title) ]),
      subtitle: subtitle != null ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall) : null,
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  void _confirmarSaida(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(t.t('config_sair_dialog_titulo')),
          content: Text(t.t('config_sair_dialog_desc')),
          actions: <Widget>[
            TextButton(
              child: Text(t.t('config_sair_dialog_cancelar')),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(t.t('config_sair'), style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); 
                Navigator.of(context).pop(); // Sai da tela de Configurações
                ref.read(provedorNotificadorAutenticacao.notifier).logout(); 
              },
            ),
          ],
        );
      },
    );
  }
}