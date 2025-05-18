import { defineStore } from 'pinia';
import http from '../utils/http'; // Assuming you have an HTTP utility
import { handleError } from '../utils/messageHandler'; // Assuming error handling utility

export const useReportStore = defineStore('reportStore', {
  state: () => ({
    appointmentsByCategory: [],
    appointmentsByAge: [],
    appointmentsByDepartment: [],
    isLoadingByCategory: false,
    isLoadingByAge: false,
    isLoadingByDepartment: false,
    errorByCategory: null,
    errorByAge: null,
    errorByDepartment: null,
  }),

  actions: {
    async fetchAppointmentsByCategoryDaily(params = { period: 'last_30_days' }) {
      this.isLoadingByCategory = true;
      this.errorByCategory = null;
      try {
        const response = await http.get('/api/reports/appointments-by-category-daily', { params });
        this.appointmentsByCategory = response.data;
      } catch (error) {
        handleError(error);
        this.errorByCategory = error.message || 'Failed to fetch category report data.';
      } finally {
        this.isLoadingByCategory = false;
      }
    },

    async fetchAppointmentsByAgeDaily(params = { period: 'last_30_days' }) {
      this.isLoadingByAge = true;
      this.errorByAge = null;
      try {
        const response = await http.get('/api/reports/appointments-by-age-daily', { params });
        this.appointmentsByAge = response.data;
      } catch (error) {
        handleError(error);
        this.errorByAge = error.message || 'Failed to fetch age report data.';
      } finally {
        this.isLoadingByAge = false;
      }
    },

    async fetchAppointmentsByDepartmentDaily(params = { period: 'last_30_days' }) {
      this.isLoadingByDepartment = true;
      this.errorByDepartment = null;
      try {
        const response = await http.get('/api/reports/appointments-by-department-daily', { params });
        this.appointmentsByDepartment = response.data;
      } catch (error) {
        handleError(error);
        this.errorByDepartment = error.message || 'Failed to fetch department report data.';
      } finally {
        this.isLoadingByDepartment = false;
      }
    },
  },
}); 