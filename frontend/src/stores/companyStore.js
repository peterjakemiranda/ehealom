import { defineStore } from 'pinia'
import http from '@/utils/http'

export const useCompanyStore = defineStore('companyStore', {
  state: () => ({
    companies: [],
    currentCompany: null,
    isLoading: false,
    error: null
  }),

  getters: {
    hasCompanies: (state) => state.companies.length > 0,
    defaultCompany: (state) => state.companies.find(c => c.pivot.is_default),
    companyCount: (state) => state.companies.length
  },

  actions: {
    async fetchUserCompanies() {
      this.isLoading = true
      try {
        const response = await http.get('/api/user/companies')
        this.companies = response.data.data
        
        // Set current company to default or first company
        if (!this.currentCompany && this.companies.length > 0) {
          const defaultCompany = this.companies.find(c => c.pivot.is_default)
          await this.setCurrentCompany(defaultCompany || this.companies[0])
        }
      } catch (error) {
        this.error = error.message
        throw error
      } finally {
        this.isLoading = false
      }
    },

    async createCompany(companyData) {
      this.isLoading = true
      try {
        const response = await http.post('/api/companies', companyData)
        this.companies.push(response.data.data)
        
        // If this is the first company, set it as current
        if (this.companies.length === 1) {
          await this.setCurrentCompany(response.data.data)
        }
        
        return response.data.data
      } catch (error) {
        this.error = error.message
        throw error
      } finally {
        this.isLoading = false
      }
    },

    async updateCompany(uuid, companyData) {
      this.isLoading = true
      try {
        const response = await http.put(`/api/companies/${uuid}`, companyData)
        const index = this.companies.findIndex(c => c.uuid === uuid)
        if (index !== -1) {
          this.companies[index] = response.data.data
          
          // Update current company if it's the one being updated
          if (this.currentCompany?.uuid === uuid) {
            this.currentCompany = response.data.data
          }
        }
        return response.data.data
      } catch (error) {
        this.error = error.message
        throw error
      } finally {
        this.isLoading = false
      }
    },

    async deleteCompany(uuid) {
      this.isLoading = true
      try {
        await http.delete(`/api/companies/${uuid}`)
        this.companies = this.companies.filter(c => c.uuid !== uuid)
        
        // If deleted company was current, switch to another company
        if (this.currentCompany?.uuid === uuid) {
          const nextCompany = this.companies[0]
          if (nextCompany) {
            await this.setCurrentCompany(nextCompany)
          } else {
            this.currentCompany = null
          }
        }
      } catch (error) {
        this.error = error.message
        throw error
      } finally {
        this.isLoading = false
      }
    },

    async setCurrentCompany(company) {
      try {
        // Update default company on the server
        await http.patch(`/api/companies/${company.uuid}/set-default`)
        
        // Update local state
        this.currentCompany = company
        http.defaults.headers.common['X-Company-Id'] = company.uuid
        localStorage.setItem('currentCompanyId', company.uuid)
        
        // Update is_default in companies array
        this.companies = this.companies.map(c => ({
          ...c,
          pivot: {
            ...c.pivot,
            is_default: c.uuid === company.uuid
          }
        }))
      } catch (error) {
        this.error = error.message
        throw error
      }
    },

    // Initialize company from localStorage
    async initializeCompany() {
      const savedCompanyId = localStorage.getItem('currentCompanyId')
      if (savedCompanyId && this.companies.length > 0) {
        const company = this.companies.find(c => c.uuid === savedCompanyId)
        if (company) {
          await this.setCurrentCompany(company)
        }
      }
    },

    // Reset store state
    resetState() {
      this.companies = []
      this.currentCompany = null
      this.isLoading = false
      this.error = null
      localStorage.removeItem('currentCompanyId')
      delete http.defaults.headers.common['X-Company-Id']
    }
  }
})
