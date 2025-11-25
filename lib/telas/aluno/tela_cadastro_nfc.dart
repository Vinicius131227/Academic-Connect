// lib/telas/aluno/tela_cadastro_nfc.dart
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
              Icon(Icons.nfc,
                  size: 100, color: AppColors.primaryPurple),
              const SizedBox(height: 24),
              Text(
                t.t('nfc_cadastro_aguardando'),
                style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                t.t('nfc_cadastro_instrucao'),
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
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
                style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '${t.t('nfc_cadastro_uid')} ${estado.uid}',
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          );
        case StatusCadastroNFC.error:
        case StatusCadastroNFC.unsupported:
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 120, color: AppColors.error),
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
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          );
        case StatusCadastroNFC.idle:
        default:
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone visível com a cor do tema
              Icon(Icons.nfc,
                  size: 120, color: AppColors.primaryPurple.withOpacity(0.5)),
              const SizedBox(height: 24),
              Text(
                t.t('nfc_cadastro_titulo'),
                style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                t.t('nfc_cadastro_instrucao'),
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
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
        title: Text(t.t('nfc_cadastro_titulo')),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2C2C2C), AppColors.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: CartaoVidro(child: cardContentWrapper),
            ),
          ),
        ),
      ),
    );
  }
}