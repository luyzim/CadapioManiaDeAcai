# Firebase Authentication

## Arquitetura adotada

O projeto passa a usar um fluxo hibrido:

- Firebase Authentication: responsavel por cadastro, validacao de senha e recuperacao por email.
- Prisma/PostgreSQL: continua guardando o perfil do cliente e o relacionamento com pedidos.
- JWT interno da aplicacao: continua protegendo as rotas existentes do cliente sem exigir refatoracao completa do restante do sistema.

## Campos atendidos no cadastro

O cadastro agora valida:

- nome do usuario
- email
- numero de telefone
- senha
- confirmacao de senha

As validacoes aplicadas sao:

- todos os campos obrigatorios preenchidos
- email em formato valido
- senha igual a confirmacao
- senha com pelo menos 6 caracteres, que e o minimo exigido pelo Firebase Auth com email/senha

## Recuperacao de senha

Foi criada a tela `forgot-password.html`, acessivel a partir do login.

Fluxo:

1. usuario informa o email cadastrado
2. o backend valida preenchimento e formato
3. se o usuario existir no Firebase, o sistema envia o email de redefinicao
4. se o usuario ainda for legado (existe no banco, mas nao no Firebase), ele e migrado para o Firebase com uma senha temporaria aleatoria e em seguida recebe o email de redefinicao

## Variaveis de ambiente

Voce pode configurar o Firebase Admin de dois jeitos:

- opcao A: preencher `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL` e `FIREBASE_PRIVATE_KEY`
- opcao B: apontar `FIREBASE_SERVICE_ACCOUNT_PATH` para o arquivo JSON da conta de servico

O backend tambem aceita `GOOGLE_APPLICATION_CREDENTIALS`, que segue o padrao do Google.

Exemplo usando o arquivo JSON baixado do Firebase Console:

```env
FIREBASE_SERVICE_ACCOUNT_PATH="C:\\Users\\aloys\\Downloads\\acaicravinhos-firebase-adminsdk-fbsvc-679eda5e22.json"
```

Variaveis suportadas no `.env`:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`
- `FIREBASE_WEB_API_KEY`
- `FIREBASE_SERVICE_ACCOUNT_PATH`
- `GOOGLE_APPLICATION_CREDENTIALS`

Observacoes:

- `FIREBASE_CLIENT_EMAIL` e `FIREBASE_PRIVATE_KEY` vem da conta de servico do Firebase.
- `FIREBASE_PRIVATE_KEY` deve manter os `\n` escapados quando estiver no `.env`.
- `FIREBASE_WEB_API_KEY` e a chave publica do app Web cadastrada no Firebase e usada nas chamadas REST do Identity Toolkit.
- `FIREBASE_WEB_API_KEY` continua obrigatoria para os endpoints atuais de login por email/senha e de recuperacao de senha do site.
- Para o Flutter, o backend agora aceita a troca do `idToken` do Firebase por um JWT proprio da API.

## Configuracao no Firebase Console

1. crie ou reutilize um projeto no Firebase
2. ative `Authentication`
3. habilite o provedor `Email/Password`
4. em `Project settings > Service accounts`, gere uma chave privada
5. em `Project settings > General`, copie a `Web API Key`

## Impacto na aplicacao

- as credenciais deixam de ficar sob responsabilidade direta do banco local
- o reset de senha passa a seguir o fluxo nativo do Firebase, com envio de email
- o banco local continua necessario para armazenar dados de negocio, como telefone, nome e pedidos
- contas antigas podem ser migradas aos poucos sem quebrar o login atual
- o app Flutter pode autenticar direto no Firebase SDK e depois abrir sessao na API sem enviar senha para o backend

## Diferenca de uso em relacao ao fluxo antigo

Antes:

- senha era validada apenas pelo hash salvo na tabela `clients`
- nao havia processo real de reset por email

Agora:

- senha e validada pelo Firebase Authentication
- redefinicao de senha usa email transacional do Firebase
- a tabela `clients` vira um perfil de negocio vinculado ao `firebase_uid`

## Fluxo recomendado para o Flutter

1. o app Flutter faz login ou cadastro com `firebase_auth`
2. o app chama `user.getIdToken()`
3. o app envia esse token para `POST /api/client/firebase-session`
4. o backend valida o token no Firebase Admin, sincroniza o perfil do cliente e devolve o JWT interno da API
5. o app passa a usar esse JWT nas rotas protegidas com header `Authorization: Bearer <token>`

Payload esperado em `POST /api/client/firebase-session`:

```json
{
  "idToken": "token-gerado-pelo-firebase",
  "name": "Nome opcional do cliente",
  "phone": "(16) 99999-9999"
}
```

Resposta:

```json
{
  "token": "jwt-da-api",
  "client": {
    "id": 1,
    "name": "Nome opcional do cliente",
    "email": "cliente@exemplo.com",
    "phone": "(16) 99999-9999",
    "firebase_uid": "firebase-uid"
  },
  "firebaseSignInProvider": "password"
}
```

## Banco de dados

O model `clients` recebeu:

- `phone`
- `firebase_uid`

E `pass_hash` passou a ser opcional para permitir a transicao do fluxo antigo para o novo.
