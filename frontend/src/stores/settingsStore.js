import { defineStore } from 'pinia'
import http from '../utils/http'
import { db } from '../services/db'
import { handleError } from '../utils/messageHandler'

export const useSettingsStore = defineStore('settings', {
  state: () => ({
    settings: {
      site_name: '',
      site_logo: '',
      business_name: '',
      business_address: '',
      pawn_ticket_header: ''  // Add this line
    },
    isLoading: false,
    error: null,
    lastFetched: null
  }),

  getters: {
    getSiteName: (state) => state.settings.site_name,
    getSiteLogo: (state) => state.settings.site_logo,
    getBusinessName: (state) => state.settings.business_name,
    getBusinessAddress: (state) => state.settings.business_address,
    getPawnTicketHeader: (state) => state.settings.pawn_ticket_header
  },

  actions: {
    async fetchSettings() {
      // If we've fetched within the last hour and have settings, don't fetch again
      const now = new Date().getTime()
      if (this.lastFetched && (now - this.lastFetched) < 3600000 && this.settings.site_name) {
        return this.settings
      }

      this.isLoading = true
      this.error = null

      try {
        // Get from IndexedDB first
        const cachedSettings = await db.settings.get('site-settings')
        if (cachedSettings) {
          this.settings = cachedSettings.data
        }

        // Only fetch from server if online
        if (navigator.onLine) {
          const { data } = await http.get('/api/settings')
          
          // Save to IndexedDB
          await db.settings.put({
            id: 'site-settings',
            data: data,
            updated_at: new Date().toISOString()
          })

          this.settings = data
          this.lastFetched = now
        }

        return this.settings
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to fetch settings'
        handleError(error)
        throw error
      } finally {
        this.isLoading = false
      }
    },

    async updateSettings(settingsData) {
      if (!navigator.onLine) {
        handleError('Cannot update settings while offline')
        return
      }

      this.isLoading = true
      this.error = null

      try {
        let dataToSend;

        if (settingsData instanceof FormData) {
          const file = settingsData.get('site_logo');
          let logo = null;

          if (file instanceof File) {
            // Convert file to base64
            logo = await new Promise((resolve) => {
              const reader = new FileReader();
              reader.onloadend = () => resolve(reader.result);
              reader.readAsDataURL(file);
            });
          }

          dataToSend = {
            site_name: settingsData.get('site_name'),
            business_name: settingsData.get('business_name'),
            business_address: settingsData.get('business_address'),
            site_logo: logo
          };
        } else {
          dataToSend = settingsData;
        }

        const { data } = await http.post('/api/settings', dataToSend);
        
        // Update IndexedDB
        await db.settings.put({
          id: 'site-settings',
          data: data.settings,
          updated_at: new Date().toISOString()
        });

        this.settings = data.settings;
        this.lastFetched = new Date().getTime();
        
        return this.settings;
      } catch (error) {
        this.error = error.response?.data?.message || 'Failed to update settings';
        handleError(error);
        throw error;
      } finally {
        this.isLoading = false;
      }
    },

    resetSettings() {
      this.settings = {
        site_name: '',
        site_logo: '',
        business_name: '',
        business_address: ''
      }
      this.error = null
    }
  }
})
