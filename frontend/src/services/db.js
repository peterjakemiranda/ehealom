import { useAuthStore } from '@/stores/auth';
import http from '@/utils/http';
import Dexie from 'dexie';

export class AppDatabase extends Dexie {
    constructor() {
        super('PawnshopDB');
        
        // Delete existing database on version conflicts
        this.on('blocked', () => this.close());
        
        // Define version 11 with new schema (clean slate approach)
        this.version(11).stores({
            customers: 'uuid, id, sync_status, last_synced_at, &created_at, *searchTerms, [last_name+first_name]',
            loans: 'uuid, id, customer_uuid, status, sync_status, last_synced_at, &created_at, [customer_uuid+status], [status+loan_date]',
            items: 'uuid, id, loan_uuid, customer_uuid, sync_status, &created_at, status, [loan_uuid+status]',
            transactions: 'uuid, id, loan_uuid, type, sync_status, &created_at',
            categories: 'uuid, id, localId, sync_status, last_synced_at, &created_at',
            syncQueue: '++id, operation, data, status, created_at, retry_count, error, priority',
            syncState: 'id, table_name, lastSyncTime, lastId, dataVersion, totalRecords',
            auth: 'id, token, user, lastVerified, expiresAt'
        }).upgrade(tx => {
            // Clear all data during upgrade
            return Promise.all([
                tx.customers.clear(),
                tx.loans.clear(),
                tx.items.clear(),
                tx.transactions.clear(),
                tx.categories.clear(),
                tx.syncQueue.clear(),
                tx.syncState.clear(),
                tx.auth.clear()
            ]);
        });

        // Update schema to remove unique constraints on created_at
        this.version(12).stores({ // Increment version number
            customers: 'uuid, id, sync_status, last_synced_at, created_at, *searchTerms, [last_name+first_name]',
            loans: 'uuid, id, customer_uuid, status, sync_status, last_synced_at, created_at, [customer_uuid+status], [status+loan_date]',
            items: 'uuid, id, loan_uuid, customer_uuid, sync_status, created_at, status, [loan_uuid+status]',
            transactions: 'uuid, id, loan_uuid, type, sync_status, created_at',
            categories: 'uuid, id, localId, sync_status, last_synced_at, created_at',
            // ...existing tables...
        }).upgrade(tx => {
            // Clear all data during upgrade
            return Promise.all([
                tx.customers.clear(),
                tx.loans.clear(),
                tx.items.clear(),
                tx.transactions.clear(),
                tx.categories.clear(),
                tx.syncQueue.clear(),
                tx.syncState.clear(),
                tx.auth.clear()
            ]);
        });

        // Define version 13 with updated schema
        this.version(13).stores({
            customers: 'uuid, id, sync_status, last_synced_at, created_at, *searchTerms, [last_name+first_name]',
            loans: 'uuid, id, customer_uuid, status, sync_status, last_synced_at, created_at, *customer_uuid, [status+created_at]',
            items: 'uuid, id, loan_uuid, customer_uuid, sync_status, created_at, status, [loan_uuid+status]',
            transactions: 'uuid, id, loan_uuid, type, sync_status, created_at',
            categories: 'uuid, id, localId, sync_status, last_synced_at, created_at',
            syncQueue: '++id, operation, data, status, created_at, retry_count, error, priority',
            syncState: 'id, table_name, lastSyncTime, lastId, dataVersion, totalRecords',
            auth: 'id, token, user, lastVerified, expiresAt'
        }).upgrade(tx => {
            // Clear all data during upgrade
            return Promise.all([
                tx.customers.clear(),
                tx.loans.clear(),
                tx.items.clear(),
                tx.transactions.clear(),
                tx.categories.clear(),
                tx.syncQueue.clear(),
                tx.syncState.clear(),
                tx.auth.clear()
            ]);
        });

        // Update schema to remove unique constraints on created_at
        this.version(14).stores({ // Increment version number
            customers: 'uuid, id, sync_status, last_synced_at, created_at, *searchTerms, [last_name+first_name]',
            loans: 'uuid, id, pawn_ticket_number, customer_uuid, status, sync_status, last_synced_at, created_at, [customer_uuid+status], [status+loan_date]',
            items: 'uuid, id, loan_uuid, customer_uuid, sync_status, created_at, status, [loan_uuid+status]',
            transactions: 'uuid, id, loan_uuid, type, sync_status, created_at',
            categories: 'uuid, id, localId, sync_status, last_synced_at, created_at',
            // ...existing tables...
        }).upgrade(tx => {
            // Clear all data during upgrade
            return Promise.all([
                tx.customers.clear(),
                tx.loans.clear(),
                tx.items.clear(),
                tx.transactions.clear(),
                tx.categories.clear(),
                tx.syncQueue.clear(),
                tx.syncState.clear(),
                tx.auth.clear()
            ]);
        });

        this.version(15).stores({
            // ...existing tables...
            settings: 'id, updated_at',
            // ...existing tables...
        }).upgrade(tx => {
            // ...existing upgrade code...
        });

        // Add hooks
        this.customers.hook('creating', this.addCustomerHookData);
        this.customers.hook('updating', this.updateCustomerHookData);
        this.loans.hook('creating', this.convertLoanData);
        this.loans.hook('updating', this.convertLoanData);
        this.items.hook('creating', this.convertItemData);
        this.items.hook('updating', this.convertItemData);
    }

    // Hook implementations
    addCustomerHookData = (primKey, obj) => {
        if (!obj.uuid) obj.uuid = crypto.randomUUID();
        if (!obj.created_at) obj.created_at = new Date().toISOString();
        obj.updated_at = new Date().toISOString();
        obj.sync_status = 'pending';
        obj.searchTerms = this.generateSearchTerms(obj);
        return obj;
    }

    updateCustomerHookData = (mods, primKey, obj) => {
        if (mods.hasOwnProperty('first_name') || mods.hasOwnProperty('last_name')) {
            mods.searchTerms = this.generateSearchTerms(mods);
        }
        mods.updated_at = new Date().toISOString();
        return mods;
    }

    generateSearchTerms(obj) {
        const terms = [];
        if (obj.first_name) terms.push(...obj.first_name.toLowerCase().split(/\s+/));
        if (obj.last_name) terms.push(...obj.last_name.toLowerCase().split(/\s+/));
        if (obj.phone_number) terms.push(obj.phone_number);
        return terms;
    }

    // Helper methods for common operations
    async findByUuid(table, uuid) {
        return await this[table].where('uuid').equals(uuid).first();
    }

    async markForSync(table, id, status = 'pending') {
        await this[table].update(id, {
            sync_status: status,
            last_synced_at: new Date()
        });
    }

    async saveWithSync(table, item, generateUuid = true) {
        // Create a new object without spreading
        const data = Object.assign({}, {
            // Explicitly copy properties
            uuid: generateUuid && !item.uuid ? crypto.randomUUID() : item.uuid,
            sync_status: 'pending',
            updated_at: new Date().toISOString(),
            created_at: item.created_at || new Date().toISOString(),
            // Safely copy all other properties
            ...this.sanitizeDataForStorage(item)
        });
            
        await this.table(table).put(data);
        return data;
    }

    async updateWithSync(table, uuid, data, markPending = true) {
        try {
            // Parse string data if needed
            const inputData = typeof data === 'string' ? JSON.parse(data) : data;
            
            // Create clean object with explicit uuid assignment
            const cleanData = Object.assign({}, {
                uuid: uuid, // Explicit uuid assignment
                updated_at: new Date().toISOString(),
            }, this.sanitizeDataForStorage(inputData));
    
            // Remove any array-like or numbered properties
            Object.keys(cleanData).forEach(key => {
                if (!isNaN(parseInt(key))) {
                    delete cleanData[key];
                }
            });
    
            // Check if item exists
            const existingItem = await this.table(table).where('uuid').equals(uuid).first();
            
            if (!existingItem) {
                // Create new item with minimal required fields
                const newItem = Object.assign({}, {
                    ...cleanData,
                    created_at: new Date().toISOString(),
                    sync_status: markPending ? 'pending' : 'synced'
                });
                
                await this.table(table).add(newItem);
                return newItem;
            }
            
            // Update existing item, preserving required fields
            const updatedItem = Object.assign({}, 
                existingItem,
                cleanData,
                {
                    sync_status: markPending ? 'pending' : 
                        (data.sync_status || existingItem.sync_status)
                }
            );
            
            await this.table(table).put(updatedItem);
            return updatedItem;
        } catch (error) {
            console.error(`Error in updateWithSync for ${table}:`, error);
            throw new Error(`Failed to update ${table}: ${error.message}`);
        }
    }

    // New helper method to sanitize data specifically for storage
    sanitizeDataForStorage(data) {
        if (!data || typeof data !== 'object') {
            return {};
        }
    
        const result = {};
        
        // List of fields that should be numbers
        const numberFields = [
            'market_value', 'selling_price', 'final_selling_price',
            'appraisal_value', 'loan_amount', 'service_charge',
            'interest_rate', 'penalty_rate', 'amount_disbursed'
        ];
        
        // List of fields that should be dates
        const dateFields = [
            'created_at', 'updated_at', 'sold_at', 'forfeiture_date',
            'loan_date', 'maturity_date', 'expiry_date',
            'renewal_date', 'redemption_date'
        ];
    
        // Process each field in the data object
        Object.entries(data).forEach(([key, value]) => {
            if (value === undefined || value === null) {
                return; // Skip undefined/null values
            }
    
            // Special handling for UUIDs to prevent splitting
            if (key === 'uuid' || key.endsWith('_uuid')) {
                result[key] = String(value);
                return;
            }
    
            if (numberFields.includes(key)) {
                result[key] = Number(value) || 0;
                return;
            }
    
            if (dateFields.includes(key)) {
                result[key] = value instanceof Date ? value.toISOString() : value;
                return;
            }
    
            if (typeof value === 'string') {
                result[key] = value;
                return;
            }
    
            if (typeof value === 'number' || typeof value === 'boolean') {
                result[key] = value;
                return;
            }
    
            // For objects and arrays, safely clone them
            if (typeof value === 'object' && !Array.isArray(value)) {
                try {
                    result[key] = this.sanitizeDataForStorage(value);
                } catch (e) {
                    console.warn(`Skipping non-cloneable field: ${key}`);
                }
            }
        });
    
        return result;
    }

    async bulkUpsert(table, items) {
        const arrayItems = Array.isArray(items) ? items : [items];
        await this.transaction('rw', table, async () => {
            for (const item of arrayItems) {
                await this.table(table).put(item);
            }
        });
        return arrayItems;
    }

    async performInitialSync() {
        const syncState = await this.syncState.get(1);
        if (!syncState) {
            await this.downloadAllData();
        }
    }

    async downloadAllData() {
        try {
            // First check if total dataset is too large
            const initialResponse = await http.get('/api/sync', {
                params: {
                    since: new Date(0).toISOString()
                }
            });

            if (initialResponse.data.meta?.recommendation === 'Use individual table endpoints') {
                await this.downloadLargeDataset();
            } else {
                await this.downloadSmallDataset(initialResponse.data);
            }

            await this.syncState.put({
                id: 1,
                lastSyncTime: new Date().toISOString(),
                dataVersion: 1
            });
        } catch (error) {
            console.error('Error in initial data download:', error);
            throw error;
        }
    }

    async downloadLargeDataset() {
        const tables = ['customers', 'loans', 'items'];
        const chunkSize = 1000; // Increased chunk size
        
        await this.transaction('rw', [...tables, 'syncState'], async () => {
            await Promise.all([
                this.customers.clear(),
                this.loans.clear(),
                this.items.clear(),
                this.syncState.clear()
            ]);
            console.log('All tables cleared successfully');
        });

        for (const table of tables) {
            let lastId = 0;
            let hasMore = true;
            const batchSize = 1000; // Process in larger batches
            let accumulator = [];
    
            while (hasMore) {
                try {
                    const response = await http.get('/api/sync', {
                        params: {
                            table,
                            since: new Date(0).toISOString(),
                            last_id: lastId,
                            chunk_size: chunkSize
                        }
                    });
    
                    accumulator.push(...response.data.data);
    
                    // Process in batches
                    if (accumulator.length >= batchSize || !response.data.meta.has_more) {
                        await this.transaction('rw', ['customers', 'loans', 'items', 'syncState'], async () => {
                            if (table === 'loans') {
                                await Promise.all([
                                    this.loans.bulkPut(accumulator),
                                    this.items.bulkPut(
                                        accumulator.flatMap(loan => 
                                            loan.items?.map(item => ({
                                                ...item,
                                                loan_uuid: loan.uuid
                                            })) || []
                                        )
                                    )
                                ]);
                            } else {
                                await this[table].bulkPut(accumulator);
                            }
                        });
                        accumulator = []; // Clear processed items
                    }
    
                    hasMore = response.data.meta.has_more;
                    lastId = response.data.meta.next_chunk_id;
                } catch (error) {
                    console.error(`Error syncing ${table}:`, error);
                    throw error;
                }
            }
        }
    }

    async downloadSmallDataset(data) {
        await this.transaction('rw', ['customers', 'loans', 'items'], async () => {
            // Process customers
            if (data.data.customers?.length) {
                await this.customers.bulkPut(data.data.customers);
            }

            // Process loans and their items
            if (data.data.loans?.length) {
                for (const loan of data.data.loans) {
                    await this.loans.put(loan);
                    if (loan.items?.length) {
                        await this.items.bulkPut(loan.items.map(item => ({
                            ...item,
                            loan_uuid: loan.uuid
                        })));
                    }
                }
            }

            // Process standalone items
            if (data.data.items?.length) {
                await this.items.bulkPut(data.data.items);
            }
        });
    }

    async searchCustomersOffline(query) {
        const terms = query.toLowerCase().split(/\s+/);
        return await this.customers
            .where('searchTerms')
            .startsWithAnyOf(terms)
            .distinct()
            .toArray();
    }

    async getRecentLoans(limit = 50) {
        return await this.loans
            .orderBy('created_at')
            .reverse()
            .limit(limit)
            .toArray();
    }

    // Add new methods for specific queries
    async getActiveLoansByCustomer(customerId) {
        return await this.loans
            .where('[customer_uuid+status]')
            .equals([customerId, 'active'])
            .toArray();
    }

    async getLoansNearingMaturity(daysThreshold = 7) {
        const threshold = new Date();
        threshold.setDate(threshold.getDate() + daysThreshold);
        
        return await this.loans
            .where('status')
            .equals('active')
            .filter(loan => {
                const maturityDate = new Date(loan.maturity_date);
                return maturityDate <= threshold;
            })
            .toArray();
    }

    convertLoanData(primKey, obj, trans) {
        // Convert decimal values to numbers
        const decimalFields = [
            'appraisal_value', 'loan_amount', 'service_charge',
            'interest_rate', 'penalty_rate', 'amount_disbursed',
            'paid_interest_amount', 'paid_penalty_amount'
        ];

        decimalFields.forEach(field => {
            if (obj[field] !== undefined) {
                obj[field] = Number(obj[field]);
            }
        });

        // Convert dates to ISO strings
        const dateFields = [
            'loan_date', 'maturity_date', 'expiry_date',
            'renewal_date', 'redemption_date', 'forfeiture_date',
            'created_at', 'updated_at'
        ];

        dateFields.forEach(field => {
            if (obj[field]) {
                obj[field] = new Date(obj[field]).toISOString();
            }
        });

        return obj;
    }

    // Add auth-specific methods
    async saveAuthState(authData) {
        return await this.auth.put({
            id: 1,
            token: authData.token,
            user: authData.user,
            lastVerified: new Date().toISOString(),
            expiresAt: new Date(Date.now() + (3 * 24 * 60 * 60 * 1000)).toISOString() // 3 days
        });
    }

    async getAuthState() {
        return await this.auth.get(1);
    }

    async clearAuthState() {
        return await this.auth.delete(1);
    }

    // Update pagination helper to handle sorting correctly
    async getPaginatedData(table, { data = null, page = 1, perPage = 10, sortBy = 'created_at', sortDir = 'desc' }) {
        const offset = (page - 1) * perPage;
        
        try {
            let items;
            let total;

            if (data) {
                // Use provided data if available
                items = this.sortItems(data, sortBy, sortDir)
                    .slice(offset, offset + perPage);
                total = data.length;
            } else {
                // Otherwise query the table
                let collection = this[table].orderBy(sortBy);
                if (sortDir === 'desc') {
                    collection = collection.reverse();
                }

                [items, total] = await Promise.all([
                    collection.offset(offset).limit(perPage).toArray(),
                    this[table].count()
                ]);
            }

            return {
                data: items,
                meta: {
                    current_page: page,
                    per_page: perPage,
                    total,
                    last_page: Math.ceil(total / perPage)
                }
            };
        } catch (error) {
            console.error('Pagination error:', error);
            throw error;
        }
    }

    // Add helper method for memory sorting
    sortItems(items, sortBy, sortDir) {
        const key = sortBy.replace('-', '');
        const direction = sortDir === 'desc' || sortBy.startsWith('-') ? -1 : 1;
        
        return [...items].sort((a, b) => {
            if (a[key] < b[key]) return -1 * direction;
            if (a[key] > b[key]) return 1 * direction;
            return 0;
        });
    }
}

export const db = new AppDatabase();

export const ensureDbInitialized = async () => {
    try {
        // Delete existing database if there's a version mismatch
        const currentVersion = await Dexie.getDatabaseNames()
            .then(names => names.includes('PawnshopDB') ? 
                db.version : null);

        if (currentVersion && currentVersion < 13) { // Update version check
            await db.delete();
        }

        // Open database with new schema
        await db.open();
        
        // Perform initial sync after successful initialization
        const syncState = await db.syncState.get(1);
        const authStore = useAuthStore();

        if (!syncState && authStore.isAuthenticated) {
            await db.performInitialSync();
        }

        console.log('Database initialized successfully');
    } catch (error) {
        console.error('Database initialization error:', error);
        
        // Handle specific error cases
        if (error.name === 'VersionError' || error.name === 'UpgradeError') {
            await db.delete();
            window.location.reload();
            return;
        }

        throw error;
    }
};