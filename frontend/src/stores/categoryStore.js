import { defineStore } from "pinia";
import http from "../utils/http";
import { db } from "../services/db";
import { syncService } from "../services/syncService";
import { handleError, handleSuccess } from "../utils/messageHandler";

export const useCategoryStore = defineStore({
  id: "categoryStore",
  state: () => ({
    categories: [],
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
    hasCategories: (state) => state.categories.length > 0,
    totalPages: (state) => state.pagination.last_page,
    currentPage: (state) => state.pagination.current_page,
  },

  actions: {
    async fetchCategories({ page = 1, search = '', perPage = 10 } = {}) {
      this.isLoading = true;
      try {
        const params = new URLSearchParams({
          page,
          per_page: perPage
        });

        if (search) {
          params.append('search', search);
        }

        const response = await http.get(`/api/categories?${params.toString()}`);
        this.categories = response.data.data;
        this.pagination = response.data.meta;
        return this.categories;
      } catch (error) {
        handleError(error);
        throw error;
      } finally {
        this.isLoading = false;
      }
    },

    async searchCategories(search) {
      // Reset to first page when searching
      return this.fetchCategories();
    },

    // Reset pagination state
    resetPagination() {
      this.pagination = {
        current_page: 1,
        last_page: 1,
        per_page: 10,
        total: 0,
        from: null,
        to: null
      };
    },

    async fetchCategory(id) {
      try {
        const response = await http.get(`/api/categories/${id}`);
        return response.data;
      } catch (error) {
        console.error("Error fetching category:", error);
        throw error;
      }
    },

    async addCategory(category) {
      this.isLoading = true;
      try {
        const formData = new FormData();
        Object.keys(category).forEach(key => {
          if (key === 'image' && category[key]) {
            formData.append('image', category[key]);
          } else {
            formData.append(key, category[key]);
          }
        });

        const response = await http.post('/api/categories', formData, {
          headers: { 'Content-Type': 'multipart/form-data' }
        });
        
        this.categories.push(response.data.data);
        handleSuccess('Category created successfully');
        return response.data.data;
      } catch (error) {
        handleError(error);
        throw error;
      } finally {
        this.isLoading = false;
      }
    },

    async updateCategory(uuid, category) {
      this.isLoading = true;
      try {
        const formData = new FormData();
        Object.keys(category).forEach(key => {
          if (key === 'image' && category[key]) {
            formData.append('image', category[key]);
          } else if (key !== 'uuid') {
            formData.append(key, category[key]);
          }
        });
        formData.append('_method', 'PUT');

        const response = await http.post(`/api/categories/${uuid}`, formData, {
          headers: { 'Content-Type': 'multipart/form-data' }
        });

        const index = this.categories.findIndex(c => c.uuid === uuid);
        if (index !== -1) {
          this.categories[index] = response.data.data;
        }

        handleSuccess('Category updated successfully');
        return response.data.data;
      } catch (error) {
        handleError(error);
        throw error;
      } finally {
        this.isLoading = false;
      }
    },

    async deleteCategory(uuid) {
      this.isLoading = true;
      try {
        await http.delete(`/api/categories/${uuid}`);
        this.categories = this.categories.filter(c => c.uuid !== uuid);
        handleSuccess('Category deleted successfully');
      } catch (error) {
        handleError(error);
        throw error;
      } finally {
        this.isLoading = false;
      }
    }
  }
});
