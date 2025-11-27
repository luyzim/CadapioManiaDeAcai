document.addEventListener('DOMContentLoaded', () => {
  const cartItemsContainer = document.getElementById('cart-items-container');
  const cartSummaryContainer = document.getElementById('cart-summary');

  function centsToBRL(cents) {
    return (cents / 100).toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
  }

  async function renderCart() {
    const cart = await fetchCart();
    cartItemsContainer.innerHTML = '';

    if (!cart || cart.length === 0) {
      cartItemsContainer.innerHTML = `
        <div class="rounded-2xl border border-white/10 bg-white/5 p-8 text-center text-white/70">
          Seu carrinho está vazio.
          <a href="/cardapio" class="mt-4 inline-block rounded-lg bg-fuchsia-600 px-5 py-2.5 text-sm font-bold text-white transition hover:bg-fuchsia-700">Ver Cardápio</a>
        </div>
      `;
      cartSummaryContainer.innerHTML = '';
      return;
    }

    cart.forEach(item => {
      const cartItemElement = document.createElement('div');
      cartItemElement.className = 'flex items-center justify-between gap-4 rounded-2xl border border-white/10 bg-white/5 p-4';
      cartItemElement.innerHTML = `
        <div class="flex items-center gap-4">
          <img src="${item.image_url || 'https://picsum.photos/seed/acai/100/100'}" alt="${item.name}" class="h-16 w-16 rounded-lg object-cover">
          <div>
            <h3 class="font-semibold text-white/95">${item.name}</h3>
            <p class="text-sm text-white/70">${centsToBRL(item.price_cents)}</p>
          </div>
        </div>
        <div class="flex items-center gap-4">
          <div class="flex items-center gap-2">
            <button data-item-id="${item.item_id}" data-quantity="${item.quantity - 1}" class="update-qty-btn h-8 w-8 rounded-full bg-white/10 text-lg transition hover:bg-white/20">-</button>
            <span class="w-8 text-center">${item.quantity}</span>
            <button data-item-id="${item.item_id}" data-quantity="${item.quantity + 1}" class="update-qty-btn h-8 w-8 rounded-full bg-white/10 text-lg transition hover:bg-white/20">+</button>
          </div>
          <button data-item-id="${item.item_id}" class="remove-item-btn text-red-400 hover:text-red-300">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
          </button>
        </div>
      `;
      cartItemsContainer.appendChild(cartItemElement);
    });

    const total = cart.reduce((sum, item) => sum + item.price_cents * item.quantity, 0);
    document.getElementById('cart-total-display').textContent = centsToBRL(total);

    // The "Finalizar Pedido" button is now static in HTML, no need to generate it here.
    // Ensure it's enabled/disabled based on cart content if needed.
    const checkoutButton = document.querySelector('#cart-summary a');
    if (checkoutButton) {
        checkoutButton.classList.toggle('pointer-events-none', cart.length === 0);
        checkoutButton.classList.toggle('opacity-50', cart.length === 0);
    }

    addEventListeners();
  }

  function addEventListeners() {
    document.querySelectorAll('.update-qty-btn').forEach(button => {
      button.onclick = async (e) => {
        const itemId = e.currentTarget.dataset.itemId;
        const quantity = parseInt(e.currentTarget.dataset.quantity);
        if (quantity === 0) {
          await removeItem(itemId);
        } else {
          await updateQuantity(itemId, quantity);
        }
        renderCart();
      };
    });

    document.querySelectorAll('.remove-item-btn').forEach(button => {
      button.onclick = async (e) => {
        const itemId = e.currentTarget.dataset.itemId;
        await removeItem(itemId);
        renderCart();
      };
    });
  }

  async function fetchCart() {
    try {
      const res = await fetch('/api/cart');
      if (!res.ok) throw new Error('Falha ao buscar o carrinho.');
      return await res.json();
    } catch (e) {
      console.error(e);
      cartItemsContainer.innerHTML = `<div class="text-red-400">${e.message}</div>`;
      return [];
    }
  }

  async function updateQuantity(itemId, quantity) {
    try {
      await fetch(`/api/cart/${itemId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ quantity })
      });
    } catch (e) {
      console.error('Falha ao atualizar a quantidade:', e);
    }
  }

  async function removeItem(itemId) {
    try {
      await fetch(`/api/cart/${itemId}`, { method: 'DELETE' });
    } catch (e) {
      console.error('Falha ao remover o item:', e);
    }
  }

  renderCart();
});
