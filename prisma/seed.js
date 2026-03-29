const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

const categories = [
  { key: "acai", name: "A\u00E7a\u00ED" },
  { key: "bebidas", name: "Bebidas" },
];

const menuItems = [
  {
    categoryKey: "acai",
    name: "A\u00E7a\u00ED com Morango e Ninho",
    short_desc: "A\u00E7a\u00ED cremoso com morango e leite Ninho.",
    ingredients: "A\u00E7a\u00ED, morango e leite Ninho.",
    price_cents: 1800,
    image_url: "/img/AcaiMorangoComNinho-removebg-preview.png",
  },
  {
    categoryKey: "acai",
    name: "A\u00E7a\u00ED com Uva e Nutella",
    short_desc: "A\u00E7a\u00ED cremoso com uva e Nutella.",
    ingredients: "A\u00E7a\u00ED, uva e Nutella.",
    price_cents: 1900,
    image_url: "/img/AcaiUvaComNutella-removebg-preview.png",
  },
  {
    categoryKey: "bebidas",
    name: "Batida de A\u00E7a\u00ED",
    short_desc: "Batida gelada de a\u00E7a\u00ED pronta para beber.",
    ingredients: "A\u00E7a\u00ED batido e gelo.",
    price_cents: 1400,
    image_url: "/img/BatidaA\u00E7ai-removebg-preview.png",
  },
  {
    categoryKey: "bebidas",
    name: "Coca-Cola Lata",
    short_desc: "Refrigerante Coca-Cola em lata 350ml.",
    ingredients: "\u00C1gua gaseificada, a\u00E7\u00FAcar e extrato de noz de cola.",
    price_cents: 600,
    image_url: "/img/CocaCola.png",
  },
  {
    categoryKey: "bebidas",
    name: "Guaran\u00E1 Antarctica Lata",
    short_desc: "Refrigerante Guaran\u00E1 Antarctica em lata 350ml.",
    ingredients: "\u00C1gua gaseificada, a\u00E7\u00FAcar e extrato de guaran\u00E1.",
    price_cents: 550,
    image_url: "/img/GuaranaLata.png",
  },
  {
    categoryKey: "bebidas",
    name: "Suco de Laranja",
    short_desc: "Suco de laranja gelado e refrescante.",
    ingredients: "Suco de laranja.",
    price_cents: 800,
    image_url: "/img/sucoDeLaranja-removebg-preview.png",
  },
];

const legacyItemsWithoutMatchingImage = [
  "A\u00E7a\u00ED Tradicional",
  "Soda Lim\u00E3o Lata",
];

async function main() {
  console.log("Start seeding...");

  const categoryMap = new Map();

  for (const category of categories) {
    const upsertedCategory = await prisma.categories.upsert({
      where: { name: category.name },
      update: { name: category.name },
      create: { name: category.name },
    });

    categoryMap.set(category.key, upsertedCategory);
    console.log(`Category ready: ${upsertedCategory.name}`);
  }

  for (const item of menuItems) {
    const category = categoryMap.get(item.categoryKey);

    if (!category) {
      throw new Error(`Category not found for key: ${item.categoryKey}`);
    }

    const upsertedItem = await prisma.items.upsert({
      where: { name: item.name },
      update: {
        category_id: category.id,
        short_desc: item.short_desc,
        ingredients: item.ingredients,
        price_cents: item.price_cents,
        image_url: item.image_url,
        active: true,
      },
      create: {
        category_id: category.id,
        name: item.name,
        short_desc: item.short_desc,
        ingredients: item.ingredients,
        price_cents: item.price_cents,
        image_url: item.image_url,
        active: true,
      },
    });

    console.log(`Item ready: ${upsertedItem.name}`);
  }

  const deactivatedItems = await prisma.items.updateMany({
    where: {
      name: {
        in: legacyItemsWithoutMatchingImage,
      },
    },
    data: {
      active: false,
    },
  });

  console.log(
    `Legacy items disabled because they do not have a matching image: ${deactivatedItems.count}`
  );
  console.log("Seeding finished.");
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
