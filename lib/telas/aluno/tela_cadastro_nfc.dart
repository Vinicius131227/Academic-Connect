import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// Importações internas
import '../../providers/provedor_aluno.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../comum/cartao_vidro.dart';

@UseCase(
  name: 'Cadastro NFC',
  type: TelaCadastroNFC,
)
Widget buildTelaCadastroNFC(BuildContext context) {
  return const ProviderScope(
    child: TelaCadastroNFC(),
  );
}

class TelaCadastroNFC extends ConsumerWidget {
  const TelaCadastroNFC({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    
    final estado = ref.watch(provedorCadastroNFC);
    final notifier = ref.read(provedorCadastroNFC.notifier);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3))
                ),
                child: Column(
                  children: [
                    Text(
                      "Código Lido (Livre para uso):",
                      style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      estado.uid ?? '---',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryPurple, letterSpacing: 1.2),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
          
        case StatusCadastroNFC.error:
        case StatusCadastroNFC.unsupported:
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 100, color: AppColors.error),
              const SizedBox(height: 24),
              Text(
                estado.status == StatusCadastroNFC.error
                    ? t.t('nfc_cadastro_erro')
                    : t.t('nfc_cadastro_nao_suportado'),
                style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  estado.erro ?? 'Um erro desconhecido ocorreu.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: textColor.withOpacity(0.8), fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
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
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Ler outro cartão"), 
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryPurple,
                  side: const BorderSide(color: AppColors.primaryPurple),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => notifier.iniciarLeitura(),
              ),
            ],
          );
          
        case StatusCadastroNFC.error:
        case StatusCadastroNFC.unsupported:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (estado.status == StatusCadastroNFC.error)
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Tentar Outro Cartão"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => notifier.iniciarLeitura(),
                ),
              if (estado.status == StatusCadastroNFC.error)
                const SizedBox(height: 12),
                
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: Text(t.t('nfc_cadastro_voltar')),
                 style: ElevatedButton.styleFrom(
                  backgroundColor: estado.status == StatusCadastroNFC.error ? Colors.grey : AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
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
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
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