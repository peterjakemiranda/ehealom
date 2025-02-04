import { defineStore } from 'pinia'
import http from '@/utils/http'

export const useUserStore = defineStore('userStore', {
  state: () => ({
    users: [],
    pagination: {
      current_page: 1,
      last_page: 1,
      per_page: 10,
      total: 0,
      from: null,
      to: null
    },
    isLoading: false,
    error: null,
    currentCompany: null,
    userCompanies: []
  }),

  actions: {
    async fetchUsers({ page = 1, search = '', role = '' } = {}) {
      this.isLoading = true
      try {
        const response = await http.get('/api/users', {
          params: { page, search, role, per_page: this.pagination.per_page }
        })
        this.users = response.data.data
        this.pagination = response.data.meta
      } catch (error) {
        this.error = error.message
        throw error
      } finally {
        this.isLoading = false
      }
    },

    resetPagination() {
      this.pagination = {
        current_page: 1,
        last_page: 1,
        per_page: 10,
        total: 0,
        from: null,
        to: null
      }
    },

    async createUser(userData) {
      const response = await http.post('/api/users', userData)
      this.users.push(response.data)
      return response.data
    },

    async updateUser(id, userData) {
      const response = await http.put(`/api/users/${id}`, userData)
      const index = this.users.findIndex(user => user.id === id)
      if (index !== -1) {
        this.users[index] = response.data
      }
      return response.data
    },

    async deleteUser(id) {
      await http.delete(`/api/users/${id}`)
      this.users = this.users.filter(user => user.id !== id)
    },

    async toggleUserStatus(userId) {
      const user = this.users.find(u => u.id === userId)
      if (!user) return

      const response = await http.patch(`/api/users/${userId}/toggle-status`)
      const index = this.users.findIndex(u => u.id === userId)
      if (index !== -1) {
        this.users[index] = response.data
      }
      return response.data
    },

    async fetchUserCompanies() {
      try {
        const response = await http.get('/api/user/companies')
        this.userCompanies = response.data
        if (!this.currentCompany && this.userCompanies.length > 0) {
          this.setCurrentCompany(this.userCompanies.find(c => c.pivot.is_default) || this.userCompanies[0])
        }
      } catch (error) {
        this.error = error.message
        throw error
      }
    },

    setCurrentCompany(company) {
      this.currentCompany = company
      http.defaults.headers.common['X-Company-Id'] = company.id
      localStorage.setItem('currentCompanyId', company.id)
    },

    async switchCompany(companyId) {
      const company = this.userCompanies.find(c => c.id === companyId)
      if (company) {
        await this.setCurrentCompany(company)
        // Optionally refresh other data as needed
        return company
      }
      throw new Error('Company not found')
    },

    async fetchCounselors() {
      try {
        const response = await http.get('/api/users', { 
          params: { user_type: 'counselor' } 
        })
        return response.data.data
      } catch (error) {
        console.error('Failed to fetch counselors:', error)
        throw error
      }
    }
  }
})
