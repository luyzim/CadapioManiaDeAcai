const router = require("express").Router();
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const multer = require("multer");
const path = require("path");

// Multer storage configuration
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, path.join(__dirname, '..', 'public', 'uploads'));
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ storage: storage });

function auth(req, res, next) {
  const h = req.headers.authorization || "";
  const token = h.startsWith("Bearer ") ? h.slice(7) : "";
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.user = payload; // { id, email }
    next();
  } catch {
    return res.status(401).json({ error: "unauthorized" });
  }
}

// POST /api/admin/login
router.post("/login", async (req, res) => {
  const { email, password } = req.body || {};
  try {
    const admin = await prisma.admins.findUnique({ where: { email } });
    if (!admin) return res.status(401).json({ error: "credenciais inválidas" });
    const ok = await bcrypt.compare(password || "", admin.pass_hash);
    if (!ok) return res.status(401).json({ error: "credenciais inválidas" });
    const token = jwt.sign({ id: admin.id, email }, process.env.JWT_SECRET, { expiresIn: "8h" });
    res.json({ token });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /api/admin/upload
router.post("/upload", auth, upload.single('image'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'Nenhum arquivo foi enviado.' });
  }
  // The file is uploaded, return the URL
  const fileUrl = `/uploads/${req.file.filename}`;
  res.json({ imageUrl: fileUrl });
});


// --- CRUD CATEGORIES
router.post("/categories", auth, async (req, res) => {
  const { name } = req.body || {};
  if (!name) return res.status(400).json({ error: "name obrigatório" });
  try {
    const category = await prisma.categories.create({ data: { name } });
    res.status(201).json(category);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put("/categories/:id", auth, async (req, res) => {
  const id = +req.params.id;
  const { name } = req.body || {};
  try {
    const category = await prisma.categories.update({
      where: { id },
      data: { name },
    });
    res.json(category);
  } catch (e) {
    if (e.code === 'P2025') return res.status(404).json({ error: "não encontrado" });
    res.status(500).json({ error: e.message });
  }
});

router.delete("/categories/:id", auth, async (req, res) => {
  const id = +req.params.id;
  try {
    await prisma.categories.delete({ where: { id } });
    res.status(204).end();
  } catch (e) {
    if (e.code === 'P2025') return res.status(404).json({ error: "não encontrado" });
    res.status(500).json({ error: e.message });
  }
});

// --- CRUD ITEMS
router.post("/items", auth, async (req, res) => {
  const { category_id, name, short_desc, ingredients, price_cents, image_url, active } = req.body || {};
  if (!category_id || !name || price_cents == null) return res.status(400).json({ error: "campos obrigatórios faltando" });
  try {
    const item = await prisma.items.create({
      data: {
        category_id,
        name,
        short_desc,
        ingredients,
        price_cents,
        image_url,
        active: active ?? true,
      }
    });
    res.status(201).json(item);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

router.put("/items/:id", auth, async (req, res) => {
  const id = +req.params.id;
  const { category_id, name, short_desc, ingredients, price_cents, image_url, active } = req.body || {};
  try {
    const item = await prisma.items.update({
      where: { id },
      data: {
        category_id,
        name,
        short_desc,
        ingredients,
        price_cents,
        image_url,
        active,
      }
    });
    res.json(item);
  } catch (e) {
    if (e.code === 'P2025') return res.status(404).json({ error: "não encontrado" });
    res.status(500).json({ error: e.message });
  }
});

router.delete("/items/:id", auth, async (req, res) => {
  const id = +req.params.id;
  try {
    await prisma.items.delete({ where: { id } });
    res.status(204).end();
  } catch (e) {
    if (e.code === 'P2025') return res.status(404).json({ error: "não encontrado" });
    res.status(500).json({ error: e.message });
  }
});

// PATCH /api/admin/orders/:id/status  (RF008)
router.patch("/orders/:id/status", auth, async (req, res) => {
  const id = BigInt(req.params.id);
  const { status } = req.body || {};
  const allowed = ['Recebido', 'Em preparo', 'Pronto', 'Entregue'];
  if (!allowed.includes(status)) return res.status(400).json({ error: "status inválido" });

  // Map the string value from the request to the Prisma enum identifier
  const statusForDb = status === 'Em preparo' ? 'Em_preparo' : status;

  try {
    await prisma.$transaction(async (prisma) => {
      await prisma.orders.update({
        where: { id },
        data: { status: statusForDb },
      });

      await prisma.order_status_history.create({
        data: {
          order_id: id,
          status: statusForDb,
          changed_by: req.user.id,
        }
      });
    });
    res.json({ ok: true });
  } catch (e) {
    if (e.code === 'P2025') return res.status(404).json({ error: "pedido não encontrado" });
    res.status(500).json({ error: e.message });
  }
});

// GET /api/admin/orders (RF007)
router.get("/orders", auth, async (req, res) => {
  const { status } = req.query;
  
  let whereClause = {};
  if (status) {
    // Map the public-facing string to the internal Prisma enum identifier if needed
    const statusForDb = status === 'Em preparo' ? 'Em_preparo' : status;
    whereClause = { status: statusForDb };
  }

  try {
    const orders = await prisma.orders.findMany({
      where: whereClause,
      include: {
        _count: {
          select: { order_items: true }
        }
      },
      orderBy: {
        created_at: 'desc',
      },
      take: 200,
    });
    const response = orders.map(o => ({
      ...o,
      total_items: o._count.order_items
    }));
    res.json(response);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// GET /api/admin/paid-orders - Get all active orders (not 'Entregue')
router.get("/paid-orders", auth, async (req, res) => {
  try {
    const orders = await prisma.orders.findMany({
      where: {
        NOT: {
          status: "Entregue",
        }
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
        created_at: 'asc', // Oldest received orders first
      },
    });

    const response = orders.map(order => ({
      id: order.id,
      customer_name: order.customer_name,
      customer_table: order.customer_table,
      status: order.status,
      total_cents: order.total_cents,
      created_at: order.created_at,
      items: order.order_items.map(oi => ({
        item_id: oi.item_id,
        name: oi.items.name,
        qty: oi.qty,
        unit_price_cents: oi.unit_price_cents,
        options: oi.options,
        image_url: oi.items.image_url,
      })),
    }));

    res.json(response);
  } catch (e) {
    console.error("Database error in /api/admin/paid-orders:", e);
    res.status(500).json({ error: e.message });
  }
});

// GET /api/admin/delivery-orders - Get all orders with status 'Pronto'
router.get("/delivery-orders", auth, async (req, res) => {
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
        created_at: 'asc',
      },
    });

    const response = orders.map(order => ({
      id: order.id,
      customer_name: order.customer_name,
      customer_table: order.customer_table,
      status: order.status,
      total_cents: order.total_cents,
      created_at: order.created_at,
      items: order.order_items.map(oi => ({
        item_id: oi.item_id,
        name: oi.items.name,
        qty: oi.qty,
        unit_price_cents: oi.unit_price_cents,
        options: oi.options,
        image_url: oi.items.image_url,
      })),
    }));

    res.json(response);
  } catch (e) {
    console.error("Database error in /api/admin/delivery-orders:", e);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
