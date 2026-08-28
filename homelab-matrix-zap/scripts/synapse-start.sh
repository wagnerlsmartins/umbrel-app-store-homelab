#!/bin/bash
# Bootstrap do Synapse do Matrix Zap.
# Idempotente: gera o homeserver.yaml só na primeira vez, garante as duas
# linhas que o app oficial do Umbrel não dá (appservice do bridge registrado
# e registro de contas desligado) e espera o bridge gerar o registration.yaml
# antes de subir — o bridge gera esse arquivo sem precisar do Synapse no ar,
# então a espera converge.
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
EOF
fi

echo "matrix-zap: aguardando o bridge gerar /bridges/whatsapp/registration.yaml"
while [ ! -f /bridges/whatsapp/registration.yaml ]; do
  sleep 3
done

exec ./start.py
