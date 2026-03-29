# PraticaExistencionista

Sistema de cardapio digital e pedidos para acai, com:

- backend em Node.js + Express + Prisma + PostgreSQL
- autenticacao de clientes com Firebase Authentication
- JWT interno para proteger rotas de cliente e admin
- frontend web estatico em `public/`
- aplicativo Flutter em `mobile/` para web, desktop e mobile

Hoje o projeto convive com dois frontends:

- `public/`: paginas HTML servidas pelo Express
- `mobile/`: app Flutter com painel admin, fluxo de login, pedidos e checkout

## Visao Geral

O backend centraliza:

- cardapio
- carrinho por sessao
- pedidos
- autenticacao de cliente
- autenticacao de admin
- painel administrativo
- upload de imagens
- documentacao Swagger em `/docs`

O app Flutter consome a mesma API e hoje cobre:

- login e cadastro de cliente
- home, cardapio, checkout e detalhes do pedido
- painel admin com pedidos, filas e CRUD de cardapio

## Stack

### Backend

- Node.js
- Express
- Prisma Client
- PostgreSQL
- `express-session`
- `jsonwebtoken`
- `bcryptjs`
- `multer`
- `swagger-ui-express`

### Autenticacao

- Firebase Admin SDK no backend
- Firebase Authentication no app Flutter
- JWT proprio da aplicacao para autorizacao de cliente e admin

### Frontend

- paginas HTML estaticas em `public/`
- Flutter em `mobile/`
- `provider`
- `http`
- `shared_preferences`

## Estrutura Do Repositorio

```text
.
|- config/                # Configuracao de runtime, proxy, cookies e seguranca
|- docs/                  # Documentacao complementar
|- mobile/                # App Flutter
|- prisma/                # Schema, migrations e seed
|- public/                # Frontend web estatico servido pelo Express
|- routes/                # Rotas da API
|- scripts/               # Scripts auxiliares
|- services/              # JWT, Firebase e servicos compartilhados
|- .env.example           # Modelo de variaveis de ambiente
|- package.json           # Scripts do backend
|- server.js              # Entrada principal do servidor
```

## Funcionalidades

### Cliente

- cadastro com nome, email, telefone, senha e confirmacao
- login
- reset de senha via Firebase
- navegacao pelo cardapio
- carrinho persistido por sessao
- checkout
- consulta dos proprios pedidos
- confirmacao de entrega quando o pedido estiver `Pronto`

### Admin

- login com JWT
- CRUD de categorias
- CRUD de itens do cardapio
- upload de imagem
- dashboard de pedidos
- alteracao de status
- fila de pedidos ativos
- fila de pedidos prontos para entrega

### Cardapio

- categorias
- itens ativos e inativos
- opcoes por item
- preco base em centavos
- imagens

## Arquitetura

### Backend

O servidor principal esta em `server.js` e:

- carrega `.env`
- configura `trust proxy`
- aplica headers de seguranca
- aplica CORS
- registra sessoes
- serve arquivos estaticos de `public/`
- expoe Swagger em `/docs`
- monta as rotas:
  - `/api/menu`
  - `/api/cart`
  - `/api/orders`
  - `/api/client`
  - `/api/admin`

### Banco

O schema Prisma esta em `prisma/schema.prisma`.

Entidades principais:

- `admins`
- `clients`
- `categories`
- `items`
- `item_options`
- `cart`
- `orders`
- `order_items`
- `order_status_history`

Status de pedido:

- `Recebido`
- `Em preparo`
- `Pronto`
- `Entregue`

### Autenticacao E Autorizacao

O projeto usa tres mecanismos em paralelo:

- Firebase Authentication para credenciais do cliente
- JWT da aplicacao para proteger rotas
- sessao Express para carrinho anonimo

Roles no JWT:

- `admin`
- `client`

Middlewares principais:

- `requireAdmin`
- `requireClient`

Arquivo central:

- `services/jwt-auth.js`

## Frontends Disponiveis

### 1. Web estatico servido pelo Express

Paginas principais:

- `/` e `/login`
- `/signup`
- `/forgot-password`
- `/home`
- `/cardapio`
- `/cart`
- `/carrinho`
- `/checkout`
- `/pedido`
- `/my-orders`
- `/admin.html`
- `/admin/paid-orders`
- `/admin_delivery.html`

### 2. App Flutter em `mobile/`

O app Flutter inicializa Firebase em `mobile/lib/main.dart` e usa:

- `firebase_options.dart`
- `AuthService`
- `SessionController`
- `AdminSessionController`

Paginas principais:

- login
- cadastro
- forgot password
- home
- checkout
- detalhes do pedido
- admin

O painel admin Flutter inclui uma aba de cardapio com:

- criacao e edicao de categorias
- criacao e edicao de itens
- exclusao
- ativacao e desativacao

## Como Rodar Localmente

### Pre-requisitos

- Node.js 18 ou superior
- PostgreSQL
- projeto Firebase configurado
- Flutter SDK para rodar `mobile/`

### 1. Instale dependencias

Backend:

```bash
npm install
```

Flutter:

```bash
cd mobile
flutter pub get
cd ..
```

### 2. Configure o ambiente

Copie `.env.example` para `.env` e preencha os valores necessarios.

Exemplo minimo para desenvolvimento local:

```env
NODE_ENV=development
HOST=0.0.0.0
PORT=3110
TRUST_PROXY=false
PUBLIC_BASE_URL=
CORS_ORIGIN=*
SESSION_COOKIE_SECURE=false
HSTS_ENABLED=false
DATABASE_URL=postgresql://postgres:senha@localhost:5432/cardapio
JWT_SECRET=troque-por-uma-chave-forte
FIREBASE_WEB_API_KEY=sua-chave-web
FIREBASE_SERVICE_ACCOUNT_PATH=C:\caminho\firebase-service-account.json
```

### 3. Prepare o banco

Gerar client Prisma:

```bash
npx prisma generate
```

Aplicar migrations em desenvolvimento:

```bash
npx prisma migrate dev
```

Popular dados iniciais:

```bash
npm run prisma:seed
```

### 4. Suba o backend

```bash
npm start
```

O backend sobe por padrao em:

```text
http://localhost:3110
```

Se `HOST=0.0.0.0`, ele tambem fica acessivel pelo IP da maquina na rede local.

### 5. Rode o app Flutter

#### Flutter web no mesmo PC

```bash
cd mobile
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Abra:

```text
http://localhost:8080
```

#### Flutter web em outro aparelho da mesma rede

Abra:

```text
http://IP_DO_PC:8080
```

O app web resolve automaticamente o backend para:

```text
http://IP_DO_PC:3110
```

Se quiser sobrescrever manualmente:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 --dart-define=API_BASE_URL=http://192.168.0.15:3110
```

#### Android emulador

Sem override, o app usa:

```text
http://10.0.2.2:3110
```

Ou com override:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.15:3110
```

#### Celular fisico

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.15:3110
```

## Variaveis De Ambiente

As variaveis documentadas abaixo refletem `.env.example`.

| Variavel | Obrigatoria | Uso |
| --- | --- | --- |
| `NODE_ENV` | sim | `development` ou `production` |
| `HOST` | sim | endereco de bind do Node |
| `PORT` | sim | porta HTTP interna do backend |
| `PUBLIC_BASE_URL` | nao | URL publica usada em logs e deploy |
| `TRUST_PROXY` | nao | `false`, `true`, `loopback` ou numero de hops |
| `CORS_ORIGIN` | nao | `*` em dev ou lista de origens em prod |
| `SESSION_SECRET` | recomendado | segredo da sessao Express |
| `SESSION_COOKIE_NAME` | nao | nome do cookie de sessao |
| `SESSION_COOKIE_MAX_AGE_MS` | nao | duracao da sessao |
| `SESSION_COOKIE_SAME_SITE` | nao | `lax`, `strict` ou `none` |
| `SESSION_COOKIE_SECURE` | nao | `false` em HTTP local, `true` em HTTPS |
| `SECURITY_HEADERS_ENABLED` | nao | habilita headers de seguranca |
| `HSTS_ENABLED` | nao | habilita HSTS |
| `HSTS_MAX_AGE_SECONDS` | nao | max-age do HSTS |
| `HSTS_INCLUDE_SUBDOMAINS` | nao | inclui subdominios no HSTS |
| `PGHOST` | opcional | host do Postgres |
| `PGPORT` | opcional | porta do Postgres |
| `PGDATABASE` | opcional | nome do banco |
| `PGUSER` | opcional | usuario do banco |
| `PGPASSWORD` | opcional | senha do banco |
| `DATABASE_URL` | sim | conexao principal do Prisma |
| `JWT_SECRET` | sim | segredo do JWT de cliente e admin |
| `FIREBASE_PROJECT_ID` | depende | opcao A de config do Firebase Admin |
| `FIREBASE_CLIENT_EMAIL` | depende | opcao A de config do Firebase Admin |
| `FIREBASE_PRIVATE_KEY` | depende | opcao A de config do Firebase Admin |
| `FIREBASE_WEB_API_KEY` | sim | usada nas chamadas REST do Firebase Auth |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | depende | opcao B de config do Firebase Admin |
| `GOOGLE_APPLICATION_CREDENTIALS` | depende | alternativa padrao do Google |

Observacao:

- para o Firebase Admin, use ou o trio `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`, ou `FIREBASE_SERVICE_ACCOUNT_PATH`

## Firebase

O projeto usa um fluxo hibrido:

- Firebase Authentication para senha, login e reset
- PostgreSQL para perfil e pedidos
- JWT interno da API para rotas protegidas

Fluxos suportados:

- `POST /api/client/signup`
- `POST /api/client/login`
- `POST /api/client/firebase-session`
- `POST /api/client/forgot-password`

Arquivos importantes:

- `services/firebase-auth.js`
- `routes/client.routes.js`
- `mobile/lib/firebase_options.dart`
- `docs/firebase-auth.md`

Para o Firebase funcionar, confirme:

- provider `Email/Password` habilitado no console
- `FIREBASE_WEB_API_KEY` preenchido
- conta de servico valida no backend
- dominio `localhost` autorizado quando usar web local

## API

O Swagger esta disponivel em:

```text
http://localhost:3110/docs
```

O arquivo fonte da especificacao esta em:

- `docs/swagger.yaml`

Observacao:

- o Swagger cobre o nucleo da API, mas o codigo das rotas continua sendo a fonte de verdade para os endpoints mais novos

## Resumo Dos Endpoints

### Menu

- `GET /api/menu`
- `GET /api/menu/items/:id`

### Carrinho por sessao

- `GET /api/cart`
- `POST /api/cart`
- `PUT /api/cart/:itemId`
- `DELETE /api/cart/:itemId`
- `DELETE /api/cart`

### Cliente

- `POST /api/client/signup`
- `POST /api/client/login`
- `POST /api/client/firebase-session`
- `POST /api/client/forgot-password`
- `GET /api/client/my-orders`

### Pedidos

- `POST /api/orders`
- `GET /api/orders/:id`
- `POST /api/orders/:id/confirm-delivery`

### Admin

- `POST /api/admin/login`
- `GET /api/admin/categories`
- `POST /api/admin/categories`
- `PUT /api/admin/categories/:id`
- `DELETE /api/admin/categories/:id`
- `GET /api/admin/items`
- `POST /api/admin/items`
- `PUT /api/admin/items/:id`
- `DELETE /api/admin/items/:id`
- `POST /api/admin/upload`
- `GET /api/admin/orders`
- `PATCH /api/admin/orders/:id/status`
- `GET /api/admin/paid-orders`
- `GET /api/admin/delivery-orders`

## Banco De Dados

### Seed

O seed em `prisma/seed.js` cria exemplos de:

- categorias de acai e bebidas
- itens iniciais
- opcoes de tamanho para acai

Execute:

```bash
npm run prisma:seed
```

### Migrations

As migrations vivem em:

- `prisma/migrations/`

Em producao, prefira:

```bash
npx prisma migrate deploy
```

## Criacao De Admin

Existe um script em:

- `scripts/create-admin.js`

Antes de rodar:

- edite o email
- edite a senha

O arquivo hoje usa valores hardcoded, entao vale revisar antes de executar.

Para executar do jeito mais seguro com o caminho atual do `.env`, rode a partir da pasta `scripts`:

```bash
cd scripts
node create-admin.js
cd ..
```

## Seguranca E HTTPS

Recomendacao atual:

- desenvolvimento local: HTTP direto no Node
- staging e producao: HTTPS na borda com Nginx/proxy

O backend ja foi preparado para:

- `trust proxy`
- headers de seguranca
- HSTS condicional
- cookies configuraveis
- sessao persistente em PostgreSQL em producao

Documentacao complementar:

- [docs/https-e-seguranca.md](docs/https-e-seguranca.md)

## Scripts Uteis

Backend:

```bash
npm start
npm run prisma:seed
```

Prisma:

```bash
npx prisma generate
npx prisma migrate dev
npx prisma migrate deploy
```

Flutter:

```bash
cd mobile
flutter pub get
flutter analyze --no-pub
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

## Troubleshooting

### 1. Login/cadastro nao funciona no Flutter web em `:8080`

Verifique se:

- o backend esta rodando em `:3110`
- voce abriu o app pelo host correto
- o firewall do Windows nao bloqueou a porta
- `FIREBASE_WEB_API_KEY` esta configurada

Hoje o app web resolve automaticamente o host atual para a API. Se precisar, use `--dart-define=API_BASE_URL=http://IP_DO_PC:3110`.

### 2. O backend sobe, mas o Firebase falha

Confira:

- `FIREBASE_WEB_API_KEY`
- conta de servico valida
- `FIREBASE_SERVICE_ACCOUNT_PATH`
- provider `Email/Password` habilitado no Firebase Console

### 3. Carrinho ou sessao falha em producao

Confira:

- `SESSION_SECRET`
- `SESSION_COOKIE_SECURE=true`
- `TRUST_PROXY`
- Nginx enviando `X-Forwarded-Proto`

### 4. App Flutter no celular nao acessa a API

Confira:

- backend ouvindo em `0.0.0.0`
- celular e PC na mesma rede
- porta `3110` liberada no firewall
- `API_BASE_URL` apontando para o IP da maquina

## Documentacao Complementar

- [docs/firebase-auth.md](docs/firebase-auth.md)
- [docs/https-e-seguranca.md](docs/https-e-seguranca.md)
- [docs/swagger.yaml](docs/swagger.yaml)

## Fonte De Verdade

Para entender o comportamento atual do sistema, os arquivos mais importantes sao:

- `server.js`
- `config/server-env.js`
- `routes/admin.routes.js`
- `routes/client.routes.js`
- `routes/orders.routes.js`
- `routes/menu.routes.js`
- `routes/cart.routes.js`
- `services/firebase-auth.js`
- `services/jwt-auth.js`
- `prisma/schema.prisma`
- `mobile/lib/app/mania_de_acai_app.dart`
- `mobile/lib/core/config/api_config.dart`
