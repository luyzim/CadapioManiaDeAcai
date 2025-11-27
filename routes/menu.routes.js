const router = require("express").Router();
const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

// GET /api/menu -> categorias com itens
router.get("/", async (req, res) => {
  try {
    const categories = await prisma.categories.findMany({
      orderBy: {
        name: 'asc',
      },
      include: {
        items: {
          where: {
            active: true,
          },
          orderBy: {
            name: 'asc',
          },
        },
      },
    });
    res.json({ categories });
  } catch (e) {
    console.error("Database error in /api/menu:", e);
    res.status(500).json({ error: e.message });
  }
});

// GET /api/menu/items/:id -> detalhes de um item + opções
router.get("/items/:id", async (req, res) => {
  const id = +req.params.id;
  if (!Number.isInteger(id)) return res.status(400).json({ error: "id inválido" });
  try {
    const item = await prisma.items.findUnique({
      where: {
        id: id,
      },
      include: {
        item_options: true,
      },
    });
    if (!item) return res.status(404).json({ error: "item não encontrado" });
    res.json(item);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
