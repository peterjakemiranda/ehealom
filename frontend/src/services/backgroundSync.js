import { useSyncStore } from '@/stores/syncStore';
import { db } from './db';

class BackgroundSyncManager {
    constructor() {
        this.syncStore = null;
        this.initialized = false;
    }

    async initialize() {
        if (this.initialized) return;
        
        // Initialize the sync store
        this.syncStore = useSyncStore();
        
        // Start background sync with delay
        setTimeout(() => {
            this.startBackgroundSync();
        }, 2000);

        // Add online/offline handlers
        window.addEventListener('online', () => this.handleOnline());
        window.addEventListener('offline', () => this.handleOffline());

        this.initialized = true;
    }

    async startBackgroundSync() {
        try {
            // Check if initial sync is needed
            const syncState = await db.syncState.get(1);
            if (!syncState) {
                console.log('📥 Initial sync needed - starting in background');
                this.syncStore.startInitialSync();
            } else {
                console.log('✅ Data already synced, starting periodic sync');
                this.syncStore.startPeriodicSync();
            }
        } catch (error) {
            console.error('Background sync initialization failed:', error);
        }
    }

    handleOnline() {
        console.log('🌐 Back online, resuming sync');
        this.syncStore.syncData();
    }

    handleOffline() {
        console.log('📴 Offline, pausing sync');
    }
}

export const backgroundSync = new BackgroundSyncManager();
