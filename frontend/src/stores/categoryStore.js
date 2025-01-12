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
      this.error = null;

      try {
        // First get from IndexedDB
        let categories = await db.categories
          .orderBy('created_at')
          .reverse()
          .toArray();

        if (navigator.onLine) {
          try {
            const response = await http.get("/api/categories", {
              params: { page, search, per_page: perPage }
            });
            
            // Update IndexedDB with server data
            await db.bulkUpsert('categories', response.data.data);
            this.categories = response.data.data;
            this.pagination = response.data.meta;
          } catch (error) {
            console.error("Server sync failed:", error);
            this.categories = categories;
          }
        } else {
          this.categories = categories;
        }
      } catch (error) {
        this.error = error.response?.data?.message || 'An error occurred';
        throw error;
      } finally {
        this.isLoading = false;
      }
    },

    async searchCategories(search) {
      // Reset to first page when searching
      return this.fetchCategories({ page: 1, search });
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
      try {
        const categoryData = {
          ...category,
          uuid: category.uuid || crypto.randomUUID(),
          localId: category.localId || Date.now(),
          sync_status: 'pending',
          created_at: category.created_at || new Date().toISOString(),
          updated_at: new Date().toISOString()
        };

        // Save to IndexedDB first
        await db.categories.put(categoryData);
        
        // Update local list immediately
        this.categories = [categoryData, ...this.categories];

        if (navigator.onLine) {
          try {
            // Direct server sync
            const response = await http.post("/api/categories", categoryData);
            const serverCategory = response.data.data;
            
            // Update local DB with server response
            await db.categories.put({
              ...categoryData,
              ...serverCategory,
              sync_status: 'synced'
            });
            
            // Refresh the list to show updated data
            await this.fetchCategories();
          } catch (error) {
            console.error("Server sync failed:", error);
            // Only queue for sync if server sync fails
            await syncService.queueForSync({
              type: 'CREATE_CATEGORY',
              data: categoryData
            });
          }
        } else {
          // Queue for later sync if offline
          await syncService.queueForSync({
            type: 'CREATE_CATEGORY',
            data: categoryData
          });
        }

        handleSuccess("Category created successfully");
        return categoryData;
      } catch (error) {
        console.error('Error adding category:', error);
        handleError(error);
        throw error;
      }
    },

    async updateCategory(uuid, category) {
      try {
        const existingCategory = await db.findByUuid('categories', uuid);
        if (!existingCategory) throw new Error('Category not found');

        // Update local DB first
        const updatedCategory = await db.updateWithSync('categories', uuid, {
          ...category,
          sync_status: 'pending'
        });

        // Update store immediately
        const index = this.categories.findIndex(c => c.uuid === uuid);
        if (index !== -1) {
          this.categories = [
            ...this.categories.slice(0, index),
            updatedCategory,
            ...this.categories.slice(index + 1)
          ];
        }

        if (navigator.onLine) {
          try {
            // Direct server sync
            const response = await http.put(`/api/categories/${uuid}`, category);
            const serverCategory = response.data.data;
            
            // Update local DB with server response
            await db.updateWithSync('categories', uuid, {
              ...serverCategory,
              sync_status: 'synced'
            }, false);
            
            // Refresh the list to show updated data
            await this.fetchCategories();
          } catch (error) {
            console.error("Server sync failed:", error);
            // Only queue for sync if server sync fails
            await syncService.queueForSync({
              type: 'UPDATE_CATEGORY',
              data: { uuid, ...category }
            });
          }
        } else {
          // Queue for later sync if offline
          await syncService.queueForSync({
            type: 'UPDATE_CATEGORY',
            data: { uuid, ...category }
          });
        }

        handleSuccess("Category updated successfully");
        return updatedCategory;
      } catch (error) {
        handleError(error);
        throw error;
      }
    }
  }
});
