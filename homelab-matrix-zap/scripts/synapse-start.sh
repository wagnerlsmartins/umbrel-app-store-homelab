#!/bin/bash
# Bootstrap do Synapse do Matrix Zap.
# Idempotente: gera o homeserver.yaml só na primeira vez, garante as linhas
# que o app oficial do Umbrel não dá (appservices dos bridges registrados e
# registro de contas desligado) e espera cada bridge gerar o seu
# registration.yaml antes de subir — o bridge gera esse arquivo sem precisar
# do Synapse no ar, então a espera converge.
#
# Instalação antiga (só WhatsApp, v0.1.0): o bloco já existe no homeserver.yaml
# e só falta a linha do Signal; ela é inserida logo abaixo da do WhatsApp.
set -euo pipefail

cd /

if [ ! -f /data/homeserver.yaml ]; then
  ./start.py generate
fi

if ! grep -q '^app_service_config_files:' /data/homeserver.yaml; then
  cat >> /data/homeserver.yaml <<'EOF'

# --- adicionado pelo Matrix Zap (homelab-matrix-zap) ---
enable_registration: false
app_service_config_files:
  - /bridges/whatsapp/registration.yaml
  - /bridges/signal/registration.yaml
EOF
fi

if ! grep -q '/bridges/signal/registration.yaml' /data/homeserver.yaml; then
  sed -i 's#^  - /bridges/whatsapp/registration.yaml$#&\n  - /bridges/signal/registration.yaml#' /data/homeserver.yaml
fi

for ponte in whatsapp signal; do
  echo "matrix-zap: aguardando o bridge gerar /bridges/$ponte/registration.yaml"
  while [ ! -f "/bridges/$ponte/registration.yaml" ]; do
    sleep 3
  done
done

exec ./start.py
