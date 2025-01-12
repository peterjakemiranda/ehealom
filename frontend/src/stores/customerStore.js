import { defineStore } from 'pinia'
import http from '../utils/http'
import { db } from '../services/db'
import { syncService } from '../services/syncService'
import { handleError, handleSuccess } from '../utils/messageHandler'

export const useCustomerStore = defineStore({
  id: 'customerStore',

  state: () => ({
    customers: [],
    pagination: {},
    isOnline: navigator.onLine,
    currentCustomer: null // Add this line
  }),

  actions: {
    async fetchCustomers({ page = 1, filters = {}, sort = '', includes = [] }) {
      try {
        if (navigator.onLine) {
          try {
            const params = new URLSearchParams({
              page: page.toString(),
              per_page: '10'
            })

            // Handle search
            if (filters.search) {
              params.append('search', filters.search)
            }

            // Add sort if present
            if (sort) {
              params.append('sort', sort)
            }

            // Add includes if present
            if (includes.length) {
              params.append('include', includes.join(','))
            }

            const response = await http.get(`/api/customers?${params.toString()}`)
            this.customers = response.data.data
            this.pagination = {
              current_page: response.data.meta.current_page,
              last_page: response.data.meta.last_page,
              total: response.data.meta.total
            }
          } catch (error) {
            console.error('Server fetch failed, using local data:', error)
            await this.fetchOfflineCustomers(filters, page, sort)
          }
        } else {
          await this.fetchOfflineCustomers(filters, page, sort)
        }
      } catch (error) {
        console.error('Error fetching customers:', error)
        handleError(error)
      }
    },

    async fetchOfflineCustomers(filters, page, sort) {
      try {
        let query = db.customers
        const searchTerm = filters.search?.toLowerCase()

        if (searchTerm) {
          // First try exact matches
          let customers = await query.where('searchTerms').anyOf(searchTerm.split(/\s+/)).toArray()

          // If no results, try partial matches
          if (customers.length === 0) {
            customers = await query
              .filter((customer) => {
                const searchFields = [
                  customer.first_name,
                  customer.last_name,
                  customer.phone_number,
                  customer.email,
                  customer.id_number
                ].map((field) => field?.toLowerCase() || '')

                return searchFields.some((field) => field.includes(searchTerm))
              })
              .toArray()
          }

          // Apply sorting
          const sortField = sort?.replace('-', '') || 'last_name'
          const sortDir = sort?.startsWith('-') ? -1 : 1

          customers.sort((a, b) => {
            const aVal = (a[sortField] || '').toLowerCase()
            const bVal = (b[sortField] || '').toLowerCase()
            return sortDir * (aVal > bVal ? 1 : aVal < bVal ? -1 : 0)
          })

          // Handle pagination
          const perPage = 10
          const start = (page - 1) * perPage
          const paginatedCustomers = customers.slice(start, start + perPage)

          this.customers = paginatedCustomers
          this.pagination = {
            current_page: page,
            last_page: Math.ceil(customers.length / perPage),
            total: customers.length
          }
        } else {
          // No search, get all sorted
          const offset = (page - 1) * 10
          const customers = await query
            .orderBy(sort || 'last_name')
            .offset(offset)
            .limit(10)
            .toArray()

          const total = await query.count()

          this.customers = customers
          this.pagination = {
            current_page: page,
            last_page: Math.ceil(total / 10),
            total
          }
        }
      } catch (error) {
        console.error('Error in offline search:', error)
        handleError(error)
      }
    },

    updateLocalCustomers(customer) {
      const index = this.customers.findIndex((c) => c.uuid === customer.uuid)
      if (index !== -1) {
        // Create a new array to trigger reactivity
        this.customers = [
          ...this.customers.slice(0, index),
          { ...this.customers[index], ...customer },
          ...this.customers.slice(index + 1)
        ]
      } else {
        this.customers = [customer, ...this.customers]
      }
    },

    async addCustomer(customer) {
      try {
        const customerData = {
          ...customer,
          name: `${customer.first_name} ${customer.last_name}`,
          uuid: customer.uuid || crypto.randomUUID(),
          localId: customer.localId || Date.now(),
          sync_status: 'pending',
          created_at: customer.created_at || new Date().toISOString(),
          updated_at: new Date().toISOString()
        }

        // Save to IndexedDB first
        await db.customers.put(customerData)

        // Update store immediately
        this.updateLocalCustomers(customerData)

        if (navigator.onLine) {
          try {
            const response = await http.post('/api/customers', customerData)
            const serverCustomer = response.data.data

            // Update local DB with server response
            await db.customers.put({
              ...customerData,
              ...serverCustomer,
              sync_status: 'synced'
            })

            // Refresh the list
            await this.fetchCustomers({
              page: this.pagination.current_page
            })

            return serverCustomer;
          } catch (error) {
            console.error('Server sync failed:', error)
            // Queue for sync if server sync fails
            await syncService.queueForSync({
              type: 'CREATE_CUSTOMER',
              data: customerData
            })
          }
          
        } else {
          // Queue for later sync if offline
          await syncService.queueForSync({
            type: 'CREATE_CUSTOMER',
            data: customerData
          })
        }

        handleSuccess('Customer created successfully')
        return customerData
      } catch (error) {
        console.error('Error adding customer:', error)
        handleError(error)
        throw error
      }
    },

    async updateCustomer(uuid, customer) {
      try {
        const existingCustomer = await db.findByUuid('customers', uuid)
        if (!existingCustomer) throw new Error('Customer not found')

        // Update local DB first
        const updatedCustomer = await db.updateWithSync('customers', uuid, {
          ...customer,
          sync_status: 'pending'
        })

        // Update store immediately
        this.updateLocalCustomers(updatedCustomer)

        if (navigator.onLine) {
          try {
            const response = await http.put(`/api/customers/${uuid}`, customer)
            const serverCustomer = response.data.data

            await db.updateWithSync(
              'customers',
              uuid,
              {
                ...serverCustomer,
                sync_status: 'synced'
              },
              false
            )

            // Force a fresh fetch to ensure list is up to date
            await this.fetchCustomers({
              page: this.pagination.current_page
            })
          } catch (error) {
            console.error('Server sync failed:', error)
            await syncService.queueForSync({
              type: 'UPDATE_CUSTOMER',
              data: { uuid, ...customer }
            })
          }
        } else {
          await syncService.queueForSync({
            type: 'UPDATE_CUSTOMER',
            data: { uuid, ...customer }
          })
        }

        handleSuccess('Customer updated successfully')
        return updatedCustomer
      } catch (error) {
        handleError(error)
        throw error
      }
    },

    async fetchCustomer(uuid) {
      try {
        let customer = await db.findByUuid('customers', uuid)

        if (!customer && navigator.onLine) {
          const response = await http.get(`/api/customers/${uuid}`)
          customer = response.data.data
          await db.saveWithSync('customers', customer, false)
        }

        return customer
      } catch (error) {
        console.error('Error fetching customer:', error)
        handleError(error)
        return null
      }
    },

    setCurrentCustomer(customer) {
      this.currentCustomer = customer
    },

    clearCurrentCustomer() {
      this.currentCustomer = null
    }
  }
})
