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

exec mautrix-whatsapp -c /data/config.yaml
