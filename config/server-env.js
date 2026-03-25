const DAY_IN_MS = 24 * 60 * 60 * 1000;

function normalizeString(value) {
  if (value == null) {
    return "";
  }

  return String(value).trim();
}

function parseBoolean(value, fallback) {
  const normalized = normalizeString(value).toLowerCase();

  if (!normalized) {
    return fallback;
  }

  if (["1", "true", "yes", "on"].includes(normalized)) {
    return true;
  }

  if (["0", "false", "no", "off"].includes(normalized)) {
    return false;
  }

  return fallback;
}

function parseInteger(value, fallback) {
  const normalized = normalizeString(value);

  if (!normalized) {
    return fallback;
  }

  const parsed = Number.parseInt(normalized, 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function parseSameSite(value, fallback) {
  const normalized = normalizeString(value).toLowerCase();

  if (["lax", "strict", "none"].includes(normalized)) {
    return normalized;
  }

  return fallback;
}

function parseList(value) {
  return normalizeString(value)
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function normalizeUrl(value) {
  return normalizeString(value).replace(/\/+$/, "");
}

function parseTrustProxy(value, fallback) {
  const normalized = normalizeString(value);

  if (!normalized) {
    return fallback;
  }

  const lowered = normalized.toLowerCase();
  if (["true", "yes", "on"].includes(lowered)) {
    return true;
  }

  if (["false", "no", "off"].includes(lowered)) {
    return false;
  }

  if (/^\d+$/.test(normalized)) {
    return Number.parseInt(normalized, 10);
  }

  return normalized;
}

const nodeEnv = normalizeString(process.env.NODE_ENV) || "development";
const isProduction = nodeEnv === "production";
const bindHost = normalizeString(process.env.HOST) || "0.0.0.0";
const port = parseInteger(process.env.PORT, 3110);
const publicBaseUrl = normalizeUrl(process.env.PUBLIC_BASE_URL);
const trustProxy = parseTrustProxy(
  process.env.TRUST_PROXY,
  isProduction ? "loopback" : false
);

const rawCorsOrigin =
  normalizeString(process.env.CORS_ORIGIN) ||
  (isProduction && publicBaseUrl ? publicBaseUrl : "*");

const allowAnyCorsOrigin = rawCorsOrigin === "*";
const allowedCorsOrigins = allowAnyCorsOrigin ? "*" : parseList(rawCorsOrigin);

const usedSessionSecretFallback = !normalizeString(process.env.SESSION_SECRET);
const sessionSecret =
  normalizeString(process.env.SESSION_SECRET) ||
  "a-very-weak-secret-for-dev";

const sessionConfig = {
  secret: sessionSecret,
  cookieName:
    normalizeString(process.env.SESSION_COOKIE_NAME) ||
    "praticaexistencionista.sid",
  cookieMaxAgeMs: parseInteger(
    process.env.SESSION_COOKIE_MAX_AGE_MS,
    7 * DAY_IN_MS
  ),
  sameSite: parseSameSite(process.env.SESSION_COOKIE_SAME_SITE, "lax"),
  secure: parseBoolean(process.env.SESSION_COOKIE_SECURE, isProduction),
};

const securityConfig = {
  headersEnabled: parseBoolean(process.env.SECURITY_HEADERS_ENABLED, true),
  hstsEnabled: parseBoolean(process.env.HSTS_ENABLED, isProduction),
  hstsMaxAgeSeconds: parseInteger(
    process.env.HSTS_MAX_AGE_SECONDS,
    180 * 24 * 60 * 60
  ),
  hstsIncludeSubDomains: parseBoolean(
    process.env.HSTS_INCLUDE_SUBDOMAINS,
    true
  ),
};

const warnings = [];

if (isProduction && usedSessionSecretFallback) {
  warnings.push(
    "SESSION_SECRET nao definido; o servidor esta usando o fallback de desenvolvimento."
  );
}

if (isProduction && !publicBaseUrl) {
  warnings.push(
    "PUBLIC_BASE_URL nao definido; configure a URL publica HTTPS do backend para facilitar logs e deploy."
  );
}

if (isProduction && allowAnyCorsOrigin) {
  warnings.push(
    "CORS_ORIGIN esta liberado para qualquer origem. Restrinja esse valor em producao."
  );
}

function buildCorsOptions() {
  if (allowAnyCorsOrigin) {
    return {
      origin: "*",
      credentials: false,
    };
  }

  const allowedOrigins = new Set(allowedCorsOrigins);

  return {
    origin(origin, callback) {
      if (!origin || allowedOrigins.has(origin)) {
        callback(null, true);
        return;
      }

      callback(null, false);
    },
    credentials: false,
  };
}

function isHttpsRequest(req) {
  if (req.secure) {
    return true;
  }

  const forwardedProtoHeader = req.headers["x-forwarded-proto"];
  if (typeof forwardedProtoHeader !== "string") {
    return false;
  }

  const forwardedProto = forwardedProtoHeader
    .split(",")[0]
    .trim()
    .toLowerCase();

  return forwardedProto === "https";
}

function applySecurityHeaders(req, res, next) {
  if (!securityConfig.headersEnabled) {
    next();
    return;
  }

  res.set("X-Content-Type-Options", "nosniff");
  res.set("X-Frame-Options", "DENY");
  res.set("Referrer-Policy", "strict-origin-when-cross-origin");
  res.set("X-DNS-Prefetch-Control", "off");
  res.set("X-Permitted-Cross-Domain-Policies", "none");
  res.set(
    "Permissions-Policy",
    "camera=(), geolocation=(), microphone=(), payment=()"
  );

  if (securityConfig.hstsEnabled && isHttpsRequest(req)) {
    const hstsValue = [
      `max-age=${securityConfig.hstsMaxAgeSeconds}`,
      securityConfig.hstsIncludeSubDomains ? "includeSubDomains" : "",
    ]
      .filter(Boolean)
      .join("; ");

    res.set("Strict-Transport-Security", hstsValue);
  }

  next();
}

const displayBaseUrl =
  publicBaseUrl ||
  `http://${bindHost === "0.0.0.0" ? "localhost" : bindHost}:${port}`;

module.exports = {
  buildCorsOptions,
  applySecurityHeaders,
  isHttpsRequest,
  serverEnv: {
    nodeEnv,
    isProduction,
    warnings,
    server: {
      host: bindHost,
      port,
      publicBaseUrl,
      displayBaseUrl,
      trustProxy,
    },
    cors: {
      raw: rawCorsOrigin,
      allowAnyOrigin: allowAnyCorsOrigin,
      allowedOrigins: allowedCorsOrigins,
    },
    session: sessionConfig,
    security: securityConfig,
  },
};
