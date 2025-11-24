#!/usr/bin/env bash
set -euo pipefail

# 1. Instalar o Flutter (apenas o necessário para rodar)
FLUTTER_DIR="$HOME/flutter"
if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Baixando Flutter..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_DIR"
fi

# 2. Adicionar Flutter ao caminho do sistema temporariamente
export PATH="$FLUTTER_DIR/bin:$PATH"

# 3. Verificar a instalação e habilitar Web
echo "Configurando Flutter..."
flutter channel stable
flutter config --enable-web
flutter precache --web

# 4. Baixar dependências e Construir o site
echo "Construindo o projeto..."
flutter pub get
flutter build web --release --no-tree-shake-icons