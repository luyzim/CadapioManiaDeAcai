const express = require("express");
require("dotenv").config();

const bcrypt = require("bcryptjs");
const { PrismaClient } = require("@prisma/client");
const { isValidEmail } = require("../services/email-validator");
const {
  requireClient,
  signClientToken,
} = require("../services/jwt-auth");

const {
  firebaseAuth,
  generateTemporaryPassword,
  getUserByEmailIfExists,
  mapFirebaseAuthError,
  sendPasswordResetEmail,
  signInWithEmailAndPassword,
  verifyFirebaseIdToken,
} = require("../services/firebase-auth");

const router = express.Router();
const prisma = new PrismaClient();

function normalizeText(value) {
  return String(value || "").trim();
}

function normalizeEmail(value) {
  return normalizeText(value).toLowerCase();
}

function buildClientToken(client) {
  return signClientToken(client);
}

function buildClientAuthResponse(client, extra = {}) {
  return {
    token: buildClientToken(client),
    client: {
      id: client.id,
      name: client.name,
      email: client.email,
      phone: client.phone || null,
      firebase_uid: client.firebase_uid || null,
    },
    ...extra,
  };
}

async function upsertClientProfile({
  email,
  firebaseUid,
  name,
  phone,
  preservePassHash = true,
}) {
  const existingClient = await prisma.clients.findUnique({ where: { email } });
  const clientName =
    normalizeText(name) || existingClient?.name || email.split("@")[0];
  const clientPhone =
    phone === undefined ? existingClient?.phone || null : normalizeText(phone) || null;

  if (existingClient) {
    const data = {
      name: clientName,
      phone: clientPhone,
      firebase_uid: firebaseUid || existingClient.firebase_uid || null,
    };

    if (!preservePassHash) {
      data.pass_hash = null;
    }

    return prisma.clients.update({
      where: { id: existingClient.id },
      data,
    });
  }

  return prisma.clients.create({
    data: {
      name: clientName,
      email,
      phone: clientPhone,
      firebase_uid: firebaseUid || null,
      pass_hash: null,
    },
  });
}

async function ensureLegacyClientMigrated(client, password) {
  let firebaseUser = await getUserByEmailIfExists(client.email);

  if (!firebaseUser) {
    firebaseUser = await firebaseAuth().createUser({
      email: client.email,
      password,
      displayName: client.name || undefined,
    });
  }

  return upsertClientProfile({
    email: client.email,
    firebaseUid: firebaseUser.uid,
    name: client.name,
    phone: client.phone,
  });
}

router.post("/signup", async (req, res) => {
  const name = normalizeText(req.body?.name);
  const email = normalizeEmail(req.body?.email);
  const phone = normalizeText(req.body?.phone);
  const password = String(req.body?.password || "");
  const confirmPassword = String(req.body?.confirmPassword || "");

  if (!name || !email || !phone || !password || !confirmPassword) {
    return res.status(400).json({
      error:
        "Nome, email, telefone, senha e confirmacao de senha sao obrigatorios.",
    });
  }

  if (!isValidEmail(email)) {
    return res.status(400).json({ error: "Informe um e-mail valido." });
  }

  if (password !== confirmPassword) {
    return res
      .status(400)
      .json({ error: "Senha e confirmacao de senha devem ser iguais." });
  }

  if (password.length < 6) {
    return res
      .status(400)
      .json({ error: "A senha deve ter pelo menos 6 caracteres." });
  }

  try {
    const existingClient = await prisma.clients.findUnique({ where: { email } });
    if (existingClient) {
      return res.status(409).json({ error: "Email ja cadastrado." });
    }

    const firebaseUser = await firebaseAuth().createUser({
      email,
      password,
      displayName: name,
    });

    try {
      const client = await upsertClientProfile({
        email,
        firebaseUid: firebaseUser.uid,
        name,
        phone,
      });

      return res.status(201).json({
        message: "Cadastro realizado com sucesso!",
        ...buildClientAuthResponse(client),
      });
    } catch (dbError) {
      await firebaseAuth().deleteUser(firebaseUser.uid);
      throw dbError;
    }
  } catch (error) {
    if (error.code === "P2002") {
      return res.status(409).json({ error: "Email ja cadastrado." });
    }

    const mappedError = mapFirebaseAuthError(error);
    console.error("Signup error:", error);
    return res.status(mappedError.status).json({ error: mappedError.message });
  }
});

router.post("/login", async (req, res) => {
  const email = normalizeEmail(req.body?.email);
  const password = String(req.body?.password || "");

  if (!email || !password) {
    return res
      .status(400)
      .json({ error: "Email e senha sao obrigatorios." });
  }

  if (!isValidEmail(email)) {
    return res.status(400).json({ error: "Informe um e-mail valido." });
  }

  try {
    const firebaseUser = await getUserByEmailIfExists(email);

    if (firebaseUser) {
      await signInWithEmailAndPassword(email, password);

      const client = await upsertClientProfile({
        email,
        firebaseUid: firebaseUser.uid,
        name: firebaseUser.displayName,
      });

      return res.json(buildClientAuthResponse(client));
    }

    const legacyClient = await prisma.clients.findUnique({ where: { email } });
    if (!legacyClient || !legacyClient.pass_hash) {
      return res.status(401).json({ error: "Credenciais invalidas." });
    }

    const passwordMatches = await bcrypt.compare(password, legacyClient.pass_hash);
    if (!passwordMatches) {
      return res.status(401).json({ error: "Credenciais invalidas." });
    }

    const migratedClient = await ensureLegacyClientMigrated(legacyClient, password);
    return res.json(
      buildClientAuthResponse(migratedClient, {
        migratedToFirebase: true,
      })
    );
  } catch (error) {
    const mappedError = mapFirebaseAuthError(error);
    console.error("Login error:", error);
    return res.status(mappedError.status).json({ error: mappedError.message });
  }
});

router.post("/firebase-session", async (req, res) => {
  const idToken = normalizeText(req.body?.idToken);
  const name = normalizeText(req.body?.name);
  const phone = normalizeText(req.body?.phone);

  if (!idToken) {
    return res.status(400).json({
      error: "Informe o Firebase ID token para abrir a sessao.",
    });
  }

  try {
    const decodedToken = await verifyFirebaseIdToken(idToken);
    const email = normalizeEmail(decodedToken.email);

    if (!email || !isValidEmail(email)) {
      return res.status(400).json({
        error: "O Firebase ID token precisa conter um e-mail valido.",
      });
    }

    const client = await upsertClientProfile({
      email,
      firebaseUid: decodedToken.uid,
      name: name || normalizeText(decodedToken.name),
      phone,
    });

    return res.json(
      buildClientAuthResponse(client, {
        firebaseSignInProvider:
          decodedToken.firebase?.sign_in_provider || null,
      })
    );
  } catch (error) {
    const mappedError = mapFirebaseAuthError(error);
    console.error("Firebase session error:", error);
    return res.status(mappedError.status).json({ error: mappedError.message });
  }
});

router.post("/forgot-password", async (req, res) => {
  const email = normalizeEmail(req.body?.email);

  if (!email) {
    return res
      .status(400)
      .json({ error: "Informe o e-mail cadastrado para recuperar a senha." });
  }

  if (!isValidEmail(email)) {
    return res.status(400).json({ error: "Informe um e-mail valido." });
  }

  try {
    let firebaseUser = await getUserByEmailIfExists(email);

    if (!firebaseUser) {
      const legacyClient = await prisma.clients.findUnique({ where: { email } });

      if (!legacyClient) {
        return res
          .status(404)
          .json({ error: "Nenhuma conta encontrada com este e-mail." });
      }

      firebaseUser = await firebaseAuth().createUser({
        email,
        password: generateTemporaryPassword(),
        displayName: legacyClient.name || undefined,
      });

      await upsertClientProfile({
        email,
        firebaseUid: firebaseUser.uid,
        name: legacyClient.name,
        phone: legacyClient.phone,
      });
    }

    await sendPasswordResetEmail(email);

    return res.json({
      message:
        "As instrucoes para redefinicao de senha foram enviadas para o e-mail informado.",
    });
  } catch (error) {
    const mappedError = mapFirebaseAuthError(error);
    console.error("Forgot password error:", error);
    return res.status(mappedError.status).json({ error: mappedError.message });
  }
});

router.get("/my-orders", requireClient, async (req, res) => {
  try {
    const orders = await prisma.orders.findMany({
      where: {
        client_id: req.client.id,
      },
      include: {
        order_items: {
          include: {
            items: {
              select: {
                name: true,
                image_url: true,
              },
            },
          },
        },
      },
      orderBy: {
        created_at: "desc",
      },
    });

    const response = orders.map((order) => ({
      id: order.id,
      customer_name: order.customer_name,
      customer_table: order.customer_table,
      status: order.status,
      total_cents: order.total_cents,
      created_at: order.created_at,
      items: order.order_items.map((oi) => ({
        item_id: oi.item_id,
        name: oi.items.name,
        qty: oi.qty,
        unit_price_cents: oi.unit_price_cents,
        options: oi.options,
        image_url: oi.items.image_url,
      })),
    }));

    res.json(response);
  } catch (error) {
    console.error("Database error in /api/client/my-orders:", error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
