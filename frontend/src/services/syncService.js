import { db } from './db';
import http from '../utils/http';

class SyncService {
    constructor() {
        this.syncInProgress = false;
        this.syncQueue = [];
        this.lastSyncTime = null;
    }

    async queueForSync(operation) {
        await db.syncQueue.add({
            operation: operation.type,
            data: operation.data,
            status: 'pending',
            created_at: new Date()
        });

        // Try to sync immediately if online
        if (navigator.onLine) {
            this.processQueue();
        }
    }

    async processQueue() {
        if (this.syncInProgress) return;
        this.syncInProgress = true;

        try {
            const pendingOperations = await db.syncQueue
                .where('status')
                .equals('pending')
                .toArray();

            if (pendingOperations.length > 0) {
                console.log(`Processing ${pendingOperations.length} pending operations`);
                
                for (const operation of pendingOperations) {
                    try {
                        await this.processOperation(operation);
                        await db.syncQueue.update(operation.id, { 
                            status: 'completed',
                            completed_at: new Date()
                        });
                        
                        // Emit sync success event
                        window.dispatchEvent(new CustomEvent('sync-operation-completed', {
                            detail: {
                                operation: operation.operation,
                                timestamp: new Date().toISOString()
                            }
                        }));
                    } catch (error) {
                        console.error('Sync operation failed:', error);
                        await db.syncQueue.update(operation.id, { 
                            status: 'failed',
                            error: error.message
                        });
                    }
                }
            }
        } finally {
            this.syncInProgress = false;
            this.lastSyncTime = new Date().toISOString();
        }
    }

    async processOperation(operation) {
        switch (operation.operation) {
            case 'CREATE_LOAN':
                return await this.syncCreateLoan(operation.data);
            case 'UPDATE_LOAN':
                return await this.syncUpdateLoan(operation.data);
            case 'CREATE_CUSTOMER':
                return await this.syncCreateCustomer(operation.data);
            case 'UPDATE_CUSTOMER':
                return await this.syncUpdateCustomer(operation.data);
            case 'CREATE_ITEM':
                return await this.syncCreateItem(operation.data);
            case 'UPDATE_ITEM':
                return await this.syncUpdateItem(operation.data);
            case 'CREATE_CATEGORY':
                return await this.syncCreateCategory(operation.data);
            case 'UPDATE_CATEGORY':
                return await this.syncUpdateCategory(operation.data);
            case 'RENEW_LOAN':
                return await this.syncRenewLoan(operation.data);
            case 'REDEEM_LOAN':
                return await this.syncRedeemLoan(operation.data);
            case 'FORFEIT_LOAN':
                return await this.syncForfeitLoan(operation.data);
            case 'MARK_ITEM_SOLD':
                return await this.syncMarkItemSold(operation.data);
            case 'PROCESS_FORFEITED_ITEM':
                return await this.syncProcessForfeited(operation.data);
            default:
                throw new Error(`Unknown operation type: ${operation.operation}`);
        }
    }

    async syncCreateLoan(loanData) {
        const { items, ...loan } = loanData;
        const response = await http.post('/api/loans', {
            ...loan,
            items: items
        });
        
        const serverLoan = response.data.data;
        
        // Update loan in local DB
        await db.loans.where('uuid').equals(loanData.uuid)
            .modify({
                sync_status: 'synced',
                server_id: serverLoan.id,
                ...serverLoan
            });
            
        // Update items in local DB
        if (serverLoan.items?.length) {
            await Promise.all(serverLoan.items.map(async serverItem => {
                const localItem = items.find(item => item.description === serverItem.description);
                if (localItem) {
                    await db.items.where('uuid').equals(localItem.uuid)
                        .modify({
                            sync_status: 'synced',
                            server_id: serverItem.id,
                            ...serverItem
                        });
                }
            }));
        }
    }

    async syncCreateCustomer(customerData) {
        const response = await http.post('/api/customers', customerData);
        await db.customers.where('uuid').equals(customerData.uuid)
            .modify({
                sync_status: 'synced',
                server_id: response.data.id
            });
    }

    async syncUpdateCustomer(customerData) {
        const { uuid, ...data } = customerData;
        const response = await http.put(`/api/customers/${uuid}`, data);
        await db.customers.where('uuid').equals(uuid)
            .modify({
                sync_status: 'synced',
                ...response.data
            });
    }

    async syncCreateItem(itemData) {
        const response = await http.post('/api/items', itemData);
        await db.items.where('uuid').equals(itemData.uuid)
            .modify({
                sync_status: 'synced',
                server_id: response.data.id
            });
    }

    async syncUpdateItem(itemData) {
        const { uuid, ...data } = itemData;
        const response = await http.put(`/api/items/${uuid}`, data);
        await db.items.where('uuid').equals(uuid)
            .modify({
                sync_status: 'synced',
                ...response.data
            });
    }

    async syncCreateCategory(categoryData) {
        try {
            const response = await http.post('/api/categories', categoryData);
            const serverCategory = response.data.data;
            
            await db.categories.where('uuid').equals(categoryData.uuid)
                .modify({
                    sync_status: 'synced',
                    ...serverCategory
                });

            return serverCategory;
        } catch (error) {
            console.error('Error syncing category creation:', error);
            throw error;
        }
    }

    async syncUpdateCategory(categoryData) {
        try {
            const { uuid, ...data } = categoryData;
            const response = await http.put(`/api/categories/${uuid}`, data);
            const serverCategory = response.data.data;
            
            await db.categories.where('uuid').equals(uuid)
                .modify({
                    sync_status: 'synced',
                    ...serverCategory
                });

            return serverCategory;
        } catch (error) {
            console.error('Error syncing category update:', error);
            throw error;
        }
    }

    async syncRenewLoan(data) {
        const { uuid, new_loan, ...renewalData } = data;
        renewalData.new_uuid = new_loan.uuid;
        
        // Sync with server
        const response = await http.post(`/api/loans/${uuid}/renew`, renewalData);
        const serverLoan = response.data.data;
        
        // Update the original loan
        await db.loans.where('uuid').equals(uuid)
            .modify({
                sync_status: 'synced',
                status: 'renewed'
            });

        // Update the new loan with server data
        await db.loans.where('uuid').equals(new_loan.uuid)
            .modify({
                ...serverLoan,
                sync_status: 'synced'
            });

        return serverLoan;
    }

    async syncRedeemLoan(data) {
        const { uuid, ...redemptionData } = data;
        const response = await http.post(`/api/loans/${uuid}/redeem`, redemptionData);
        const serverLoan = response.data.data;
        
        await db.loans.where('uuid').equals(uuid)
            .modify({
                ...serverLoan,
                sync_status: 'synced'
            });

        return serverLoan;
    }

    async syncForfeitLoan(data) {
        const { uuid, ...forfeitData } = data;
        const response = await http.post(`/api/loans/${uuid}/forfeit`, forfeitData);
        const serverLoan = response.data.data;
        
        await db.loans.where('uuid').equals(uuid)
            .modify({
                ...serverLoan,
                sync_status: 'synced'
            });

        return serverLoan;
    }

    async syncMarkItemSold(data) {
        const { uuid, ...saleData } = data;
        try {
            // Call the mark-as-sold endpoint
            const response = await http.post(`/api/items/${uuid}/mark-as-sold`, {
                final_selling_price: saleData.final_selling_price,
                buyer_name: saleData.buyer_name,
                buyer_contact: saleData.buyer_contact,
                sale_notes: saleData.sale_notes
            });
            const serverItem = response.data.data;
            
            // Update local item with server response
            await db.items.where('uuid').equals(uuid)
                .modify({
                    ...serverItem,
                    sync_status: 'synced',
                    updated_at: serverItem.updated_at || new Date().toISOString()
                });

            // Emit update event
            window.dispatchEvent(new CustomEvent('item-sold', {
                detail: { item: serverItem }
            }));

            return serverItem;
        } catch (error) {
            console.error('Error syncing item sale:', error);
            throw error;
        }
    }

    async syncProcessForfeited(data) {
        const { uuid, ...processData } = data;
        try {
            // Call the process-forfeited endpoint
            const response = await http.put(`/api/items/${uuid}/process-forfeited`, processData);
            const serverItem = response.data.data;
            
            // Update local item with server response
            await db.items.where('uuid').equals(uuid)
                .modify({
                    ...serverItem,
                    sync_status: 'synced',
                    updated_at: serverItem.updated_at || new Date().toISOString()
                });

            // Emit update event
            window.dispatchEvent(new CustomEvent('item-processed', {
                detail: { item: serverItem }
            }));

            return serverItem;
        } catch (error) {
            console.error('Error syncing forfeited item processing:', error);
            throw error;
        }
    }

    async syncUpdateLoan(data) {
        const { uuid, ...loanData } = data;
        
        // Sync loan data including items
        const response = await http.put(`/api/loans/${uuid}`, loanData);
        const serverLoan = response.data.data;
        
        // Update loan in local DB
        await db.loans.where('uuid').equals(uuid)
            .modify({
                sync_status: 'synced',
                server_id: serverLoan.id,
                ...serverLoan
            });

        // Update items in local DB if server returned them
        if (serverLoan.items?.length) {
            await Promise.all(serverLoan.items.map(async serverItem => {
                await db.items.where('uuid').equals(serverItem.uuid)
                    .modify({
                        sync_status: 'synced',
                        server_id: serverItem.id,
                        ...serverItem
                    });
            }));
        }

        return serverLoan;
    }

    async retryFailedOperations() {
        const failedOperations = await db.syncQueue
            .where('status')
            .equals('failed')
            .toArray();

        for (const operation of failedOperations) {
            try {
                await this.processOperation(operation);
                await db.syncQueue.update(operation.id, { status: 'completed' });
            } catch (error) {
                console.error('Retry failed for operation:', operation, error);
            }
        }
    }
}

export const syncService = new SyncService();

window.addEventListener('online', () => {
    console.log('Back online, processing sync queue...');
    syncService.processQueue();
    syncService.retryFailedOperations();
});