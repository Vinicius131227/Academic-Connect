# 📱 Portal do Aluno - App de Gestão Acadêmica

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Riverpod](https://img.shields.io/badge/State-Riverpod-purple?style=for-the-badge)

Aplicativo móvel desenvolvido para facilitar a vida acadêmica dos estudantes, permitindo o acompanhamento de frequência, notas e informações detalhadas sobre disciplinas e professores em tempo real.

## ✨ Funcionalidades

- **🔐 Autenticação Segura:** Login e Logout integrados com Firebase Authentication.
- **🔄 Recuperação de Senha:** Fluxo completo com envio de link por e-mail e feedback visual.
- **📊 Controle de Frequência:** - Cálculo automático de percentual de presença baseado em aulas cadastradas no Firestore.
  - Indicadores visuais de status (Aprovado/Reprovado).
- **📍 Localização e Contato:** - Visualização de sala de aula e e-mail do professor.
  - **Integração com Mapas:** Abertura direta do Google Maps via *Plus Code* para localização exata do prédio/sala.
  - Atalho para envio de e-mail direto ao docente.
- **📝 Notas e Avaliações:** Visualização de desempenho acadêmico.
- **☁️ Sincronização em Tempo Real:** Dados atualizados instantaneamente via Streams do Firestore.

## 🛠️ Tecnologias Utilizadas

- **Frontend:** [Flutter](https://flutter.dev/) (Dart)
- **Backend (BaaS):** [Firebase](https://firebase.google.com/)
  - **Authentication:** Gestão de usuários.
  - **Firestore Database:** Banco de dados NoSQL em tempo real.
- **Gerenciamento de Estado:** [Riverpod](https://riverpod.dev/) (Hooks & Providers).
- **Pacotes Principais:**
  - `cloud_firestore` & `firebase_auth`
  - `flutter_riverpod`
  - `url_launcher` (Para abrir Mapas e E-mail)
  - `google_fonts` (Tipografia moderna)
  - `percent_indicator` (Gráficos de frequência)

## 🚀 Como Executar o Projeto

### Pré-requisitos
- Flutter SDK instalado.
- Conta no Firebase configurada.

### Passo a Passo

1. **Clone o repositório:**
   ```bash
   git clone [https://github.com/SEU_USUARIO/NOME_DO_REPO.git](https://github.com/SEU_USUARIO/NOME_DO_REPO.git)
   cd NOME_DO_REPO
