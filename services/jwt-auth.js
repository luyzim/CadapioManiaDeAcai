const jwt = require("jsonwebtoken");

const ROLE_ADMIN = "admin";
const ROLE_CLIENT = "client";
const TOKEN_TTL = "8h";

function getJwtSecret() {
  return process.env.JWT_SECRET;
}

function signToken(payload) {
  return jwt.sign(payload, getJwtSecret(), { expiresIn: TOKEN_TTL });
}

function signAdminToken(admin) {
  return signToken({
    sub: `admin:${admin.id}`,
    id: admin.id,
    email: admin.email,
    role: ROLE_ADMIN,
  });
}

function signClientToken(client) {
  return signToken({
    sub: `client:${client.id}`,
    id: client.id,
    email: client.email,
    name: client.name,
    phone: client.phone || null,
    firebase_uid: client.firebase_uid || null,
    role: ROLE_CLIENT,
  });
}

function extractBearerToken(req) {
  const authHeader =
    req.headers.authorization || req.headers["x-authorization"] || "";

  return authHeader.startsWith("Bearer ")
    ? authHeader.slice(7).trim()
    : "";
}

function verifyToken(token) {
  return jwt.verify(token, getJwtSecret());
}

function requireAuth(allowedRoles = []) {
  return (req, res, next) => {
    const token = extractBearerToken(req);
    if (!token) {
      return res.status(401).json({ error: "unauthorized" });
    }

    try {
      const payload = verifyToken(token);
      if (
        allowedRoles.length > 0 &&
        !allowedRoles.includes(payload.role)
      ) {
        return res.status(403).json({ error: "forbidden" });
      }

      req.auth = payload;

      if (payload.role === ROLE_ADMIN) {
        req.user = payload;
      }

      if (payload.role === ROLE_CLIENT) {
        req.client = payload;
      }

      next();
    } catch (error) {
      return res.status(401).json({ error: "unauthorized" });
    }
  };
}

const requireAdmin = requireAuth([ROLE_ADMIN]);
const requireClient = requireAuth([ROLE_CLIENT]);

module.exports = {
  ROLE_ADMIN,
  ROLE_CLIENT,
  extractBearerToken,
  requireAdmin,
  requireAuth,
  requireClient,
  signAdminToken,
  signClientToken,
  verifyToken,
};
