const express = require('express');
const router = express.Router();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

router.use((req, res, next) => {
  // Persist the anonymous session only when the cart flow is actually used.
  if (!req.session.cartInitialized) {
    req.session.cartInitialized = true;
  }

  next();
});

// GET /api/cart - Get all items in the cart
router.get('/', async (req, res) => {
  try {
    const cartItems = await prisma.cart.findMany({
      where: {
        session_id: req.session.id,
      },
      include: {
        items: { // Assuming 'items' is the relation name in your Prisma schema
          select: {
            name: true,
            price_cents: true,
            image_url: true,
          },
        },
      },
    });

    // Map the result to a more flattened structure
    const response = cartItems.map(ci => ({
      id: ci.id,
      item_id: ci.item_id,
      quantity: ci.quantity,
      name: ci.items.name,
      price_cents: ci.items.price_cents,
      image_url: ci.items.image_url,
    }));

    res.json(response);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});
// POST /api/cart - Add an item to the cart
router.post('/', async (req, res) => {
  const { itemId, quantity = 1 } = req.body;

  if (!itemId) {
    return res.status(400).json({ error: 'itemId is required' });
  }

  try {
    const cartItem = await prisma.cart.upsert({
      where: {
        session_id_item_id: {
          session_id: req.session.id,
          item_id: itemId,
        },
      },
      update: {
        quantity: {
          increment: quantity,
        },
      },
      create: {
        session_id: req.session.id,
        item_id: itemId,
        quantity: quantity,
      },
    });
    res.status(201).json(cartItem);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PUT /api/cart/:itemId - Update item quantity
router.put('/:itemId', async (req, res) => {
    const itemId = +req.params.itemId;
    const { quantity } = req.body;

    if (!quantity || quantity < 1) {
        return res.status(400).json({ error: 'A valid quantity is required' });
    }

    try {
        const updatedCart = await prisma.cart.updateMany({
            where: {
                session_id: req.session.id,
                item_id: itemId,
            },
            data: {
                quantity: quantity,
            },
        });

        if (updatedCart.count === 0) {
            return res.status(404).json({ error: 'Item not found in cart' });
        }

        res.json({ok: true});
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// DELETE /api/cart/:itemId - Remove an item from the cart
router.delete('/:itemId', async (req, res) => {
    const itemId = +req.params.itemId;

    try {
        const result = await prisma.cart.deleteMany({
            where: {
                session_id: req.session.id,
                item_id: itemId,
            },
        });

        if (result.count === 0) {
            return res.status(404).json({ error: 'Item not found in cart' });
        }

        res.status(204).send(); // No Content
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// DELETE /api/cart - Clear the entire cart
router.delete('/', async (req, res) => {
    try {
        await prisma.cart.deleteMany({ where: { session_id: req.session.id } });
        res.status(204).send(); // No Content
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Internal server error' });
    }
});


module.exports = router;
