document.addEventListener('DOMContentLoaded', () => {
    const ordersContainer = document.getElementById('orders-container');
    const API_BASE_URL = '/api'; // Assuming API is served from /api

    // Function to check for JWT token and redirect if not found
    function getAuthToken() {
        return localStorage.getItem('admin_jwt_token');
    }

    function redirectToLogin() {
        window.location.href = '/admin.html'; // Redirect to admin login page
    }

    async function fetchPaidOrders() {
        const token = getAuthToken();
        if (!token) {
            alert('Você precisa estar logado como administrador para acessar esta página.');
            redirectToLogin();
            return;
        }

        try {
            const response = await fetch(`${API_BASE_URL}/admin/paid-orders`, {
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
            console.error('Erro ao buscar pedidos pagos:', error);
            ordersContainer.innerHTML = '<p class="text-danger">Erro ao carregar pedidos. Tente novamente mais tarde.</p>';
        }
    }

    function displayOrders(orders) {
        ordersContainer.innerHTML = ''; // Clear loading message

        if (orders.length === 0) {
            ordersContainer.innerHTML = '<p>Nenhum pedido ativo encontrado.</p>';
            return;
        }

        orders.forEach(order => {
            const orderCard = document.createElement('div');
            orderCard.className = 'order-card shadow-sm';
            orderCard.innerHTML = `
                <h5>Pedido #${order.id}</h5>
                <p><strong>Cliente:</strong> ${order.customer_name || 'N/A'}</p>
                <p><strong>Mesa:</strong> ${order.customer_table || 'N/A'}</p>
                <p><strong>Status:</strong> <span class="badge badge-info">${order.status}</span></p>
                <p><strong>Total:</strong> R$ ${(order.total_cents / 100).toFixed(2)}</p>
                <p><strong>Data:</strong> ${new Date(order.created_at).toLocaleString()}</p>
                <h6>Itens do Pedido:</h6>
                <ul class="list-unstyled">
                    ${order.items.map(item => `
                        <li class="order-item d-flex align-items-center">
                            ${item.image_url ? `<img src="${item.image_url}" alt="${item.name}" class="item-image">` : ''}
                            <div>
                                <strong>${item.qty}x ${item.name}</strong> - R$ ${(item.unit_price_cents / 100).toFixed(2)} cada
                                ${item.options && item.options.length > 0 ?
                                    `<br><small>Opções: ${item.options.map(opt => opt.name + ': ' + opt.value).join(', ')}</small>` : ''}
                            </div>
                        </li>
                    `).join('')}
                </ul>
                <button class="btn btn-primary btn-sm mt-3 update-status-btn" data-order-id="${order.id}" data-current-status="${order.status}">Atualizar Status</button>
            `;
            ordersContainer.appendChild(orderCard);
        });

        // Add event listeners for update status buttons
        document.querySelectorAll('.update-status-btn').forEach(button => {
            button.addEventListener('click', (event) => {
                const orderId = event.target.dataset.orderId;
                const currentStatus = event.target.dataset.currentStatus;
                showUpdateStatusModal(orderId, currentStatus);
            });
        });
    }

    // Placeholder for a modal to update status (can be implemented with Bootstrap modal)
    function showUpdateStatusModal(orderId, currentStatus) {
        const newStatus = prompt(`Atualizar status do Pedido #${orderId} (Atual: ${currentStatus}).\nDigite o novo status (Em preparo, Pronto, Entregue):`);
        if (newStatus) {
            updateOrderStatus(orderId, newStatus);
        }
    }

    async function updateOrderStatus(orderId, newStatus) {
        const token = getAuthToken();
        if (!token) {
            redirectToLogin();
            return;
        }

        // Basic validation for allowed statuses
        const allowedStatuses = ['Em preparo', 'Pronto', 'Entregue', 'Recebido'];
        if (!allowedStatuses.includes(newStatus)) {
            alert('Status inválido. Use "Recebido", "Em preparo", "Pronto" ou "Entregue".');
            return;
        }

        try {
            const response = await fetch(`${API_BASE_URL}/admin/orders/${orderId}/status`, {
                method: 'PATCH',
                headers: {
                    'Authorization': `Bearer ${token}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ status: newStatus })
            });

            if (response.status === 401) {
                alert('Sessão expirada ou não autorizada. Por favor, faça login novamente.');
                redirectToLogin();
                return;
            }

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            alert(`Status do Pedido #${orderId} atualizado para ${newStatus} com sucesso!`);
            fetchPaidOrders(); // Refresh the list

        } catch (error) {
            console.error('Erro ao atualizar status do pedido:', error);
            alert('Erro ao atualizar status do pedido. Tente novamente.');
        }
    }


    fetchPaidOrders();
});
