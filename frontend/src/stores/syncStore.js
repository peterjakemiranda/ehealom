import { defineStore } from 'pinia'
import { db } from '../services/db'
import http from '@/utils/http'
import { useAuthStore } from './auth'

export const useSyncStore = defineStore({
  id: 'syncStore',
  state: () => ({
    isSyncing: false,
    lastSyncTime: null,
    syncError: null,
    syncProgress: {
      total: 0,
      current: 0,
      currentTable: null,
      status: 'idle' // 'idle' | 'checking' | 'syncing' | 'complete' | 'error'
    }
  }),

  actions: {
    async initializeSync() {
      try {
        this.syncProgress.status = 'checking'
        console.log('🔄 Checking sync state...')

        const syncState = await db.syncState.get(1)
        if (!syncState) {
          console.log('📥 Initial sync needed - starting background sync')
          await this.startInitialSync()
        } else {
          console.log('✅ Data already synced, last sync:', syncState.lastSyncTime)
          this.startPeriodicSync()
        }
      } catch (error) {
        console.error('❌ Sync initialization failed:', error)
        this.syncError = error
        this.syncProgress.status = 'error'
      }
    },

    async startInitialSync() {
      let retries = 3
      while (retries > 0) {
        try {
          this.isSyncing = true
          this.syncProgress.status = 'syncing'
          console.log('🚀 Starting initial sync...')

          const response = await http.get('/api/sync', {
            params: { since: new Date(0).toISOString() }
          })

          console.log('📊 Sync status:', response.data.meta)
          this.syncProgress.total = response.data.meta.counts?.total || 0

          if (response.data.meta?.recommendation === 'Use individual table endpoints') {
            console.log('📦 Large dataset detected, using chunked sync')
            await this.syncLargeDataset(new Date(0).toISOString())
          } else {
            console.log('📋 Small dataset detected, using single sync')
            await this.syncSmallDataset(new Date(0).toISOString())
          }

          this.isSyncing = false
          this.syncProgress.status = 'complete'
          console.log('✅ Initial sync completed')
          break
        } catch (error) {
          retries--
          console.error(`❌ Sync attempt failed (${retries} retries left):`, error)
          if (retries === 0) {
            this.syncProgress.status = 'error'
            this.syncError = error
            throw error
          }
          await new Promise((resolve) => setTimeout(resolve, 2000))
        }
      }
    },

    async startPeriodicSync() {
      // Sync every 5 minutes when online
      setInterval(
        async () => {
          if (navigator.onLine && !this.isSyncing) {
            await this.syncData()
          }
        },
        5 * 60 * 1000
      )
    },

    async syncData() {
      if (this.isSyncing) return

      this.isSyncing = true
      try {
        const syncState = await db.syncState.get(1)
        const lastSync = syncState?.lastSyncTime || new Date(0).toISOString()

        const countResponse = await http.get('/api/sync', {
          params: {
            since: lastSync
          }
        })

        if (countResponse.data.meta?.recommendation === 'Use individual table endpoints') {
          await this.syncLargeDataset(lastSync)
        } else {
          await this.syncSmallDataset(lastSync)
        }

        this.lastSyncTime = new Date().toISOString()
        this.syncError = null
      } catch (error) {
        console.error('Sync failed:', error)
        this.syncError = error
      } finally {
        this.isSyncing = false
      }
    },

    async clearDatabase() {
      const tables = ['customers', 'loans', 'items', 'categories']
      await db.transaction('rw', tables, async () => {
        console.log('🧹 Clearing existing data...')
        await Promise.all(tables.map((table) => db[table].clear()))
        console.log('✨ Database cleared successfully')
      })
    },

    async syncLargeDataset(since) {
      const tables = ['categories', 'customers', 'loans', 'items'] // Added categories first
      const errors = []

      // Clear database if this is initial sync
      if (since === new Date(0).toISOString()) {
        await this.clearDatabase()
      }

      for (const table of tables) {
        try {
          this.syncProgress.currentTable = table
          console.log(`📥 Syncing ${table}...`)

          let lastId = 0
          let hasMore = true
          let count = 0

          while (hasMore) {
            const response = await http.get('/api/sync', {
              params: {
                since,
                table,
                chunk_size: 1000,
                last_id: lastId
              }
            })

            if (response.data.data?.length > 0) {
              await db.transaction('rw', [...tables, 'syncState'], async () => {
                if (table === 'loans') {
                  // Handle loans
                  for (const loan of response.data.data) {
                    const loanData = { ...loan }
                    delete loanData.items
                    await db.loans.put(loanData)

                    if (loan.items?.length) {
                      const items = loan.items.map((item) => {
                        const cleanItem = { ...item }
                        cleanItem.loan_uuid = loan.uuid
                        return cleanItem
                      })
                      await db.items.bulkPut(items)
                    }
                  }
                } else {
                  // Handle other tables including categories
                  const records = response.data.data.map((record) => ({
                    ...record,
                    // Convert boolean strings to actual booleans for categories
                    ...(table === 'categories' && {
                      is_renewable: Boolean(record.is_renewable)
                    })
                  }))
                  await db[table].bulkPut(records)
                }

                await db.syncState.put({
                  id: `${table}_sync`,
                  lastSyncTime: response.data.meta.last_sync,
                  lastId: response.data.meta.next_chunk_id,
                  table
                })
              })
            }

            hasMore = response.data.meta.has_more
            lastId = response.data.meta.next_chunk_id
            count += response.data.data.length
            this.syncProgress.current = count
            console.log(`✓ Synced ${count} ${table} records`)
          }
        } catch (error) {
          console.error(`❌ Error syncing ${table}:`, error)
          errors.push({ table, error })
        }
      }

      if (errors.length > 0) {
        throw new Error('Some tables failed to sync: ' + errors.map((e) => e.table).join(', '))
      }

      await db.syncState.put({
        id: 1,
        lastSyncTime: new Date().toISOString(),
        dataVersion: 2
      })
    },

    async syncSmallDataset(since) {
      // Clear database if this is initial sync
      if (since === new Date(0).toISOString()) {
        await this.clearDatabase()
      }

      const response = await http.get('/api/sync', {
        params: { since }
      })

      await db.transaction(
        'rw',
        ['customers', 'loans', 'items', 'categories', 'syncState'],
        async () => {
          // Update categories first
          if (response.data.data.categories?.length) {
            const categories = response.data.data.categories.map((category) => ({
              ...category,
              is_renewable: Boolean(category.is_renewable)
            }))
            await db.categories.bulkPut(categories)
            console.log(`✓ Synced ${categories.length} categories`)
          }

          // Update customers
          if (response.data.data.customers?.length) {
            const customers = response.data.data.customers.map((customer) => ({
              ...customer
            }))
            await db.customers.bulkPut(customers)
            console.log(`✓ Synced ${customers.length} customers`)
          }

          // Update loans and their items
          if (response.data.data.loans?.length) {
            for (const loan of response.data.data.loans) {
              const loanData = { ...loan }
              delete loanData.items
              await db.loans.put(loanData)

              if (loan.items?.length) {
                const items = loan.items.map((item) => ({
                  ...item,
                  loan_uuid: loan.uuid
                }))
                await db.items.bulkPut(items)
              }
            }
            console.log(`✓ Synced ${response.data.data.loans.length} loans`)
          }

          // Update standalone items
          if (response.data.data.items?.length) {
            const items = response.data.data.items.map((item) => ({
              ...item
            }))
            await db.items.bulkPut(items)
            console.log(`✓ Synced ${items.length} items`)
          }

          // Update sync state
          await db.syncState.put({
            id: 1,
            lastSyncTime: response.data.meta.last_sync,
            dataVersion: response.data.meta.dataVersion || 1
          })

          window.dispatchEvent(
            new CustomEvent('sync-completed', {
              detail: {
                timestamp: new Date().toISOString(),
                tables: ['categories', 'customers', 'loans', 'items']
              }
            })
          )
        }
      )
    }
  }
})
