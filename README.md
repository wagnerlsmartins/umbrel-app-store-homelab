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

4. Abrir o Element e logar como `wagner`. **Atenção: o Element exige
   contexto seguro (HTTPS)** — em `http://` ele trava em "Browser
   insuportado". O acesso é pelo Tailscale Serve, configurado no aparelho:
   - Element: `https://umbrel.tail63b303.ts.net:9443`
   - Synapse: `https://umbrel.tail63b303.ts.net:9444` (base_url do Element
     e endpoint para workers/clientes)
   As portas 8890/8891 em HTTP seguem existindo para debug e para tráfego
   servidor-a-servidor na tailnet.
5. Conversar com `@whatsappbot:matrix.virasistema.com` e mandar `login` —
   o bot devolve o QR; escanear com o celular do número. Ordem decidida
   pelo Wagner em 2026-08-28: **o número da WMI é o próprio teste** (linha
   recém-ativada, sem histórico, custo de perda mínimo); validado, entra o
   Campus. Sem número descartável dedicado.

### Plano de validação (primeira instalação)

- [x] Os três containers sobem e estabilizam — validado em 2026-08-28, na
      primeira instalação real, depois de um ajuste: o bridge gerava o
      `registration.yaml` como root 600 e o Synapse (uid 1000) não lia
      (crash loop). Corrigido no `whatsapp-start.sh`.
- [x] Element abre e loga — validado em 2026-08-28 via
      `https://umbrel.tail63b303.ts.net:9443`; o Wagner conversou com o
      `@whatsappbot` e o `help` respondeu (appservice funcional nos dois
      sentidos).
- [ ] `login` no bot pareia número descartável; mensagem recebida no zap
      aparece como room no Matrix.
- [ ] Reinício do app preserva sessão do WhatsApp e histórico.
- [ ] Depois de validar: **pinar a imagem do bridge** — trocar
      `dock.mau.dev/mautrix/whatsapp:latest` pela tag/digest que funcionou
      (o `latest` é só para a primeira instalação não nascer defasada).

### Estado

**Instalado no Umbrel Home em 2026-08-28.** Bootstrap observado em
execução: config do mautrix gerado e expandido pelos defaults, registration
emitido, appservice conectado (o perfil de `@whatsappbot` responde no
homeserver). Falta a validação com número descartável.

### Ponte Signal, só leitura (v0.2.0, 2026-10-31)

Toda a comunicação da PR Capital (mesa, parceiros, clientes) corre no
Signal, na conta pessoal do Wagner, que é 100% PR (dito por ele em 31/10).
A ponte `mautrix-signal` entra neste app para **absorver** esses grupos no
Matrix, sem agente falando em nome dele. O servidor gerenciado só da PR
(etke.cc) fica para depois: aqui é a gambiarra que agiliza, e a migração é
re-parear lá (o pareamento é da ponte, não do servidor).

**Como fica só leitura, por mecanismo e não por disciplina:**

- `relay.enabled: false` no template: mensagem de outro usuário do Matrix
  numa sala-portal do Signal não é entregue, nem com `set-relay`.
- Só `@wagner` tem login na ponte. O que **ele** escrever numa sala-portal
  pelo Element sai no Signal como ele; é a conta dele, não é o bot.
- O leitor é uma conta nova, **`@leitor-pr`**, só convidada às salas, sem
  login na ponte e sem relação com o `@agente` da WMI, para o Vigia do
  gateway (que lê as salas do `@agente`) nunca ver conversa da PR.

**Pareamento (gate humano: o Wagner, no teclado dele):**

1. Atualizar o app pela UI do umbrelOS (a store mostra 0.2.0). **Fato
   (31/10/2026): o update do Umbrel troca o `docker-compose.yml` mas não
   copia `templates/` nem `scripts/` novos para `app-data`**; o `signal`
   fica em `Restarting` sem o seu script, e o Synapse sobe com o
   `synapse-start.sh` antigo. Copiar à mão, pelo SSH, e reiniciar os dois:

   ```sh
   cd ~/umbrel/app-data/homelab-matrix-zap
   B=https://raw.githubusercontent.com/wagnerlsmartins/umbrel-app-store-homelab/main/homelab-matrix-zap
   curl -fsSL $B/templates/signal-config.yaml -o templates/signal-config.yaml
   curl -fsSL $B/scripts/signal-start.sh -o scripts/signal-start.sh
   curl -fsSL $B/scripts/synapse-start.sh -o scripts/synapse-start.sh
   chmod +x scripts/*.sh
   sudo docker restart homelab-matrix-zap_signal_1 && sleep 20
   sudo docker restart homelab-matrix-zap_synapse_1
   ```

   O `signal` gera o registration e o Synapse volta com a linha nova no
   `homeserver.yaml`. A ponte do WhatsApp não é tocada (sessão em
   `data/whatsapp`). Validado em 31/10: `@signalbot` e `@leitor-pr` com
   perfil no homeserver.

   **Porta 8890.** O OPDS do acervo (`opds.service`, home-lab) nasceu na
   mesma porta do Element; o update recriou o `app_proxy` com ela ocupada e
   o `:9443` passou a mostrar o catálogo. Resolvido movendo o OPDS para
   `8892` (`infra/servicos/opds-do-acervo.md` do home-lab) e reiniciando o
   `app_proxy`. Antes de escolher porta para um app novo, `sudo ss -ltnp`
   no aparelho, não a lista de um documento antigo.
2. Criar o leitor, no mesmo Terminal:

   ```sh
   sudo docker exec -it homelab-matrix-zap_synapse_1 \
     register_new_matrix_user -u leitor-pr --no-admin \
     -c /data/homeserver.yaml http://localhost:8008
   ```

   O token de acesso do `@leitor-pr` vai para `.private/credentials/matrix/`
   do home-lab, nunca para repo.
3. No Element, como `@wagner`, abrir DM com `@signalbot:matrix.virasistema.com`
   e mandar `login qr`. No iPhone: Signal → Ajustes → Dispositivos
   conectados → Conectar novo dispositivo → escanear. O aparelho aparece
   como "mautrix-signal" na lista; só o Wagner vê essa lista, contato nenhum.
4. Esperar as salas-portal nascerem (uma por grupo e por conversa). O
   histórico **anterior** ao pareamento não vem: o Signal entrega a
   dispositivo conectado só a partir do pareamento (a verificar se a versão
   atual da ponte aproveita a transferência de histórico que o Signal faz
   para aparelho novo; não contar com isso).
5. Convidar `@leitor-pr` às salas que a PR quer absorver (todas, segundo o
   Wagner). O convite é a lista de permissão: sala sem o leitor não é lida.

**Quando quiser que um agente envie** (passo explícito e reversível):
`relay.enabled: true` no config vivo (`data/signal/config.yaml`), reiniciar
o contêiner, e `!signal set-relay` **na sala**, dado pelo `@wagner`. Igual ao
WhatsApp: sala não marcada continua inalcançável. A mensagem sai pela conta
dele, com o nome de quem escreveu na frente; antes de ligar, decidir se isso
serve num grupo de cliente.

**Riscos que esta versão não cobre:** a conversa da PR passa a morar em
claro no Synapse da WMI até a migração (contraria a separação proposta na
`base/11` da PR; decisão do Wagner em 31/10, temporária); anexo de
contraparte é baixado pela ponte para o servidor (a regra de abrir anexo em
ambiente isolado segue valendo para quem abre); perder o iPhone ou trocar de
número derruba o pareamento (re-parear).

### Limites conhecidos da v0.1

- SQLite no Synapse e no bridge — suficiente para a escala pequena do
  início (avaliação do Wagner em 28/08); migrar para Postgres se crescer.
- Os containers do bridge rodam como root (entrypoint custom); endurecer
  depois da prova.
- Um processo de bridge serve os vários números (logins múltiplos do
  mautrix-whatsapp); isolamento por processo fica para quando houver motivo.
