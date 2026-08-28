#!/bin/sh
# Bootstrap do mautrix-whatsapp do Matrix Zap.
# Primeira execução: copia o config-template do repo e roda o gerador de
# registration (-g), que cria tokens aleatórios no próprio aparelho e os
# grava em config.yaml + registration.yaml — por isso nenhum segredo vive
# no repo. Execuções seguintes só sobem o bridge.
set -eu

if [ ! -f /data/config.yaml ]; then
  cp /templates/whatsapp-config.yaml /data/config.yaml
fi

if [ ! -f /data/registration.yaml ]; then
  mautrix-whatsapp -g -c /data/config.yaml -r /data/registration.yaml
fi

# O Synapse roda como uid 1000 e precisa ler o registration; o bridge o
# gera como root 600. Idempotente a cada boot.
chown 1000:1000 /data/registration.yaml
chmod 640 /data/registration.yaml

exec mautrix-whatsapp -c /data/config.yaml
