import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../providers/provedor_aluno.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../comum/cartao_vidro.dart';

/// Caso de uso para o Widgetbook.
@UseCase(
  name: 'Cadastro NFC',
  type: TelaCadastroNFC,
)
Widget buildTelaCadastroNFC(BuildContext context) {
  return const ProviderScope(
    child: TelaCadastroNFC(),
  );
}

/// Tela que permite ao aluno cadastrar seu cartão NFC.
class TelaCadastroNFC extends ConsumerWidget {
  const TelaCadastroNFC({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    final estado = ref.watch(provedorCadastroNFC);
    final notifier = ref.read(provedorCadastroNFC.notifier);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Texto branco se fundo escuro, preto se fundo claro
    final textColor = isDark ? Colors.white : Colors.black87;

    /// Constrói o conteúdo central com base no estado atual
    Widget buildContent() {
      switch (estado.status) {
        case StatusCadastroNFC.scanning:
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
              ),
              const SizedBox(height: 32),
              const Icon(Icons.nfc, size: 100, color: AppColors.primaryPurple),
              const SizedBox(height: 24),
              Text(
                t.t('nfc_cadastro_aguardando'),
                style: theme.textTheme.headlineSmall?.copyWith(color: textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                t.t('nfc_cadastro_instrucao'),
                style: theme.textTheme.bodyLarge?.copyWith(color: textColor.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          );
          
        case StatusCadastroNFC.success:
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 120, color: Colors.green.shade600),
              const SizedBox(height: 24),
              Text(
                t.t('nfc_cadastro_sucesso'),
                style: theme.textTheme.headlineSmall?.copyWith(color: textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '${t.t('nfc_cadastro_uid')} ${estado.uid}',
                style: theme.textTheme.bodyLarge?.copyWith(color: textColor.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          );
          
        case StatusCadastroNFC.error:
        case StatusCadastroNFC.unsupported:
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 120, color: AppColors.error),
              const SizedBox(height: 24),
              Text(
                estado.status == StatusCadastroNFC.error
                    ? t.t('nfc_cadastro_erro')
                    : t.t('nfc_cadastro_nao_suportado'),
                style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                estado.erro ?? 'Um erro desconhecido ocorreu.',
                style: theme.textTheme.bodyLarge?.copyWith(color: textColor.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          );
          
        case StatusCadastroNFC.idle:
        default:
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.nfc, size: 120, color: AppColors.primaryPurple.withOpacity(0.5)),
              const SizedBox(height: 24),
              Text(
                t.t('nfc_cadastro_titulo'),
                style: theme.textTheme.headlineSmall?.copyWith(color: textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                t.t('nfc_cadastro_instrucao'),
                style: theme.textTheme.bodyLarge?.copyWith(color: textColor.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          );
      }
    }

    /// Constrói os botões de ação
    Widget buildButtons() {
      switch (estado.status) {
        case StatusCadastroNFC.scanning:
          return OutlinedButton.icon(
            icon: const Icon(Icons.cancel),
            label: Text(t.t('nfc_cadastro_cancelar')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => notifier.reset(),
          );
          
        case StatusCadastroNFC.success:
          return ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: Text(t.t('nfc_cadastro_salvar')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              if (estado.uid != null) {
                notifier.salvarCartao(estado.uid!);
                Navigator.pop(context);
              }
            },
          );
          
        case StatusCadastroNFC.error:
        case StatusCadastroNFC.unsupported:
          return ElevatedButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: Text(t.t('nfc_cadastro_voltar')),
             style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => Navigator.pop(context),
          );
          
        case StatusCadastroNFC.idle:
        default:
          return ElevatedButton.icon(
            icon: const Icon(Icons.nfc),
            label: Text(t.t('nfc_cadastro_iniciar')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => notifier.iniciarLeitura(),
          );
      }
    }

    Widget cardContentWrapper = Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: buildContent(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          buildButtons(),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('nfc_cadastro_titulo'), style: TextStyle(color: textColor)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
      ),
      extendBodyBehindAppBar: true, 
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [const Color(0xFF2C2C2C), AppColors.backgroundDark] 
                : [Colors.grey.shade100, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              // CORREÇÃO: Removido bgColor e borderColor, usando apenas child
              child: CartaoVidro(
                child: cardContentWrapper
              ),
            ),
          ),
        ),
      ),
    );
  }
}