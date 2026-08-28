# Umbrel App Store — Home Lab

Community app store do Umbrel Home do Wagner. Um app por enquanto:

## `homelab-matrix-zap` — Matrix Zap

A espinha Matrix da ingestão de contexto do Vira Sistema
(D-040 do `vira-sistema`, `canais-whatsapp.md`): **Synapse** (homeserver) +
**mautrix-whatsapp** (bridge, um login por número) + **Element Web**
(interface de observação).

Por que não o app oficial de Synapse da loja do Umbrel: lá o `server_name`
fica amarrado ao endereço Tor do aparelho (identidade permanente e feia) e o
registro de contas nasce aberto. Aqui o `server_name` é
**`matrix.virasistema.com`**, o registro é fechado e o bridge já vem
registrado como appservice.

### Decisões congeladas no primeiro boot

- **`server_name: matrix.virasistema.com`** — é a identidade permanente do
  homeserver (`@wagner:matrix.virasistema.com`). **Não muda depois** sem
  recomeçar do zero. Se quiser outro, edite `docker-compose.yml`,
  `templates/whatsapp-config.yaml` e `element/config.json` **antes** de
  instalar. `virasistema.com` é do Wagner desde 2026-07-10 (Name.com, DNS
  na Vercel); o subdomínio `matrix.` não precisa de registro DNS público —
  sem federação, o nome é só identidade, e os clientes falam com o
  homeserver por `http://umbrel:8891` na tailnet.
- Sem federação, sem exposição pública: o Synapse fala HTTP puro na porta
  `8891` do host, alcançável pela rede local e pela tailnet
  (`http://umbrel:8891`).

### Segurança

- **Nenhum segredo neste repo.** Os tokens do appservice (`as_token`,
  `hs_token`) são gerados aleatoriamente no próprio aparelho no primeiro
  boot e vivem só em `app-data`. O repo registra o método, nunca o segredo.
- Registro de contas desligado; usuários são criados por comando explícito.
- Enviar mensagem pelo bridge continua sob gate humano (D-022/G-003): este
  stack é a camada de ingestão.

### Instalação (gate humano — não instalar sem decisão do Wagner)

1. **Tornar este repo público** (o Umbrel clona a store por URL, sem
   autenticação).
2. Na UI do umbrelOS: App Store → menu `···` → *Community App Stores* →
   colar `https://github.com/wagnerlsmartins/umbrel-app-store-homelab` →
   *Add* → abrir a store "Home Lab" → instalar **Matrix Zap**.
3. Criar o usuário do Wagner, no Terminal da própria UI do umbrelOS
   (Settings → Advanced → Terminal):

   ```sh
   sudo docker exec -it homelab-matrix-zap_synapse_1 \
     register_new_matrix_user -u wagner -a \
     -c /data/homeserver.yaml http://localhost:8008
   ```

4. Abrir o app (Element, porta 8890), logar como `wagner`.
5. Conversar com `@whatsappbot:matrix.virasistema.com` e mandar `login` —
   o bot devolve o QR para parear **um número descartável primeiro**;
   escanear com o celular do número. Só depois do teste validado é que WMI
   e Campus são pareados (ordem da D-040).

### Plano de validação (primeira instalação)

- [ ] Os três containers sobem e estabilizam (`whatsapp` gera
      `registration.yaml`; `synapse` destrava e escuta em 8891).
- [ ] Element abre em `http://umbrel:8890` e loga.
- [ ] `login` no bot pareia número descartável; mensagem recebida no zap
      aparece como room no Matrix.
- [ ] Reinício do app preserva sessão do WhatsApp e histórico.
- [ ] Depois de validar: **pinar a imagem do bridge** — trocar
      `dock.mau.dev/mautrix/whatsapp:latest` pela tag/digest que funcionou
      (o `latest` é só para a primeira instalação não nascer defasada).

### Estado

**Escrito em 2026-08-28, ainda não instalado em aparelho nenhum.** O
bootstrap (scripts de `scripts/`) foi revisado em código, não observado em
execução. Se o formato do config do mautrix tiver mudado além do upgrade
automático, o log do container `whatsapp` diz o que ajustar no
`app-data/homelab-matrix-zap/data/whatsapp/config.yaml`.

### Limites conhecidos da v0.1

- SQLite no Synapse e no bridge — suficiente para a escala pequena do
  início (avaliação do Wagner em 28/08); migrar para Postgres se crescer.
- Os containers do bridge rodam como root (entrypoint custom); endurecer
  depois da prova.
- Um processo de bridge serve os vários números (logins múltiplos do
  mautrix-whatsapp); isolamento por processo fica para quando houver motivo.
