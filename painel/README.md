# Painel do SWX2

Recebe os avisos anônimos do SWX2 e mostra quem está jogando e quais jogos. Um único servidor Node 24 sem dependências (`node:http` + `node:sqlite`), com o banco em `/data/swx2.db`.

O SWX2 envia `POST /api/ping` a cada 5 minutos e sempre que um jogo abre ou fecha:

```json
{ "id": "uuid aleatório da instalação", "v": "1.0.7", "game": "Crash Twinsanity", "serial": "SLES-52568" }
```

O painel (`/`) e os dados (`/api/stats`) pedem usuário e senha. Depois de 10 senhas erradas por IP (ou 100 no total) em um minuto, o login fica bloqueado até o minuto acabar. O IP não é gravado. Avisos com mais de 90 dias são apagados.

O envio é **opcional**: o SWX2 pergunta na primeira abertura e só manda avisos de quem aceitou (menu "..." da biblioteca para mudar).

`TRUST_CF=0` faz o limite por IP ignorar o cabeçalho `cf-connecting-ip` e usar o `x-forwarded-for` do proxy reverso. Use quando o domínio **não** estiver com o proxy da Cloudflare ligado: sem a Cloudflare na frente, qualquer um pode falsificar esse cabeçalho.

## Deploy no Dokploy

1. **Create Service → Application**.
2. **Provider:** GitHub, repositório `Swairovsk-dev/SWX2`, branch `main`.
   **Build Type:** Dockerfile. **Build Path / Docker Context:** `painel`. **Dockerfile:** `painel/Dockerfile`.
3. **Environment:**
   ```
   ADMIN_PASSWORD=uma-senha-forte
   ADMIN_USER=admin
   ```
4. **Advanced → Volumes:** volume `swx2-painel-data` montado em `/data`, para o banco sobreviver aos deploys.
5. **Domains:** host `jogar.swairovsk.site`, container port `3000`, HTTPS ligado (Let's Encrypt).
6. **Deploy**. Teste: `https://jogar.swairovsk.site/health` responde `ok`.

## Cloudflare

DNS → **Add record**: tipo `A`, nome `jogar`, conteúdo = IP do servidor do Dokploy.

- Para o Let's Encrypt do Dokploy emitir o certificado, deixe primeiro **DNS only** (nuvem cinza). Depois de ter HTTPS funcionando, pode ligar o **Proxied** (nuvem laranja), com SSL/TLS em **Full (strict)**.

## Testar localmente

```bash
ADMIN_PASSWORD=teste DATA_DIR=./dados-teste PORT=3000 node server.mjs
```

Para o SWX2 mandar para o servidor local, abra-o com `SWX2_TELEMETRY_URL=http://127.0.0.1:3000/api/ping`.
