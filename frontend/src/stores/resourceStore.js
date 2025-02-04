import { defineStore } from 'pinia'
import http from '../utils/http'
import { handleError, handleSuccess } from '../utils/messageHandler'

export const useResourceStore = defineStore({
  id: 'resourceStore',
  state: () => ({
    resources: [],
    pagination: {
      current_page: 1,
      last_page: 1,
      per_page: 10,
      total: 0,
      from: null,
      to: null
    },
    isLoading: false,
    error: null
  }),

  getters: {
    hasResources: (state) => state.resources.length > 0,
    totalPages: (state) => state.pagination.last_page,
    currentPage: (state) => state.pagination.current_page,
    publishedResources: (state) => state.resources.filter(r => r.is_published),
    getByType: (state) => (type) => state.resources.filter(r => r.type === type)
  },

  actions: {
    async fetchResources({ page = 1, category = '', search = '' } = {}) {
      this.isLoading = true
      this.error = null

      try {
        const params = new URLSearchParams({
          page,
          per_page: 10
        })

        if (category) params.append('category', category)
        if (search) params.append('search', search)

        const response = await http.get(`/api/resources?${params.toString()}`)
        this.resources = response.data.data
        this.pagination = response.data.meta
      } catch (error) {
        handleError(error)
        this.error = error.message
      } finally {
        this.isLoading = false
      }
    },

    async createResource(resource) {
      this.isLoading = true
      try {
        const formData = new FormData()
        Object.keys(resource).forEach(key => {
          if (key === 'image' && resource[key]) {
            formData.append('image', resource[key])
          } else if (key === 'is_published') {
            formData.append('is_published', resource[key] ? '1' : '0')
          } else {
            formData.append(key, resource[key])
          }
        })

        const response = await http.post('/api/resources', formData, {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        })
        
        this.resources = [response.data.data, ...this.resources]
        handleSuccess('Resource created successfully')
        return response.data.data
      } catch (error) {
        handleError(error)
        throw error
      } finally {
        this.isLoading = false
      }
    },

    async updateResource(uuid, resource) {
      this.isLoading = true
      try {
        const formData = new FormData()
        Object.keys(resource).forEach(key => {
          if (key === 'image' && resource[key]) {
            formData.append('image', resource[key])
          } else if (key === 'is_published') {
            formData.append('is_published', resource[key] ? '1' : '0')
          } else if (key !== 'uuid' && key !== 'localId') {
            formData.append(key, resource[key])
          }
        })
        formData.append('_method', 'PUT')

        const response = await http.post(`/api/resources/${uuid}`, formData, {
          headers: {
            'Content-Type': 'multipart/form-data'
          }
        })

        const index = this.resources.findIndex(r => r.uuid === uuid)
        if (index !== -1) {
          this.resources = [
            ...this.resources.slice(0, index),
            response.data.data,
            ...this.resources.slice(index + 1)
          ]
        }

        handleSuccess('Resource updated successfully')
        return response.data.data
      } catch (error) {
        handleError(error)
        throw error
      } finally {
        this.isLoading = false
      }
    },

    async deleteResource(uuid) {
      this.isLoading = true
      try {
        await http.delete(`/api/resources/${uuid}`)
        this.resources = this.resources.filter(r => r.uuid !== uuid)
        handleSuccess('Resource deleted successfully')
      } catch (error) {
        handleError(error)
        throw error
      } finally {
        this.isLoading = false
      }
    }
  }
}) 