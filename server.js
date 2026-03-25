require("dotenv").config();

// Add this line to handle BigInt serialization
BigInt.prototype.toJSON = function() { return this.toString(); };

const express = require("express");
const morgan = require("morgan");
const path = require("path");
const cors = require("cors");
const YAML = require("yamljs");
const swaggerUi = require("swagger-ui-express");

const session = require("express-session");

const app = express();
app.use(cors({ origin: process.env.CORS_ORIGIN || "*" }));
app.use(express.json());

// Prevent browser caching for all responses
app.use((req, res, next) => {
  res.set('Cache-Control', 'no-store');
  next();
});

// Session middleware
// TODO: In production, use a more secure secret and a persistent session store like connect-pg.
app.use(session({
  secret: process.env.SESSION_SECRET || 'a-very-weak-secret-for-dev',
  resave: false,
  saveUninitialized: true,
  cookie: { secure: process.env.NODE_ENV === 'production' } // use secure cookies in production
}));

app.use(express.static(path.join(__dirname, "public")));
app.set("trust proxy", true);

// Log estilo Flask (reaproveitando sua ideia)
morgan.token("date_flask", () => {
  const d = new Date();
  const pad = (n) => String(n).padStart(2, "0");
  const mons = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
  return `${pad(d.getDate())}/${mons[d.getMonth()]}/${d.getFullYear()} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
});
const flaskFormat = ':remote-addr - - [:date_flask] ":method :url HTTP/:http-version" :status :res[content-length]';
app.use(morgan(flaskFormat)); // igual ao padrão que você já usa :contentReference[oaicite:1]{index=1}

// Swagger
const swaggerDoc = YAML.load(path.join(__dirname, "docs", "swagger.yaml"));
app.use("/docs", swaggerUi.serve, swaggerUi.setup(swaggerDoc));

// Rotas principais (mantendo o redirect/home que você usa)


app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "login.html"));
});

app.get("/login", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "login.html"));
});

app.get("/signup", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "signup.html"));
});

app.get("/forgot-password", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "forgot-password.html"));
});

app.get("/home", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "home.html"));
});

app.get("/cardapio", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "menu.html"));
});

app.get("/cart", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "cart.html"));
});

app.get("/carrinho", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "carrinho.html"));
});

app.get("/admin/paid-orders", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "admin_paid_orders.html"));
});

app.get("/admin_delivery.html", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "admin_delivery.html"));
});

app.get("/checkout", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "checkout.html"));
});

app.get("/pedido", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "pedido.html"));
});

app.get("/my-orders", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "my_orders.html"));
});

// Rotas do Cardápio Digital
app.use("/api/menu", require("./routes/menu.routes"));
app.use("/api/orders", require("./routes/orders.routes"));
app.use("/api/admin", require("./routes/admin.routes"));
app.use("/api/cart", require("./routes/cart.routes"));
app.use("/api/client", require("./routes/client.routes"));

const PORT = process.env.PORT || 3104;
const HOST = "0.0.0.0";
app.listen(PORT, HOST, () => {
  console.log(`API Cardápio ouvindo em http://${HOST}:${PORT}`);
});
