require("dotenv").config();

const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const { cert, getApps, initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");

const FIREBASE_ADMIN_ENV_KEYS = [
  "FIREBASE_PROJECT_ID",
  "FIREBASE_CLIENT_EMAIL",
  "FIREBASE_PRIVATE_KEY",
];

function normalizePrivateKey(privateKey) {
  const rawValue = String(privateKey || "");
  const withNormalizedNewlines = rawValue
    .replace(/\\n/g, "\n")
    .replace(/\r\n?/g, "\n")
    .trim();

  const pemMatch = withNormalizedNewlines.match(
    /-----BEGIN PRIVATE KEY-----[\s\S]*-----END PRIVATE KEY-----/
  );

  return pemMatch ? pemMatch[0] : withNormalizedNewlines;
}

function getMissingEnv(keys) {
  return keys.filter((key) => !process.env[key]);
}

function ensureFirebaseAdminConfig() {
  const missing = getMissingEnv(FIREBASE_ADMIN_ENV_KEYS);
  if (missing.length > 0) {
    const error = new Error(
      `Variaveis do Firebase ausentes: ${missing.join(", ")}`
    );
    error.code = "firebase/config-missing";
    throw error;
  }
}

function ensureFirebaseWebApiKey() {
  if (!process.env.FIREBASE_WEB_API_KEY) {
    const error = new Error(
      "Variavel do Firebase ausente: FIREBASE_WEB_API_KEY"
    );
    error.code = "firebase/config-missing";
    throw error;
  }
}

function getServiceAccountPath() {
  const serviceAccountPath =
    process.env.FIREBASE_SERVICE_ACCOUNT_PATH ||
    process.env.GOOGLE_APPLICATION_CREDENTIALS ||
    "";

  return String(serviceAccountPath).trim();
}

function readServiceAccountFromFile(serviceAccountPath) {
  const resolvedPath = path.resolve(serviceAccountPath);
  let rawServiceAccount = "";

  try {
    rawServiceAccount = fs.readFileSync(resolvedPath, "utf8");
  } catch (error) {
    const fileError = new Error(
      `Nao foi possivel ler o arquivo da conta de servico do Firebase em ${resolvedPath}.`
    );
    fileError.code = "firebase/service-account-file-not-found";
    throw fileError;
  }

  let parsedServiceAccount;
  try {
    parsedServiceAccount = JSON.parse(rawServiceAccount);
  } catch (error) {
    const parseError = new Error(
      "O arquivo da conta de servico do Firebase nao esta em JSON valido."
    );
    parseError.code = "firebase/service-account-invalid";
    throw parseError;
  }

  const missing = ["project_id", "client_email", "private_key"].filter(
    (key) => !parsedServiceAccount[key]
  );

  if (missing.length > 0) {
    const configError = new Error(
      `O arquivo da conta de servico do Firebase esta incompleto: ${missing.join(", ")}`
    );
    configError.code = "firebase/service-account-invalid";
    throw configError;
  }

  return {
    projectId: parsedServiceAccount.project_id,
    clientEmail: parsedServiceAccount.client_email,
    privateKey: parsedServiceAccount.private_key,
  };
}

function getFirebaseAdminCredentialConfig() {
  const serviceAccountPath = getServiceAccountPath();

  if (serviceAccountPath) {
    return readServiceAccountFromFile(serviceAccountPath);
  }

  ensureFirebaseAdminConfig();

  return {
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: normalizePrivateKey(process.env.FIREBASE_PRIVATE_KEY),
  };
}

function getFirebaseApp() {
  if (!getApps().length) {
    const credentials = getFirebaseAdminCredentialConfig();

    initializeApp({
      credential: cert(credentials),
    });
  }

  return getApps()[0];
}

function firebaseAuth() {
  return getAuth(getFirebaseApp());
}

async function verifyFirebaseIdToken(idToken) {
  return firebaseAuth().verifyIdToken(idToken);
}

async function callIdentityToolkit(endpoint, payload) {
  ensureFirebaseWebApiKey();

  const response = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:${endpoint}?key=${process.env.FIREBASE_WEB_API_KEY}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    }
  );

  let data = {};
  try {
    data = await response.json();
  } catch (error) {
    data = {};
  }

  if (!response.ok) {
    const firebaseCode = data?.error?.message || "FIREBASE_AUTH_ERROR";
    const error = new Error(firebaseCode);
    error.code = firebaseCode;
    error.details = data;
    throw error;
  }

  return data;
}

async function getUserByEmailIfExists(email) {
  try {
    return await firebaseAuth().getUserByEmail(email);
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      return null;
    }

    throw error;
  }
}

async function signInWithEmailAndPassword(email, password) {
  return callIdentityToolkit("signInWithPassword", {
    email,
    password,
    returnSecureToken: true,
  });
}

async function sendPasswordResetEmail(email) {
  return callIdentityToolkit("sendOobCode", {
    requestType: "PASSWORD_RESET",
    email,
  });
}

function generateTemporaryPassword() {
  return crypto.randomBytes(24).toString("base64url");
}

function mapFirebaseAuthError(error) {
  const code = error.code || error.message || "firebase/unknown";

  switch (code) {
    case "auth/email-already-exists":
      return { status: 409, message: "Email ja cadastrado." };
    case "auth/invalid-email":
    case "INVALID_EMAIL":
      return { status: 400, message: "Informe um e-mail valido." };
    case "auth/invalid-password":
      return {
        status: 400,
        message: "A senha precisa atender aos requisitos do Firebase.",
      };
    case "auth/user-not-found":
    case "EMAIL_NOT_FOUND":
      return {
        status: 404,
        message: "Nenhuma conta encontrada com este e-mail.",
      };
    case "INVALID_LOGIN_CREDENTIALS":
      return { status: 401, message: "Credenciais invalidas." };
    case "MISSING_EMAIL":
      return { status: 400, message: "Informe o e-mail cadastrado." };
    case "auth/invalid-id-token":
    case "auth/id-token-expired":
    case "auth/id-token-revoked":
      return {
        status: 401,
        message: "O token de autenticacao do Firebase e invalido ou expirou.",
      };
    case "app/invalid-credential":
      return {
        status: 500,
        message:
          "As credenciais do Firebase Admin sao invalidas. Verifique a conta de servico ou a FIREBASE_PRIVATE_KEY.",
      };
    case "firebase/service-account-file-not-found":
    case "firebase/service-account-invalid":
    case "firebase/config-missing":
      return { status: 500, message: error.message };
    default:
      return {
        status: 500,
        message: "Falha ao comunicar com o Firebase Authentication.",
      };
  }
}

module.exports = {
  firebaseAuth,
  generateTemporaryPassword,
  getUserByEmailIfExists,
  mapFirebaseAuthError,
  sendPasswordResetEmail,
  signInWithEmailAndPassword,
  verifyFirebaseIdToken,
};
