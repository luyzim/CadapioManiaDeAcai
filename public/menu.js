document.addEventListener('DOMContentLoaded', () => {
  const menuGrid = document.getElementById('menu-grid');
  const categoriesContainer = document.getElementById('categories-container');
  const searchInput = document.getElementById('search-query');
  const searchInputMobile = document.getElementById('search-query-mobile');
  const modal = document.getElementById('modal');
  const modalOverlay = document.getElementById('modal-overlay');
  const modalContent = document.getElementById('modal-content');

  let allData = null;
  let activeCat = 'todas';
  let query = '';

  function centsToBRL(cents) {
    return (cents / 100).toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
  }

  function renderMenu() {
    if (!allData) return;

    const filteredItems = allData.categories.flatMap(c => c.items.map(i => ({ ...i, categoryName: c.name })))
      .filter(it => {
        const byCat = activeCat === 'todas' || it.categoryName === activeCat;
        const q = query.trim().toLowerCase();
        const byQuery = !q || it.name.toLowerCase().includes(q) || (it.short_desc || '').toLowerCase().includes(q) || (it.ingredients || '').toLowerCase().includes(q);
        return byCat && byQuery && it.active !== false;
      });

    menuGrid.innerHTML = '';
    if (filteredItems.length === 0) {
      menuGrid.innerHTML = `<div class="col-span-full rounded-2xl border border-white/10 bg-white/5 p-8 text-center text-white/70">Nenhum item encontrado.</div>`;
      return;
    }

    filteredItems.forEach(it => {
      const itemElement = document.createElement('button');
      itemElement.className = 'group overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-b from-white/10 to-white/5 text-left transition hover:translate-y-[-2px] hover:shadow-xl hover:shadow-fuchsia-900/20';
      itemElement.onclick = () => openModal(it);
      const addButton = document.createElement('button');
      addButton.className = 'mt-4 w-full rounded-lg bg-fuchsia-600 px-4 py-2 text-sm font-bold text-white transition hover:bg-fuchsia-700';
      addButton.textContent = 'Adicionar ao Carrinho';
      addButton.onclick = (e) => {
        e.stopPropagation();
        addToCart(it);
      };

      const itemContent = document.createElement('div');
      itemContent.innerHTML = `
        <div class="relative h-44 w-full overflow-hidden">
          <img src="${it.image_url || 'https://picsum.photos/seed/acai/800/600'}" alt="${it.name}" class="h-full w-full object-cover transition duration-300 group-hover:scale-105" loading="lazy">
          <div class="absolute inset-0 bg-gradient-to-t from-[#0b0316] via-transparent/40 to-transparent"></div>
          <span class="absolute left-3 top-3 rounded-full bg-fuchsia-600/80 px-3 py-1 text-xs font-medium shadow-md">${it.categoryName || 'Açaí'}</span>
        </div>
        <div class="p-4">
          <h3 class="line-clamp-1 text-base font-semibold text-white/95">${it.name}</h3>
          ${it.short_desc ? `<p class="mt-1 line-clamp-2 text-sm text-white/70">${it.short_desc}</p>` : ''}
          <div class="mt-3 flex items-center justify-between">
            <span class="rounded-lg bg-white/5 px-2 py-1 text-sm text-white/80">${centsToBRL(it.price_cents || 0)}</span>
            <span class="text-xs text-white/50">Toque para detalhes</span>
          </div>
        </div>
      `;
      itemElement.appendChild(itemContent);
      itemElement.appendChild(addButton);
      menuGrid.appendChild(itemElement);
    });
  }

  async function addToCart(item) {
    try {
      const res = await fetch('/api/cart', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ itemId: item.id, quantity: 1 })
      });
      if (!res.ok) {
        throw new Error('Falha ao adicionar ao carrinho.');
      }
      // Simple feedback. A more sophisticated UI could show a toast notification.
      alert(`${item.name} foi adicionado ao carrinho!`);
    } catch (e) {
      console.error(e);
      alert(e.message);
    }
  }

  function renderCategories() {
    if (!allData) return;
    categoriesContainer.innerHTML = '';
    const allButton = document.createElement('button');
    allButton.className = `snap-start rounded-full border px-4 py-2 text-sm transition ${activeCat === 'todas' ? 'border-fuchsia-400/50 bg-fuchsia-400/10 text-fuchsia-100' : 'border-white/10 bg-white/5 text-white/80 hover:bg-white/10'}`;
    allButton.textContent = 'Todas';
    allButton.onclick = () => {
      activeCat = 'todas';
      renderCategories();
      renderMenu();
    };
    categoriesContainer.appendChild(allButton);

    allData.categories.forEach(c => {
      const catButton = document.createElement('button');
      catButton.className = `snap-start rounded-full border px-4 py-2 text-sm transition ${activeCat === c.name ? 'border-fuchsia-400/50 bg-fuchsia-400/10 text-fuchsia-100' : 'border-white/10 bg-white/5 text-white/80 hover:bg-white/10'}`;
      catButton.textContent = c.name;
      catButton.onclick = () => {
        activeCat = c.name;
        renderCategories();
        renderMenu();
      };
      categoriesContainer.appendChild(catButton);
    });
  }

  function openModal(item) {
    modalContent.innerHTML = `
      <button id="close-modal" class="absolute right-3 top-3 rounded-full border border-white/20 bg-black/30 px-3 py-1 text-xs text-white/80 hover:bg-black/50">Fechar</button>
      <div class="grid grid-cols-1 md:grid-cols-2">
        <div class="relative h-64 w-full md:h-full">
          <img src="${item.image_url || 'https://picsum.photos/seed/acai/800/600'}" alt="${item.name}" class="h-full w-full object-cover" loading="lazy">
          <div class="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-transparent"></div>
        </div>
        <div class="p-6">
          <h3 class="text-xl font-semibold text-white/95">${item.name}</h3>
          <p class="mt-1 text-sm text-white/70">${item.short_desc}</p>
          <div class="mt-4 space-y-1 text-sm text-white/75">
            <p class="text-white/60">Ingredientes:</p>
            <p class="leading-relaxed">${item.ingredients || '—'}</p>
          </div>
          <div class="mt-6 flex items-center justify-between">
            <span class="text-lg font-semibold text-fuchsia-200">${centsToBRL(item.price_cents || 0)}</span>
          </div>
        </div>
      </div>
    `;
    modal.classList.remove('hidden');
    document.getElementById('close-modal').onclick = closeModal;
  }

  function closeModal() {
    modal.classList.add('hidden');
  }

  modalOverlay.onclick = closeModal;

  searchInput.addEventListener('input', (e) => {
    query = e.target.value;
    renderMenu();
  });
  searchInputMobile.addEventListener('input', (e) => {
    query = e.target.value;
    renderMenu();
  });

  async function fetchData() {
    try {
      const res = await fetch("/api/menu");
      if (!res.ok) throw new Error("Falha ao carregar o cardápio");
      allData = await res.json();
      renderCategories();
      renderMenu();
    } catch (e) {
      console.error(e);
      menuGrid.innerHTML = `<div class="col-span-full rounded-xl border border-yellow-500/30 bg-yellow-500/10 p-3 text-sm text-yellow-100">${e.message}</div>`;
    }
  }

  fetchData();
});