import { defineStore } from 'pinia'
import http from '@/utils/http'
import { handleError } from '@/utils/messageHandler'

const weekDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']

const defaultSchedule = weekDays.reduce((acc, day) => ({
  ...acc,
  [day]: {
    is_available: false,
    start_time: '09:00',
    end_time: '17:00',
    break_start: '12:00',
    break_end: '13:00'
  }
}), {})

export const useCounselorScheduleStore = defineStore('counselorSchedule', {
  state: () => ({
    schedule: defaultSchedule,
    excludedDates: [],
    existingExcludedDates: [],
    isLoadingSchedule: false,
    isLoadingExcludedDates: false,
    error: null
  }),

  getters: {
    getSchedule: (state) => state.schedule,
    getExcludedDates: (state) => state.existingExcludedDates,
    isLoading: (state) => state.isLoadingSchedule || state.isLoadingExcludedDates,
  },

  actions: {
    async fetchSchedule() {
      this.isLoadingSchedule = true
      try {
        const { data } = await http.get('/api/counselor/schedule')
        
        // Merge saved schedule with default values
        this.schedule = weekDays.reduce((acc, day) => {
          const savedDay = data.schedule.find(d => d.day === day)
          return {
            ...acc,
            [day]: savedDay ? {
              is_available: savedDay.is_available,
              start_time: savedDay.start_time,
              end_time: savedDay.end_time,
              break_start: savedDay.break_start,
              break_end: savedDay.break_end
            } : defaultSchedule[day]
          }
        }, {})
        
        this.existingExcludedDates = data.excluded_dates || []
        return data
      } catch (error) {
        handleError(error)
        throw error
      } finally {
        this.isLoadingSchedule = false
      }
    },

    async updateSchedule(scheduleData) {
      this.isLoadingSchedule = true
      try {
        const { data } = await http.post('/api/counselor/schedule', {
          schedule: Object.entries(scheduleData).map(([day, settings]) => ({
            day,
            ...settings
          }))
        })
        await this.fetchSchedule() // Refresh data after update
        return data
      } catch (error) {
        handleError(error)
        throw error
      } finally {
        this.isLoadingSchedule = false
      }
    },

    async updateExcludedDates(dates) {
      this.isLoadingExcludedDates = true
      try {
        const { data } = await http.post('/api/counselor/excluded-dates', { dates })
        // Refresh data to get the new dates with their IDs
        await this.fetchSchedule()
        return data
      } catch (error) {
        handleError(error)
        throw error
      } finally {
        this.isLoadingExcludedDates = false
      }
    },

    async deleteExcludedDate(id) {
      this.isLoadingExcludedDates = true
      try {
        await http.delete(`/api/counselor/excluded-dates/${id}`)
        this.existingExcludedDates = this.existingExcludedDates.filter(date => date.id !== id)
      } catch (error) {
        handleError(error)
        throw error
      } finally {
        this.isLoadingExcludedDates = false
      }
    },

    resetState() {
      this.schedule = defaultSchedule
      this.excludedDates = []
      this.isLoadingSchedule = false
      this.isLoadingExcludedDates = false
      this.error = null
    }
  }
}) 