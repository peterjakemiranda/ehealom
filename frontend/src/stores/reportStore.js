import { defineStore } from 'pinia';
import http from '../utils/http';

export const useReportStore = defineStore('report', {
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
    async fetchAppointmentsByCategoryDaily(params = {}) {
      this.isLoadingByCategory = true;
      this.errorByCategory = null;
      try {
        const response = await http.get('/api/reports/appointments-by-category-daily', { params });
        console.log('Category data received:', response.data);
        this.appointmentsByCategory = response.data;
      } catch (error) {
        console.error('Category data error:', error.response || error);
        this.errorByCategory = error.response?.data?.message || error.message || 'Failed to fetch category data';
      } finally {
        this.isLoadingByCategory = false;
      }
    },

    async fetchAppointmentsByAgeDaily(params = {}) {
      this.isLoadingByAge = true;
      this.errorByAge = null;
      try {
        const response = await http.get('/api/reports/appointments-by-age-daily', { params });
        console.log('Age data received:', response.data);
        this.appointmentsByAge = response.data;
      } catch (error) {
        console.error('Age data error:', error.response || error);
        this.errorByAge = error.response?.data?.message || error.message || 'Failed to fetch age data';
      } finally {
        this.isLoadingByAge = false;
      }
    },

    async fetchAppointmentsByDepartmentDaily(params = {}) {
      this.isLoadingByDepartment = true;
      this.errorByDepartment = null;
      try {
        const response = await http.get('/api/reports/appointments-by-department-daily', { params });
        console.log('Department data received:', response.data);
        this.appointmentsByDepartment = response.data;
      } catch (error) {
        console.error('Department data error:', error.response || error);
        this.errorByDepartment = error.response?.data?.message || error.message || 'Failed to fetch department data';
      } finally {
        this.isLoadingByDepartment = false;
      }
    },
  },
}); 