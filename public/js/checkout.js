document.addEventListener('DOMContentLoaded', () => {
    const cartItemsList = document.getElementById('cart-items-list');
    const cartTotalSpan = document.getElementById('cart-total');
    const checkoutForm = document.getElementById('checkout-form');
    const checkoutMessage = document.getElementById('checkout-message');
    const API_BASE_URL = '/api';

    let cartData = []; // To store fetched cart items

    async function fetchCartItems() {
        try {
            const response = await fetch(`${API_BASE_URL}/cart`);
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            cartData = await response.json();
            displayCartItems(cartData);
        } catch (error) {
            console.error('Erro ao buscar itens do carrinho:', error);
            cartItemsList.innerHTML = '<p class="text-danger">Erro ao carregar carrinho.</p>';
        }
    }

    function displayCartItems(items) {
        cartItemsList.innerHTML = '';
        let total = 0;

        if (items.length === 0) {
            cartItemsList.innerHTML = '<p>Seu carrinho está vazio.</p>';
            checkoutForm.querySelector('button[type="submit"]').disabled = true;
            return;
        }

        items.forEach(item => {
            const itemDiv = document.createElement('div');
            itemDiv.className = 'cart-item';
            itemDiv.innerHTML = `
                ${item.image_url ? `<img src="${item.image_url}" alt="${item.name}" class="item-image">` : ''}
                <div>
                    <h6>${item.name}</h6>
                    <p class="mb-1">Quantidade: ${item.quantity}</p>
                    <p class="mb-0">Preço Unitário: R$ ${(item.price_cents / 100).toFixed(2)}</p>
                    <p class="mb-0">Subtotal: R$ ${((item.price_cents * item.quantity) / 100).toFixed(2)}</p>
                </div>
            `;
            cartItemsList.appendChild(itemDiv);
            total += item.price_cents * item.quantity;
        });

        cartTotalSpan.textContent = (total / 100).toFixed(2);
    }

    async function clearCart() {
        try {
            const response = await fetch(`${API_BASE_URL}/cart`, {
                method: 'DELETE'
            });
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            console.log('Carrinho limpo com sucesso.');
        } catch (error) {
            console.error('Erro ao limpar carrinho:', error);
            // Don't block order finalization if cart clear fails
        }
    }

    checkoutForm.addEventListener('submit', async (event) => {
        event.preventDefault();
        checkoutMessage.innerHTML = '';
        checkoutForm.querySelector('button[type="submit"]').disabled = true;

        const customer_name = document.getElementById('customer_name').value;
        const customer_table = document.getElementById('customer_table').value;
        const delivery_address = document.getElementById('delivery_address').value;
        const delivery_city = document.getElementById('delivery_city').value;
        const delivery_state = document.getElementById('delivery_state').value;
        const delivery_zip_code = document.getElementById('delivery_zip_code').value;

        if (cartData.length === 0) {
            checkoutMessage.innerHTML = '<p class="text-danger">Seu carrinho está vazio. Adicione itens antes de finalizar o pedido.</p>';
            checkoutForm.querySelector('button[type="submit"]').disabled = false;
            return;
        }

        const orderItems = cartData.map(item => ({
            item_id: item.item_id,
            qty: item.quantity,
            // Assuming options are not handled in cart for simplicity, or need to be fetched
            // selected_options: item.options // if options were stored in cart
        }));

        const orderPayload = {
            customer_name,
            customer_table: customer_table || null,
            delivery_address,
            delivery_city,
            delivery_state,
            delivery_zip_code,
            items: orderItems
        };

        try {
            const token = localStorage.getItem('token');
            const response = await fetch(`${API_BASE_URL}/orders`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'x-authorization': `Bearer ${token}`
                },
                body: JSON.stringify(orderPayload)
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
            }

            const result = await response.json();
            checkoutMessage.innerHTML = `<p class="text-success">Pedido #${result.id} finalizado com sucesso! Total: R$ ${(result.total_cents / 100).toFixed(2)}</p>`;
            
            await clearCart(); // Clear cart after successful order
            
            // Optionally redirect or show a success page
            alert('Pedido finalizado com sucesso! Você será redirecionado para a página inicial.');
            window.location.href = '/home.html'; // Redirect to home or a confirmation page

        } catch (error) {
            console.error('Erro ao finalizar pedido:', error);
            checkoutMessage.innerHTML = `<p class="text-danger">Erro ao finalizar pedido: ${error.message}.</p>`;
        } finally {
            checkoutForm.querySelector('button[type="submit"]').disabled = false;
        }
    });

    fetchCartItems();
});
