const router = require("express").Router();
const { PrismaClient } = require("@prisma/client");
const bcrypt = require("bcryptjs");
const multer = require("multer");
const path = require("path");

const { requireAdmin, signAdminToken } = require("../services/jwt-auth");

const prisma = new PrismaClient();

const storage = multer.diskStorage({
  destination(req, file, cb) {
    cb(null, path.join(__dirname, "..", "public", "uploads"));
  },
  filename(req, file, cb) {
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(
      null,
      `${file.fieldname}-${uniqueSuffix}${path.extname(file.originalname)}`
    );
  },
});

const upload = multer({ storage });

function normalizeRequiredString(value) {
  return String(value || "").trim();
}

function normalizeOptionalString(value) {
  const normalized = String(value || "").trim();
  return normalized ? normalized : null;
}

function parseInteger(value) {
  if (typeof value === "number" && Number.isInteger(value)) {
    return value;
  }

  const normalized = String(value || "").trim();
  if (!normalized) {
    return null;
  }

  const parsed = Number.parseInt(normalized, 10);
  return Number.isInteger(parsed) ? parsed : null;
}

function parseBoolean(value, fallback = true) {
  if (typeof value === "boolean") {
    return value;
  }

  if (value == null) {
    return fallback;
  }

  const normalized = String(value).trim().toLowerCase();
  if (["true", "1", "yes", "on"].includes(normalized)) {
    return true;
  }

  if (["false", "0", "no", "off"].includes(normalized)) {
    return false;
  }

  return fallback;
}

function buildCategoryPayload(body) {
  const name = normalizeRequiredString(body?.name);

  if (!name) {
    return { error: "name obrigatorio" };
  }

  return {
    data: {
      name,
    },
  };
}

function buildItemPayload(body) {
  const categoryId = parseInteger(body?.category_id);
  const name = normalizeRequiredString(body?.name);
  const priceCents = parseInteger(body?.price_cents);

  if (categoryId == null || categoryId <= 0) {
    return { error: "category_id invalido" };
  }

  if (!name) {
    return { error: "name obrigatorio" };
  }

  if (priceCents == null || priceCents < 0) {
    return { error: "price_cents invalido" };
  }

  return {
    data: {
      category_id: categoryId,
      name,
      short_desc: normalizeOptionalString(body?.short_desc),
      ingredients: normalizeOptionalString(body?.ingredients),
      price_cents: priceCents,
      image_url: normalizeOptionalString(body?.image_url),
      active: parseBoolean(body?.active, true),
    },
  };
}

function handleAdminCrudError(res, error, notFoundMessage) {
  if (error.code === "P2025") {
    return res.status(404).json({ error: notFoundMessage });
  }

  if (error.code === "P2002") {
    return res.status(409).json({ error: "registro duplicado" });
  }

  if (error.code === "P2003") {
    return res.status(400).json({ error: "relacao invalida" });
  }

  return res.status(500).json({ error: error.message });
}

router.post("/login", async (req, res) => {
  const { email, password } = req.body || {};

  try {
    const admin = await prisma.admins.findUnique({ where: { email } });
    if (!admin) {
      return res.status(401).json({ error: "credenciais invalidas" });
    }

    const isValidPassword = await bcrypt.compare(password || "", admin.pass_hash);
    if (!isValidPassword) {
      return res.status(401).json({ error: "credenciais invalidas" });
    }

    const token = signAdminToken(admin);
    return res.json({ token });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

router.get("/categories", requireAdmin, async (req, res) => {
  try {
    const categories = await prisma.categories.findMany({
      orderBy: {
        name: "asc",
      },
    });

    return res.json(categories);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

router.get("/items", requireAdmin, async (req, res) => {
  try {
    const items = await prisma.items.findMany({
      include: {
        categories: {
          select: {
            name: true,
          },
        },
      },
      orderBy: [
        {
          categories: {
            name: "asc",
          },
        },
        {
          name: "asc",
        },
      ],
    });

    return res.json(
      items.map((item) => ({
        id: item.id,
        category_id: item.category_id,
        category_name: item.categories.name,
        name: item.name,
        short_desc: item.short_desc,
        ingredients: item.ingredients,
        price_cents: item.price_cents,
        image_url: item.image_url,
        active: item.active,
      }))
    );
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

router.post("/upload", requireAdmin, upload.single("image"), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: "Nenhum arquivo foi enviado." });
  }

  const fileUrl = `/uploads/${req.file.filename}`;
  return res.json({ imageUrl: fileUrl });
});

router.post("/categories", requireAdmin, async (req, res) => {
  const payload = buildCategoryPayload(req.body);
  if (payload.error) {
    return res.status(400).json({ error: payload.error });
  }

  try {
    const category = await prisma.categories.create({
      data: payload.data,
    });

    return res.status(201).json(category);
  } catch (error) {
    return handleAdminCrudError(res, error, "categoria nao encontrada");
  }
});

router.put("/categories/:id", requireAdmin, async (req, res) => {
  const id = parseInteger(req.params.id);
  if (id == null || id <= 0) {
    return res.status(400).json({ error: "id invalido" });
  }

  const payload = buildCategoryPayload(req.body);
  if (payload.error) {
    return res.status(400).json({ error: payload.error });
  }

  try {
    const category = await prisma.categories.update({
      where: { id },
      data: payload.data,
    });

    return res.json(category);
  } catch (error) {
    return handleAdminCrudError(res, error, "categoria nao encontrada");
  }
});

router.delete("/categories/:id", requireAdmin, async (req, res) => {
  const id = parseInteger(req.params.id);
  if (id == null || id <= 0) {
    return res.status(400).json({ error: "id invalido" });
  }

  try {
    await prisma.categories.delete({ where: { id } });
    return res.status(204).end();
  } catch (error) {
    return handleAdminCrudError(res, error, "categoria nao encontrada");
  }
});

router.post("/items", requireAdmin, async (req, res) => {
  const payload = buildItemPayload(req.body);
  if (payload.error) {
    return res.status(400).json({ error: payload.error });
  }

  try {
    const item = await prisma.items.create({
      data: payload.data,
    });

    return res.status(201).json(item);
  } catch (error) {
    return handleAdminCrudError(res, error, "item nao encontrado");
  }
});

router.put("/items/:id", requireAdmin, async (req, res) => {
  const id = parseInteger(req.params.id);
  if (id == null || id <= 0) {
    return res.status(400).json({ error: "id invalido" });
  }

  const payload = buildItemPayload(req.body);
  if (payload.error) {
    return res.status(400).json({ error: payload.error });
  }

  try {
    const item = await prisma.items.update({
      where: { id },
      data: payload.data,
    });

    return res.json(item);
  } catch (error) {
    return handleAdminCrudError(res, error, "item nao encontrado");
  }
});

router.delete("/items/:id", requireAdmin, async (req, res) => {
  const id = parseInteger(req.params.id);
  if (id == null || id <= 0) {
    return res.status(400).json({ error: "id invalido" });
  }

  try {
    await prisma.items.delete({ where: { id } });
    return res.status(204).end();
  } catch (error) {
    return handleAdminCrudError(res, error, "item nao encontrado");
  }
});

router.patch("/orders/:id/status", requireAdmin, async (req, res) => {
  const id = BigInt(req.params.id);
  const { status } = req.body || {};
  const allowed = ["Recebido", "Em preparo", "Pronto", "Entregue"];
  if (!allowed.includes(status)) {
    return res.status(400).json({ error: "status invalido" });
  }

  const statusForDb = status === "Em preparo" ? "Em_preparo" : status;

  try {
    await prisma.$transaction(async (transaction) => {
      await transaction.orders.update({
        where: { id },
        data: { status: statusForDb },
      });

      await transaction.order_status_history.create({
        data: {
          order_id: id,
          status: statusForDb,
          changed_by: req.user.id,
        },
      });
    });

    return res.json({ ok: true });
  } catch (error) {
    if (error.code === "P2025") {
      return res.status(404).json({ error: "pedido nao encontrado" });
    }

    return res.status(500).json({ error: error.message });
  }
});

router.get("/orders", requireAdmin, async (req, res) => {
  const { status } = req.query;

  let whereClause = {};
  if (status) {
    const statusForDb = status === "Em preparo" ? "Em_preparo" : status;
    whereClause = { status: statusForDb };
  }

  try {
    const orders = await prisma.orders.findMany({
      where: whereClause,
      include: {
        _count: {
          select: { order_items: true },
        },
      },
      orderBy: {
        created_at: "desc",
      },
      take: 200,
    });

    const response = orders.map((order) => ({
      ...order,
      total_items: order._count.order_items,
    }));

    return res.json(response);
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
});

router.get("/paid-orders", requireAdmin, async (req, res) => {
  try {
    const orders = await prisma.orders.findMany({
      where: {
        NOT: {
          status: "Entregue",
        },
      },
      include: {
        order_items: {
          include: {
            items: {
              select: {
                name: true,
                price_cents: true,
                image_url: true,
              },
            },
          },
        },
      },
      orderBy: {
        created_at: "asc",
      },
    });

    const response = orders.map((order) => ({
      id: order.id,
      customer_name: order.customer_name,
      customer_table: order.customer_table,
      status: order.status,
      total_cents: order.total_cents,
      created_at: order.created_at,
      items: order.order_items.map((orderItem) => ({
        item_id: orderItem.item_id,
        name: orderItem.items.name,
        qty: orderItem.qty,
        unit_price_cents: orderItem.unit_price_cents,
        options: orderItem.options,
        image_url: orderItem.items.image_url,
      })),
    }));

    return res.json(response);
  } catch (error) {
    console.error("Database error in /api/admin/paid-orders:", error);
    return res.status(500).json({ error: error.message });
  }
});

router.get("/delivery-orders", requireAdmin, async (req, res) => {
  try {
    const orders = await prisma.orders.findMany({
      where: {
        status: "Pronto",
      },
      include: {
        order_items: {
          include: {
            items: {
              select: {
                name: true,
                price_cents: true,
                image_url: true,
              },
            },
          },
        },
      },
      orderBy: {
        created_at: "asc",
      },
    });

    const response = orders.map((order) => ({
      id: order.id,
      customer_name: order.customer_name,
      customer_table: order.customer_table,
      status: order.status,
      total_cents: order.total_cents,
      created_at: order.created_at,
      items: order.order_items.map((orderItem) => ({
        item_id: orderItem.item_id,
        name: orderItem.items.name,
        qty: orderItem.qty,
        unit_price_cents: orderItem.unit_price_cents,
        options: orderItem.options,
        image_url: orderItem.items.image_url,
      })),
    }));

    return res.json(response);
  } catch (error) {
    console.error("Database error in /api/admin/delivery-orders:", error);
    return res.status(500).json({ error: error.message });
  }
});

module.exports = router;
