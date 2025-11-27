document.addEventListener('DOMContentLoaded', () => {
    const ordersContainer = document.getElementById('delivery-orders-container');
    const API_BASE_URL = '/api';

    function getAuthToken() {
        return localStorage.getItem('admin_jwt_token');
    }

    function redirectToLogin() {
        window.location.href = '/admin.html';
    }

    async function fetchDeliveryOrders() {
        const token = getAuthToken();
        if (!token) {
            alert('Você precisa estar logado como administrador para acessar esta página.');
            redirectToLogin();
            return;
        }

        try {
            const response = await fetch(`${API_BASE_URL}/admin/delivery-orders`, {
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                }
            });

            if (response.status === 401) {
                alert('Sessão expirada ou não autorizada. Por favor, faça login novamente.');
                redirectToLogin();
                return;
            }

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const orders = await response.json();
            displayOrders(orders);

        } catch (error) {
            console.error('Erro ao buscar pedidos para entrega:', error);
            ordersContainer.innerHTML = '<p class="text-danger">Erro ao carregar pedidos. Tente novamente mais tarde.</p>';
        }
    }

    function displayOrders(orders) {
        ordersContainer.innerHTML = '';

        if (orders.length === 0) {
            ordersContainer.innerHTML = '<p>Nenhum pedido com status "Pronto" encontrado.</p>';
            return;
        }

        orders.forEach(order => {
            const orderCard = document.createElement('div');
            orderCard.className = 'order-card shadow-sm';
            orderCard.innerHTML = `
                <h5>Pedido #${order.id}</h5>
                <p><strong>Cliente:</strong> ${order.customer_name || 'N/A'}</p>
                <p><strong>Mesa:</strong> ${order.customer_table || 'N/A'}</p>
                <p><strong>Status:</strong> <span class="badge badge-success">${order.status}</span></p>
                <p><strong>Total:</strong> R$ ${(order.total_cents / 100).toFixed(2)}</p>
                <p><strong>Data:</strong> ${new Date(order.created_at).toLocaleString()}</p>
                <h6>Itens do Pedido:</h6>
                <ul class="list-unstyled">
                    ${order.items.map(item => `
                        <li class="order-item d-flex align-items-center">
                            ${item.image_url ? `<img src="${item.image_url}" alt="${item.name}" class="item-image">` : ''}
                            <div>
                                <strong>${item.qty}x ${item.name}</strong> - R$ ${(item.unit_price_cents / 100).toFixed(2)} cada
                            </div>
                        </li>
                    `).join('')}
                </ul>
            `;
            ordersContainer.appendChild(orderCard);
        });
    }

    fetchDeliveryOrders();
    
    // Refresh the list every 15 seconds
    setInterval(fetchDeliveryOrders, 15000);
});
