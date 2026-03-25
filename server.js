require("dotenv").config();

// Handle BigInt serialization in JSON responses.
BigInt.prototype.toJSON = function toJSON() {
  return this.toString();
};

const express = require("express");
const morgan = require("morgan");
const path = require("path");
const cors = require("cors");
const YAML = require("yamljs");
const swaggerUi = require("swagger-ui-express");
const session = require("express-session");

const {
  applySecurityHeaders,
  buildCorsOptions,
  serverEnv,
} = require("./config/server-env");

const app = express();

app.disable("x-powered-by");
app.set("trust proxy", serverEnv.server.trustProxy);

app.use(applySecurityHeaders);
app.use(cors(buildCorsOptions()));
app.use(express.json());

// Prevent browser and intermediary caching in the current app flow.
app.use((req, res, next) => {
  res.set("Cache-Control", "no-store");
  res.set("Pragma", "no-cache");
  res.set("Expires", "0");
  next();
});

const sessionOptions = {
  name: serverEnv.session.cookieName,
  secret: serverEnv.session.secret,
  resave: false,
  saveUninitialized: false,
  cookie: {
    httpOnly: true,
    sameSite: serverEnv.session.sameSite,
    secure: serverEnv.session.secure,
    maxAge: serverEnv.session.cookieMaxAgeMs,
    path: "/",
  },
};

if (serverEnv.isProduction) {
  const PgSession = require("connect-pg-simple")(session);
  const { Pool } = require("pg");
  const sessionPool = new Pool({
    connectionString: process.env.DATABASE_URL || undefined,
  });

  sessionOptions.store = new PgSession({
    pool: sessionPool,
    tableName: "user_sessions",
    createTableIfMissing: true,
  });
}

app.use(session(sessionOptions));

app.use(express.static(path.join(__dirname, "public")));

morgan.token("date_flask", () => {
  const d = new Date();
  const pad = (n) => String(n).padStart(2, "0");
  const mons = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  return `${pad(d.getDate())}/${mons[d.getMonth()]}/${d.getFullYear()} ` +
    `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
});

const flaskFormat =
  ':remote-addr - - [:date_flask] ":method :url HTTP/:http-version" ' +
  ":status :res[content-length]";

app.use(morgan(flaskFormat));

const swaggerDoc = YAML.load(path.join(__dirname, "docs", "swagger.yaml"));
app.use("/docs", swaggerUi.serve, swaggerUi.setup(swaggerDoc));

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

app.use("/api/menu", require("./routes/menu.routes"));
app.use("/api/orders", require("./routes/orders.routes"));
app.use("/api/admin", require("./routes/admin.routes"));
app.use("/api/cart", require("./routes/cart.routes"));
app.use("/api/client", require("./routes/client.routes"));

for (const warning of serverEnv.warnings) {
  console.warn(`[config] ${warning}`);
}

app.listen(serverEnv.server.port, serverEnv.server.host, () => {
  console.log(
    `API Cardapio ouvindo em ${serverEnv.server.displayBaseUrl} ` +
      `(bind ${serverEnv.server.host}:${serverEnv.server.port})`
  );
});
