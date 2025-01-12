import { defineStore } from "pinia";
import http from "../utils/http";

export const useRoleStore = defineStore({
  id: "roleStore",
  state: () => ({
    roles: [],
    permissions: [],
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
    hasRoles: (state) => state.roles.length > 0,
    totalPages: (state) => state.pagination.last_page,
    currentPage: (state) => state.pagination.current_page,
  },

  actions: {
    async fetchRoles({ page = 1, perPage = 10 } = {}) {
      this.isLoading = true;
      this.error = null;

      try {
        const response = await http.get("/api/roles", {
          params: { 
            page,
            per_page: perPage
          }
        });

        this.roles = response.data.data;
        this.pagination = response.data.meta;

      } catch (error) {
        this.error = error.response?.data?.message || 'An error occurred while fetching roles';
        throw error;
      } finally {
        this.isLoading = false;
      }
    },

    async fetchPermissions() {
      try {
        const response = await http.get('/api/permissions');
        this.permissions = response.data;
      } catch (error) {
        console.error('Error fetching permissions:', error);
        throw error;
      }
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

    async createRole(roleData) {
      try {
        const response = await http.post('/api/roles', roleData);
        await this.fetchRoles({ page: this.pagination.current_page });
        return response.data.data;
      } catch (error) {
        console.error('Error creating role:', error);
        throw error;
      }
    },

    async updateRole(id, roleData) {
      try {
        const response = await http.put(`/api/roles/${id}`, roleData);
        // Fetch roles without pagination parameters
        await this.fetchRoles();
        return response.data;
      } catch (error) {
        console.error('Error updating role:', error);
        throw error;
      }
    },

    async deleteRole(id) {
      try {
        await http.delete(`/api/roles/${id}`);
        await this.fetchRoles({ page: this.pagination.current_page });
      } catch (error) {
        console.error('Error deleting role:', error);
        throw error;
      }
    }
  }
});
