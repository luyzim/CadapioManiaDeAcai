const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Start seeding...');

  // Create Categories
  const acaiCategory = await prisma.categories.upsert({
    where: { name: 'Açaí' },
    update: {},
    create: { name: 'Açaí' },
  });
  console.log(`Created category: ${acaiCategory.name}`);

  const bebidasCategory = await prisma.categories.upsert({
    where: { name: 'Bebidas' },
    update: {},
    create: { name: 'Bebidas' },
  });
  console.log(`Created category: ${bebidasCategory.name}`);

  // Create Açaí Items with Options
  const acaiItem = await prisma.items.upsert({
    where: { name: 'Açaí Tradicional' },
    update: {},
    create: {
      category_id: acaiCategory.id,
      name: 'Açaí Tradicional',
      short_desc: 'Açaí puro e cremoso',
      ingredients: 'Açaí, xarope de guaraná',
      price_cents: 1000, // Base price for small size
      image_url: '/img/acai_tradicional.jpg',
      active: true,
      item_options: {
        create: [
          { name: 'Tamanho', value: 'Pequeno', add_price_cents: 0 }, // 10.00
          { name: 'Tamanho', value: 'Médio', add_price_cents: 500 }, // 15.00
          { name: 'Tamanho', value: 'Grande', add_price_cents: 1000 }, // 20.00
        ],
      },
    },
    include: {
      item_options: true,
    },
  });
  console.log(`Created item: ${acaiItem.name} with options`);

  const acaiMorango = await prisma.items.upsert({
    where: { name: 'Açaí com Morango e Ninho' },
    update: {},
    create: {
      category_id: acaiCategory.id,
      name: 'Açaí com Morango e Ninho',
      short_desc: 'Açaí com morangos frescos e leite em pó',
      ingredients: 'Açaí, morango, leite em pó',
      price_cents: 1500,
      image_url: '/img/AcaiMorangoComNinho.jpg',
      active: true,
    },
  });
  console.log(`Created item: ${acaiMorango.name}`);

  const acaiUva = await prisma.items.upsert({
    where: { name: 'Açaí com Uva e Nutella' },
    update: {},
    create: {
      category_id: acaiCategory.id,
      name: 'Açaí com Uva e Nutella',
      short_desc: 'Açaí com uvas e um delicioso creme de avelã',
      ingredients: 'Açaí, uva, Nutella',
      price_cents: 1600,
      image_url: '/img/AcaiUvaComNutella.jpeg',
      active: true,
    },
  });
  console.log(`Created item: ${acaiUva.name}`);

  // Create Soda Items
  const cocaCola = await prisma.items.upsert({
    where: { name: 'Coca-Cola Lata' },
    update: { image_url: '/img/CocaCola.png' },
    create: {
      category_id: bebidasCategory.id,
      name: 'Coca-Cola Lata',
      short_desc: 'Refrigerante Coca-Cola em lata 350ml',
      ingredients: 'Água gaseificada, açúcar, extrato de noz de cola',
      price_cents: 600,
      image_url: '/img/CocaCola.png',
      active: true,
    },
  });
  console.log(`Created item: ${cocaCola.name}`);

  const guarana = await prisma.items.upsert({
    where: { name: 'Guaraná Antarctica Lata' },
    update: { image_url: '/img/Guarana.png' },
    create: {
      category_id: bebidasCategory.id,
      name: 'Guaraná Antarctica Lata',
      short_desc: 'Refrigerante Guaraná Antarctica em lata 350ml',
      ingredients: 'Água gaseificada, açúcar, extrato de guaraná',
      price_cents: 550,
      image_url: '/img/Guarana.png',
      active: true,
    },
  });
  console.log(`Created item: ${guarana.name}`);

  const sodaLimao = await prisma.items.upsert({
    where: { name: 'Soda Limão Lata' },
    update: {},
    create: {
      category_id: bebidasCategory.id,
      name: 'Soda Limão Lata',
      short_desc: 'Refrigerante Soda Limão em lata 350ml',
      ingredients: 'Água gaseificada, açúcar, suco de limão',
      price_cents: 500,
      image_url: '/img/soda_limao.jpg', // Assuming a generic image or placeholder
      active: true,
    },
  });
  console.log(`Created item: ${sodaLimao.name}`);

  console.log('Seeding finished.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
