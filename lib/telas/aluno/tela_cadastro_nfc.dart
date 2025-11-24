import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provedor_aluno.dart';
import '../../l10n/app_localizations.dart';
import '../../themes/app_theme.dart';
import '../comum/cartao_vidro.dart';

class TelaCadastroNFC extends ConsumerWidget {
  const TelaCadastroNFC({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final estado = ref.watch(provedorCadastroNFC);
    final notifier = ref.read(provedorCadastroNFC.notifier);
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Determina o conteúdo principal baseado no estado
    Widget buildContent() {
      switch (estado.status) {
        case StatusCadastroNFC.scanning:
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.darkAccent : AppColors.lightPrimary),
              ),
              const SizedBox(height: 32),
              Icon(Icons.nfc,
                  size: 100, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                t.t('nfc_cadastro_aguardando'),
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                t.t('nfc_cadastro_instrucao'),
                style: theme.textTheme.bodyLarge,
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
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '${t.t('nfc_cadastro_uid')} ${estado.uid}',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          );
        case StatusCadastroNFC.error:
        case StatusCadastroNFC.unsupported:
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 120, color: theme.colorScheme.error),
              const SizedBox(height: 24),
              Text(
                estado.status == StatusCadastroNFC.error
                    ? t.t('nfc_cadastro_erro')
                    : t.t('nfc_cadastro_nao_suportado'),
                style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                estado.erro ?? 'Um erro desconhecido ocorreu.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          );
        case StatusCadastroNFC.idle:
        default:
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.nfc,
                  size: 120, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              const SizedBox(height: 24),
              Text(
                t.t('nfc_cadastro_titulo'),
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                t.t('nfc_cadastro_instrucao'),
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          );
      }
    }

    // Determina os botões baseados no estado
    Widget buildButtons() {
      switch (estado.status) {
        case StatusCadastroNFC.scanning:
          return OutlinedButton.icon(
            icon: const Icon(Icons.cancel),
            label: Text(t.t('nfc_cadastro_cancelar')),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
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
            onPressed: () => Navigator.pop(context),
          );
        case StatusCadastroNFC.idle:
        default:
          return ElevatedButton.icon(
            icon: const Icon(Icons.nfc),
            label: Text(t.t('nfc_cadastro_iniciar')),
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
        title: Text(t.t('nfc_cadastro_titulo')),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
            ? [AppColors.darkSurface, AppColors.darkBg]
            : [AppColors.lightPrimary.withOpacity(0.3), AppColors.lightBg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: isDark 
                ? CartaoVidro(child: cardContentWrapper) 
                : Card(elevation: 4, child: cardContentWrapper),
            ),
          ),
        ),
      ),
    );
  }
}