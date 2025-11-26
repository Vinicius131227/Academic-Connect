// lib/l10n/app_localizations.dart
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('pt', ''),
    Locale('en', ''),
    Locale('es', ''),
  ];
  
  // Listas Estáticas
  static const List<String> universidades = ['UFSCar - Campus Sorocaba'];
  static const List<String> cursos = [
    'Administração', 'Ciências Biológicas', 'Ciência da Computação',
    'Ciências Econômicas', 'Engenharia de Produção', 'Engenharia Florestal',
    'Física', 'Geografia', 'Matemática', 'Pedagogia', 'Química', 'Turismo'
  ];
  static const List<String> predios = ['ATLab', 'AT2', 'CCHB', 'CCTS', 'CCGT', 'FINEP 1', 'FINEP 2'];
  static const List<String> identificacaoProfessor = ['Matrícula SIAPE', 'Registro Docente', 'ID Externo'];
  
  // Dicionário
  static final Map<String, Map<String, String>> _valores = {
    'pt': {
      'app_nome': 'Academic Connect',
      'login_titulo': 'Login',
      'login_subtitulo': 'Entre com seus dados de conta',
      'login_email': 'E-mail',
      'login_senha': 'Senha',
      'login_esqueceu_senha': 'Esqueceu a senha?',
      'login_entrar': 'Entrar',
      'login_ou_continue': 'Ou continue com',
      'login_nao_tem_conta': 'Não tem uma conta?',
      'login_cadastre_se': 'Cadastre-se',
      'cadastro_titulo': 'Criar Conta',
      'cadastro_subtitulo': 'Preencha seus dados para começar',
      'cadastro_universidade': 'Universidade *',
      'cadastro_papel_label': 'Perfil *',
      'cadastro_nome_label': 'Nome Completo',
      'cadastro_curso': 'Curso *',
      'cadastro_ra_label': 'RA (Matrícula)',
      'cadastro_data_nasc_label': 'Data de Nascimento *',
      'cadastro_identificacao_prof': 'Tipo de Identificação',
      'cadastro_num_prof': 'Número de Identificação *',
      'cadastro_botao': 'Cadastrar',
      'cadastro_carregando': 'Cadastrando...',
      'cadastro_finalizar': 'Finalizar Cadastro',
      'cadastro_sucesso': 'Cadastro realizado com sucesso!',
      'esqueceu_titulo': 'Esqueceu a Senha?',
      'esqueceu_subtitulo': 'Digite seu e-mail para enviarmos um link de recuperação.',
      'esqueceu_enviar': 'Enviar Link',
      'esqueceu_voltar_login': 'Lembrou a senha?',
      'esqueceu_login_link': 'Login',
      'papel_aluno': 'Sou Aluno(a)',
      'papel_professor': 'Sou Professor(a)',
      'papel_ca': 'Sou do C.A.',
      'inicio_ola': 'Olá',
      'inicio_subtitulo': 'Vamos estudar hoje!',
      'inicio_acesso_rapido': 'Acesso Rápido',
      'inicio_proximas_avaliacoes': 'Próximas Avaliações',
      'inicio_btn_sincronizar': 'Sincronizar Dados',
      'inicio_sem_provas': 'Sem provas agendadas.',
      'card_frequencia': 'Frequência',
      'card_notas': 'Notas',
      'card_adaptacao': 'Adaptação',
      'card_nfc': 'Cartão NFC',
      'card_drive': 'Drive Provas',
      'card_dicas': 'Dicas Gerais',
      'config_titulo': 'Configurações',
      'config_secao_aparencia': 'APARÊNCIA',
      'config_secao_idioma': 'IDIOMA',
      'config_secao_geral': 'GERAL',
      'config_tema_claro': 'Modo Claro',
      'config_tema_escuro': 'Modo Escuro',
      'config_ajuda': 'Ajuda & Onboarding',
      'config_sair': 'Sair da Conta',
      'perfil_titulo': 'Perfil',
      'perfil_editar_btn': 'Editar Perfil',
      'perfil_info_academica': 'INFORMAÇÕES ACADÊMICAS',
      'perfil_info_profissional': 'INFORMAÇÕES PROFISSIONAIS',
      'aluno_disciplinas_aviso': 'A frequência mínima exigida é de 75%.',
      'aluno_disciplinas_faltas': 'faltas',
      'aluno_disciplinas_aulas': 'aulas',
      'aluno_disciplinas_frequencia': 'Frequência',
      'aluno_disciplinas_ver_notas': 'Notas',
      'aluno_disciplinas_acessar_materia': 'Acessar Sala',
      'nfc_cadastro_titulo': 'Cadastrar Cartão NFC',
      'nfc_cadastro_aguardando': 'Aguardando Cartão',
      'nfc_cadastro_instrucao': 'Aproxime o seu cartão RA do leitor NFC do celular.',
      'nfc_cadastro_sucesso': 'Cartão Lido com Sucesso!',
      'nfc_cadastro_uid': 'UID do Cartão:',
      'nfc_cadastro_erro': 'Erro na Leitura',
      'nfc_cadastro_nao_suportado': 'NFC Não Suportado',
      'nfc_cadastro_iniciar': 'Iniciar Leitura',
      'nfc_cadastro_cancelar': 'Cancelar',
      'nfc_cadastro_salvar': 'Salvar Cartão',
      'nfc_cadastro_voltar': 'Voltar',
    },
    'en': {
      'app_nome': 'Academic Connect',
      'login_titulo': 'Login',
      'login_subtitulo': 'Enter your account details',
      'login_email': 'Email',
      'login_senha': 'Password',
      'login_esqueceu_senha': 'Forgot Password?',
      'login_entrar': 'Login',
      'login_ou_continue': 'Or continue with',
      'login_nao_tem_conta': "Don't have an account?",
      'login_cadastre_se': 'Sign Up',
      'cadastro_titulo': 'Create Account',
      'cadastro_subtitulo': 'Fill in your details to start',
      'cadastro_universidade': 'University *',
      'cadastro_papel_label': 'Profile Type *',
      'cadastro_nome_label': 'Full Name',
      'cadastro_curso': 'Course *',
      'cadastro_ra_label': 'Student ID',
      'cadastro_data_nasc_label': 'Birth Date *',
      'cadastro_identificacao_prof': 'ID Type',
      'cadastro_num_prof': 'ID Number *',
      'cadastro_botao': 'Register',
      'cadastro_carregando': 'Registering...',
      'cadastro_finalizar': 'Finish Registration',
      'cadastro_sucesso': 'Registration successful!',
      'esqueceu_titulo': 'Forgot Password?',
      'esqueceu_subtitulo': 'Enter your email to receive a recovery link.',
      'esqueceu_enviar': 'Send Link',
      'esqueceu_voltar_login': 'Remember password?',
      'esqueceu_login_link': 'Login',
      'papel_aluno': 'Student',
      'papel_professor': 'Professor',
      'papel_ca': 'Academic Center',
      'inicio_ola': 'Hello',
      'inicio_subtitulo': "Let's study today!",
      'inicio_acesso_rapido': 'Quick Access',
      'inicio_proximas_avaliacoes': 'Upcoming Exams',
      'inicio_btn_sincronizar': 'Sync Data',
      'inicio_sem_provas': 'No exams scheduled.',
      'card_frequencia': 'Attendance',
      'card_notas': 'Grades',
      'card_adaptacao': 'Adaptation',
      'card_nfc': 'NFC Card',
      'card_drive': 'Exam Drive',
      'card_dicas': 'General Tips',
      'config_titulo': 'Settings',
      'config_secao_aparencia': 'APPEARANCE',
      'config_secao_idioma': 'LANGUAGE',
      'config_secao_geral': 'GENERAL',
      'config_tema_claro': 'Light Mode',
      'config_tema_escuro': 'Dark Mode',
      'config_ajuda': 'Help & Onboarding',
      'config_sair': 'Log Out',
      'perfil_titulo': 'Profile',
      'perfil_editar_btn': 'Edit Profile',
      'perfil_info_academica': 'ACADEMIC INFO',
      'perfil_info_profissional': 'PROFESSIONAL INFO',
      'nav_inicio': 'Home',
      'nav_disciplinas': 'Classes',
      'nav_perfil': 'Profile',
      'aluno_disciplinas_aviso': 'Minimum attendance required is 75%.',
      'aluno_disciplinas_faltas': 'absences',
      'aluno_disciplinas_aulas': 'classes',
      'aluno_disciplinas_frequencia': 'Attendance',
      'aluno_disciplinas_ver_notas': 'Grades',
      'aluno_disciplinas_acessar_materia': 'Enter Class',
      'nfc_cadastro_titulo': 'Register NFC Card',
      'nfc_cadastro_aguardando': 'Scanning for Card',
      'nfc_cadastro_instrucao': 'Hold your student ID card to the NFC reader on your phone.',
      'nfc_cadastro_sucesso': 'Card Scanned Successfully!',
      'nfc_cadastro_uid': 'Card UID:',
      'nfc_cadastro_erro': 'Scan Error',
      'nfc_cadastro_nao_suportado': 'NFC Not Supported',
      'nfc_cadastro_iniciar': 'Start Scan',
      'nfc_cadastro_cancelar': 'Cancel',
      'nfc_cadastro_salvar': 'Save Card',
      'nfc_cadastro_voltar': 'Go Back',
    },
    'es': {
      'app_nome': 'Academic Connect',
      'login_titulo': 'Iniciar Sesión',
      'login_subtitulo': 'Ingresa los datos de tu cuenta',
      'login_email': 'Correo electrónico',
      'login_senha': 'Contraseña',
      'login_esqueceu_senha': '¿Olvidaste tu contraseña?',
      'login_entrar': 'Entrar',
      'login_ou_continue': 'O continuar con',
      'login_nao_tem_conta': '¿No tienes una cuenta?',
      'login_cadastre_se': 'Regístrate',
      'cadastro_titulo': 'Crear Cuenta',
      'cadastro_subtitulo': 'Completa tus datos para empezar',
      'cadastro_universidade': 'Universidad *',
      'cadastro_papel_label': 'Perfil *',
      'cadastro_nome_label': 'Nombre Completo',
      'cadastro_curso': 'Curso *',
      'cadastro_ra_label': 'Matrícula',
      'cadastro_data_nasc_label': 'Fecha de Nacimiento *',
      'cadastro_identificacao_prof': 'Tipo de Identificación',
      'cadastro_num_prof': 'Número de Identificación *',
      'cadastro_botao': 'Registrarse',
      'cadastro_carregando': 'Registrando...',
      'cadastro_finalizar': 'Finalizar Registro',
      'cadastro_sucesso': '¡Registro exitoso!',
      'esqueceu_titulo': '¿Olvidaste la contraseña?',
      'esqueceu_subtitulo': 'Ingresa tu correo para recibir un enlace de recuperación.',
      'esqueceu_enviar': 'Enviar Enlace',
      'esqueceu_voltar_login': '¿Recordaste la contraseña?',
      'esqueceu_login_link': 'Entrar',
      'papel_aluno': 'Estudiante',
      'papel_professor': 'Profesor',
      'papel_ca': 'Centro Académico',
      'inicio_ola': 'Hola',
      'inicio_subtitulo': '¡Vamos a estudiar hoy!',
      'inicio_acesso_rapido': 'Acceso Rápido',
      'inicio_proximas_avaliacoes': 'Próximas Evaluaciones',
      'inicio_btn_sincronizar': 'Sincronizar Datos',
      'inicio_sem_provas': 'Sin exámenes programados.',
      'card_frequencia': 'Asistencia',
      'card_notas': 'Notas',
      'card_adaptacao': 'Adaptación',
      'card_nfc': 'Tarjeta NFC',
      'card_drive': 'Drive Exámenes',
      'card_dicas': 'Consejos Generales',
      'config_titulo': 'Configuración',
      'config_secao_aparencia': 'APARIENCIA',
      'config_secao_idioma': 'IDIOMA',
      'config_secao_geral': 'GENERAL',
      'config_tema_claro': 'Modo Claro',
      'config_tema_escuro': 'Modo Oscuro',
      'config_ajuda': 'Ayuda y Onboarding',
      'config_sair': 'Cerrar Sesión',
      'perfil_titulo': 'Perfil',
      'perfil_editar_btn': 'Editar Perfil',
      'perfil_info_academica': 'INFO ACADÉMICA',
      'perfil_info_profissional': 'INFO PROFESIONAL',
      'nav_inicio': 'Inicio',
      'nav_disciplinas': 'Clases',
      'nav_perfil': 'Perfil',
      'aluno_disciplinas_aviso': 'La asistencia mínima requerida es del 75%.',
      'aluno_disciplinas_faltas': 'ausencias',
      'aluno_disciplinas_aulas': 'clases',
      'aluno_disciplinas_frequencia': 'Asistencia',
      'aluno_disciplinas_ver_notas': 'Notas',
      'aluno_disciplinas_acessar_materia': 'Entrar a Clase',
      'nfc_cadastro_titulo': 'Registrar Tarjeta NFC',
      'nfc_cadastro_aguardando': 'Escaneando Tarjeta',
      'nfc_cadastro_instrucao': 'Acerca tu tarjeta de estudiante al lector NFC de tu móvil.',
      'nfc_cadastro_sucesso': '¡Tarjeta Leída Correctamente!',
      'nfc_cadastro_uid': 'UID de Tarjeta:',
      'nfc_cadastro_erro': 'Error de Lectura',
      'nfc_cadastro_nao_suportado': 'NFC No Soportado',
      'nfc_cadastro_iniciar': 'Iniciar Escaneo',
      'nfc_cadastro_cancelar': 'Cancelar',
      'nfc_cadastro_salvar': 'Guardar Tarjeta',
      'nfc_cadastro_voltar': 'Volver',
    },
  };

  String t(String key, {List<String>? args}) {
    // Tenta pegar a tradução exata (ex: pt_BR)
    String? value = _valores[locale.languageCode]?[key];
    
    // Se falhar e tiver código de país (ex: pt_BR), tenta só o código da língua (ex: pt)
    if (value == null && locale.languageCode.contains('_')) {
       value = _valores[locale.languageCode.split('_')[0]]?[key];
    }

    if (value == null) return key; // Retorna a chave se não achar

    if (args != null) {
      for (int i = 0; i < args.length; i++) {
        value = value!.replaceFirst('{}', args[i]);
      }
    }
    return value!;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Suporta 'pt', 'en', 'es' mesmo com código de país
    return ['pt', 'en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}