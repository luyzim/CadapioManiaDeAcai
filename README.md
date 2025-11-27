Resumo do Projeto:
API e SPA simples para cardápio digital “Açaí da Casa”, servida pelo Express (server.js) com páginas estáticas em public/ e documentação Swagger em /docs (docs/swagger.yaml).
Back-end com PostgreSQL via Prisma (prisma/schema.prisma), logging estilo Flask via morgan, CORS liberado por padrão e sessões de usuário em memória para o carrinho.
Fluxo completo de cliente: cadastro/login, navegação pelo menu, carrinho por sessão, checkout e acompanhamento de pedidos.
Fluxo completo de admin: login JWT, CRUD de categorias/itens, upload de imagens, fila de pedidos, alteração de status e monitor de entregas.
Stack e Arquitetura

Node.js + Express (CommonJS), Prisma Client para Postgres, session store em memória (express-session), uploads com Multer para public/uploads, autenticação JWT com jsonwebtoken e senhas com bcryptjs.
Front-end em HTML/Tailwind (CDN) + JS vanilla; assets em public/img e scripts em public/js.
BigInt serializado para JSON no servidor; cache HTTP desabilitado para respostas.
Principais Funcionalidades

Cardápio: listagem de categorias/itens ativos e detalhe de item com opções (routes/menu.routes.js → /api/menu, /api/menu/items/:id).
Carrinho: armazenado por req.session.id (cookies de sessão) com CRUD completo (routes/cart.routes.js → /api/cart).
Pedidos do cliente: criação transacional com cálculo de total, histórico de status e confirmação de entrega (routes/orders.routes.js → /api/orders, /api/orders/:id, /api/orders/:id/confirm-delivery).
Conta do cliente: signup/login com JWT e listagem dos próprios pedidos (routes/client.routes.js → /api/client/signup, /api/client/login, /api/client/my-orders).
Admin: login JWT, CRUD de categorias/itens, upload de imagem, listagem e alteração de status de pedidos, filas de pagos e de entrega (routes/admin.routes.js → /api/admin/*).
Páginas: public/login.html, signup.html, home.html/menu.html, carrinho.html/checkout.html, my_orders.html + pedido.html (tracking), admin.html + painéis admin_paid_orders.html e admin_delivery.html.
Banco de Dados (Prisma)

Entidades: clients, admins, categories, items (com item_options), cart (session_id + item), orders (cliente opcional, endereço, status enum), order_items e order_status_history.
Status de pedido enum: Recebido, Em_preparo (mapeado a “Em preparo”), Pronto, Entregue.
Migrations em prisma/migrations/ e seed com itens/categorias exemplo em prisma/seed.js.
Autenticação e Sessões

Clientes: header x-authorization: Bearer <token>; payload inclui id, email, name. Token emitido em /api/client/login e /api/client/signup.
Admins: header Authorization: Bearer <token>; token emitido em /api/admin/login.
Carrinho: cookie de sessão Express; em produção recomenda-se SESSION_SECRET forte e store persistente (ex.: Redis).
JWT segredo definido em JWT_SECRET no .env; cookies marcados secure quando NODE_ENV=production.
Ambiente e Execução

Pré-requisitos: Node.js, PostgreSQL acessível e variável DATABASE_URL configurada.
.env (já existe) define PORT, JWT_SECRET, SESSION_SECRET (opcional), CORS_ORIGIN, credenciais do Postgres e DATABASE_URL.
Setup típico: npm install; npx prisma migrate deploy (ou prisma migrate dev em dev); npm run prisma:seed; opcional node scripts/create-admin.js para criar/atualizar admin; subir com npm start (porta default 3104/variável PORT).
Acessos: frontend em http://localhost:PORT/ (login), /cardapio, /carrinho, /checkout, /my-orders; painel admin em /admin.html; Swagger em /docs.
APIs-chave (resumo)

Público: GET /api/menu, GET /api/menu/items/:id.
Carrinho (sessão): GET/POST/DELETE /api/cart, PUT/DELETE /api/cart/:itemId.
Cliente JWT: POST /api/orders, GET /api/orders/:id, POST /api/orders/:id/confirm-delivery, GET /api/client/my-orders.
Autenticação: POST /api/client/signup|login, POST /api/admin/login.
Admin protegido: POST/PUT/DELETE /api/admin/categories|items, PATCH /api/admin/orders/:id/status, GET /api/admin/orders, GET /api/admin/paid-orders, GET /api/admin/delivery-orders, POST /api/admin/upload.
Scripts Úteis

npm run prisma:seed popula categorias/itens exemplo.
node scripts/create-admin.js cria/atualiza admin padrão (edite email/senha antes de rodar).
