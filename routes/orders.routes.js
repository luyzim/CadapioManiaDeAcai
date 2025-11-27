// routes/orders.routes.js
const router = require("express").Router();
require("dotenv").config(); // Ensure env variables are loaded
const { PrismaClient } = require("@prisma/client"); // padronize isso depois, ver passo 3
const prisma = new PrismaClient();
const jwt = require("jsonwebtoken"); // Import jwt

// Middleware to authenticate clients
function clientAuth(req, res, next) {
  const h = req.headers['x-authorization'] || "";
  const token = h.startsWith("Bearer ") ? h.slice(7) : "";
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.client = payload; // { id, email, name }
    next();
  } catch (err) {
    console.error("JWT Verification Error:", err); // Log the specific error
    return res.status(401).json({ error: "unauthorized" });
  }
}

router.post("/", clientAuth, async (req, res) => {
  const { customer_name, customer_table, items } = req.body || {};
  if (!Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: "Pedido vazio" });
  }

  try {
    const { orderId, total } = await prisma.$transaction(async (tx) => {
      let calculatedTotal = 0;

      const order = await tx.orders.create({
        data: {
          client_id: req.client.id, // Link order to client
          customer_name: customer_name || req.client.name || null, // Use client name if not provided
          customer_table: customer_table || null,
          status: "Recebido",
          total_cents: 0,
        },
      });

      for (const it of items) {
        const baseItem = await tx.items.findUnique({ where: { id: it.item_id } });
        if (!baseItem) throw new Error(`Item ${it.item_id} inexistente`);

        const optionsPrice = (it.selected_options || []).reduce((s, o) => s + (o.add_price_cents || 0), 0);
        const unit = (baseItem.price_cents || 0) + optionsPrice;
        const qty = it.qty || 1;
        calculatedTotal += unit * qty;

        await tx.order_items.create({
          data: {
            order_id: order.id,
            item_id: it.item_id,
            qty,
            unit_price_cents: unit,
            options: it.selected_options || [],
          },
        });
      }

      await tx.orders.update({
        where: { id: order.id },
        data: { total_cents: calculatedTotal },
      });

      await tx.order_status_history.create({
        data: { order_id: order.id, status: "Recebido" },
      });

      return { orderId: order.id, total: calculatedTotal };
    });

    res.status(201).json({ id: orderId, total_cents: total, status: "Recebido" });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/orders/:id - Rota para o cliente ver o status do pedido
router.get("/:id", async (req, res) => {
  const id = BigInt(req.params.id);
  try {
    const order = await prisma.orders.findUnique({
      where: { id },
      include: {
        order_items: {
          include: {
            items: {
              select: {
                name: true,
              }
            }
          }
        }
      }
    });
    if (!order) {
      return res.status(404).json({ error: "Pedido não encontrado" });
    }
    res.json(order);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /api/orders/:id/confirm-delivery - Rota para o cliente confirmar a entrega
router.post("/:id/confirm-delivery", async (req, res) => {
  const id = BigInt(req.params.id);
  try {
    await prisma.$transaction(async (tx) => {
      const order = await tx.orders.findUnique({ where: { id } });
      if (!order) throw new Error('not_found');
      if (order.status !== 'Pronto') {
        // Only allow confirmation if the order is ready
        throw new Error('not_ready');
      }

      await tx.orders.update({
        where: { id },
        data: { status: 'Entregue' },
      });

      await tx.order_status_history.create({
        data: {
          order_id: id,
          status: 'Entregue',
          // changed_by is null because the customer did this action
        }
      });
    });
    res.json({ ok: true });
  } catch (e) {
    if (e.message === 'not_found') return res.status(404).json({ error: "Pedido não encontrado" });
    if (e.message === 'not_ready') return res.status(400).json({ error: "O pedido não está pronto para ser marcado como entregue." });
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
