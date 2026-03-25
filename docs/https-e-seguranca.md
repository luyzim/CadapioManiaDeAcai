# HTTPS, cookies e seguranca

## Recomendacao pratica

Para este projeto, o fluxo recomendado fica assim:

- Desenvolvimento local: backend em HTTP direto no Node/Express.
- Staging e producao: HTTPS terminado na borda, com Nginx na frente do Node.
- Flutter: continua com fallback local em `http://localhost` ou `http://10.0.2.2`, mas em staging/producao deve receber `API_BASE_URL=https://...`.

Esse desenho mantem o ambiente local simples e evita configurar TLS caseiro para cada celular, enquanto deixa o deploy pronto para HTTPS real.

## O que foi ajustado no backend

O servidor agora:

- le as configuracoes de runtime a partir de `config/server-env.js`
- padroniza `HOST`, `PORT`, `PUBLIC_BASE_URL`, `TRUST_PROXY`, `CORS_ORIGIN` e variaveis de cookie
- envia headers de seguranca de baixo risco
- so envia HSTS quando a requisicao realmente chega por HTTPS
- deixou `saveUninitialized=false` na sessao
- inicializa a sessao anonima apenas nas rotas de carrinho

Cookies de sessao agora usam:

- `httpOnly=true`
- `sameSite=lax` por padrao
- `secure` controlado por `SESSION_COOKIE_SECURE`
- `maxAge` controlado por `SESSION_COOKIE_MAX_AGE_MS`

## Variaveis de ambiente

As principais variaveis novas ou padronizadas sao:

- `HOST`: endereco de bind do Node. Em dev, `0.0.0.0` e pratico.
- `PORT`: porta HTTP interna do Node.
- `PUBLIC_BASE_URL`: URL publica do backend. Exemplo: `https://api.seudominio.com`.
- `TRUST_PROXY`: define se o Express deve confiar nos headers do proxy. Em dev, `false`. Com Nginx local, `loopback`.
- `CORS_ORIGIN`: `*` em dev ou lista separada por virgula em producao.
- `SESSION_COOKIE_NAME`: nome do cookie de sessao.
- `SESSION_COOKIE_MAX_AGE_MS`: duracao da sessao em milissegundos.
- `SESSION_COOKIE_SAME_SITE`: `lax`, `strict` ou `none`.
- `SESSION_COOKIE_SECURE`: `false` em HTTP local, `true` em HTTPS.
- `SECURITY_HEADERS_ENABLED`: liga ou desliga os headers de seguranca.
- `HSTS_ENABLED`: ativa `Strict-Transport-Security`.
- `HSTS_MAX_AGE_SECONDS`: tempo de HSTS.
- `HSTS_INCLUDE_SUBDOMAINS`: inclui subdominios no HSTS.

## Perfil recomendado para desenvolvimento local

Exemplo de backend local:

```env
NODE_ENV=development
HOST=0.0.0.0
PORT=3110
TRUST_PROXY=false
PUBLIC_BASE_URL=
CORS_ORIGIN=*
SESSION_COOKIE_SECURE=false
HSTS_ENABLED=false
```

Exemplo de execucao do Flutter web:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 --dart-define=API_BASE_URL=http://192.168.0.15:3110
```

Exemplo de execucao do app Flutter no celular:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.15:3110
```

## Perfil recomendado para staging ou producao

Exemplo de backend atras de Nginx:

```env
NODE_ENV=production
HOST=127.0.0.1
PORT=3110
PUBLIC_BASE_URL=https://api.seudominio.com
TRUST_PROXY=loopback
CORS_ORIGIN=https://app.seudominio.com,https://admin.seudominio.com
SESSION_SECRET=troque-por-um-valor-forte
SESSION_COOKIE_SECURE=true
SESSION_COOKIE_SAME_SITE=lax
HSTS_ENABLED=true
```

Nessa configuracao:

- o Node continua em HTTP interno
- o Nginx atende `443`
- o Nginx faz o redirect de `80` para `443`
- o Express reconhece a requisicao como segura por causa do `X-Forwarded-Proto`

## Exemplo minimo de Nginx

```nginx
server {
    listen 80;
    server_name api.seudominio.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.seudominio.com;

    ssl_certificate     /etc/letsencrypt/live/api.seudominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.seudominio.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:3110;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
    }
}
```

## Observacoes importantes

- HTTP local continua sendo o caminho ideal para desenvolvimento rapido.
- HTTPS local em celular real e possivel, mas costuma exigir certificado confiavel no aparelho ou tunel HTTPS.
- Em producao, nao exponha o Node direto na internet se o objetivo for operar com HTTPS.
- Ainda nao foi aplicado CSP neste projeto porque as paginas publicas usam scripts inline e recursos externos. Esse pode ser o proximo endurecimento, mas precisa ser feito com cuidado para nao quebrar as telas.
