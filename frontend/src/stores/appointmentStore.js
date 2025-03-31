import { defineStore } from 'pinia'
import http from '../utils/http'
import { handleError, handleSuccess } from '../utils/messageHandler'

export const useAppointmentStore = defineStore({
  id: 'appointmentStore',
  state: () => ({
    appointments: [],
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
    availableSlots: []
  }),

  getters: {
    hasAppointments: (state) => state.appointments.length > 0,
    totalPages: (state) => state.pagination.last_page,
    currentPage: (state) => state.pagination.current_page,
    upcomingAppointments: (state) => {
      return state.appointments.filter(apt => 
        apt.status === 'pending' || apt.status === 'confirmed'
      ).sort((a, b) => new Date(a.appointment_date) - new Date(b.appointment_date))
    }
  },

  actions: {
    async fetchAppointments({ 
      page = 1, 
      status = '', 
      date = '', 
      perPage = 10,
      user_type = '',
      search = ''
    } = {}) {
      this.isLoading = true
      this.error = null

      try {
        const params = { 
          page, 
          per_page: perPage,
          ...(status && { status }),
          ...(date && { date }),
          ...(user_type && { user_type }),
          ...(search && { search })
        }

        console.log('Fetching appointments with params:', params)
        const response = await http.get('/api/appointments', { params })
        
        this.appointments = response.data.data
        this.pagination = response.data.meta
      } catch (error) {
        this.error = error.response?.data?.message || 'An error occurred'
        throw error
      } finally {
        this.isLoading = false
      }
    },

    async createAppointment(appointment) {
      try {
        const response = await http.post('/api/appointments', appointment)
        const newAppointment = response.data.data
        
        // Update local list
        this.appointments = [newAppointment, ...this.appointments]
        
        handleSuccess('Appointment created successfully')
        return newAppointment
      } catch (error) {
        console.error('Error adding appointment:', error)
        handleError(error)
        throw error
      }
    },

    async updateAppointment(uuid, appointment) {
      try {
        const response = await http.put(`/api/appointments/${uuid}`, appointment)
        const updatedAppointment = response.data.data
        
        // Update local list
        const index = this.appointments.findIndex(a => a.uuid === uuid)
        if (index !== -1) {
          this.appointments = [
            ...this.appointments.slice(0, index),
            updatedAppointment,
            ...this.appointments.slice(index + 1)
          ]
        }

        handleSuccess('Appointment updated successfully')
        return updatedAppointment
      } catch (error) {
        handleError(error)
        throw error
      }
    },

    async updateAppointmentStatus(uuid, status) {
      try {
        const response = await http.put(`/api/appointments/${uuid}`, { status })
        const updatedAppointment = response.data.data
        
        // Update local list
        const index = this.appointments.findIndex(a => a.uuid === uuid)
        if (index !== -1) {
          this.appointments = [
            ...this.appointments.slice(0, index),
            updatedAppointment,
            ...this.appointments.slice(index + 1)
          ]
        }

        // Show appropriate success message based on status
        const messages = {
          confirmed: 'Appointment confirmed successfully',
          completed: 'Appointment marked as completed',
          cancelled: 'Appointment cancelled successfully'
        }
        handleSuccess(messages[status] || 'Appointment status updated')
        
        return updatedAppointment
      } catch (error) {
        handleError(error)
        throw error
      }
    },

    async deleteAppointment(uuid) {
      try {
        await http.delete(`/api/appointments/${uuid}`)
        // Remove from local list
        this.appointments = this.appointments.filter(a => a.uuid !== uuid)
        handleSuccess('Appointment deleted successfully')
      } catch (error) {
        handleError(error)
        throw error
      }
    },

    async fetchAvailableSlots(counselorId, date) {
      this.isLoading = true
      try {
        const { data } = await http.get('/api/appointments/available-slots', {
          params: {
            counselor_id: counselorId,
            date: date
          }
        })
        this.availableSlots = data.slots
        return data.slots
      } catch (error) {
        // handleError(error)
        console.error('Error fetching available slots:', error)
        throw error
      } finally {
        this.isLoading = false
      }
    }
  }
}) 