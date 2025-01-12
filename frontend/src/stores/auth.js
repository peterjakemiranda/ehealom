import { defineStore } from 'pinia'
import http from '@/utils/http'
import router from '@/router'
import { db } from '@/services/db'

export const useAuthStore = defineStore({
  id: 'auth',
  state: () => ({
    user: null,
    token: null,
    isAuthenticated: false,
    isLoading: true,
    isOnline: navigator.onLine,
    lastVerified: null,
    offlineMode: false
  }),
  getters: {
    isLandlord: (state) => state.user && state.user.role === 'landlord',
    isTenant: (state) => state.user && state.user.role === 'tenant'
  },
  actions: {
    async setToken(token) {
      this.token = token;
      http.defaults.headers.common['Authorization'] = `Bearer ${token}`;
      // Store in both localStorage and IndexedDB for redundancy
      localStorage.setItem('token', token);
      await db.saveAuthState({
        token,
        timestamp: Date.now()
      });
    },

    async clearAuth() {
      this.token = null;
      this.user = null;
      this.isAuthenticated = false;
      this.lastVerified = null;
      localStorage.removeItem('token');
      delete http.defaults.headers.common['Authorization'];
      await db.clearAuthState();
    },

    async login(email, password) {
      try {
        const response = await http.post('/api/login', { email, password });
        if (response.data.user && response.data.token) {
          await this.setAuthData(response.data);
          router.push('/');
        }
      } catch (error) {
        console.error('Error logging in:', error);
        throw error;
      }
    },

    async setAuthData(data) {
      this.user = data.user;
      this.isAuthenticated = true;
      this.lastVerified = new Date().toISOString();
      await this.setToken(data.token);
      
      // Save auth state to IndexedDB
      const expiresAt = new Date();
      expiresAt.setDate(expiresAt.getDate() + 7);
      
      await db.saveAuthState({
        token: data.token,
        user: data.user,
        expiresAt: expiresAt.toISOString()
      });
    },

    async register(name, email, password, password_confirmation) {
      try {
        const response = await http.post('/api/register', {
          name,
          email,
          password,
          password_confirmation
        })
        if (response.data.user && response.data.token) {
          this.user = response.data.user
          this.setToken(response.data.token)
          this.isAuthenticated = true
          return response.data.user;
        } else {
          throw new Error('Registration failed')
        }
      } catch (error) {
        console.error('Error registering:', error)
        throw error
      }
    },
    async fetchUser() {
      if (!this.token) {
        this.isLoading = false
        return
      }
      try {
        const response = await http.get('/api/me')
        this.user = response.data
        this.permissions = response.data.permissions
        this.roles = response.data.roles
        this.isAuthenticated = true
      } catch (error) {
        console.error('Error fetching user:', error)
        this.clearToken()
        this.user = null
        this.isAuthenticated = false
      } finally {
        this.isLoading = false
      }
    },
    async logout() {
      if (navigator.onLine) {
        try {
          await http.post('/api/logout');
        } catch (error) {
          console.error('Error logging out:', error);
        }
      }
      await this.clearAuth();
      router.push('/login');
    },

    async checkAuth() {
      if (this.isAuthenticated) return true;

      try {
        const authState = await db.getAuthState();
        if (!authState?.token) return false;

        const isExpired = new Date(authState.expiresAt) < new Date();
        if (isExpired) {
          await this.clearAuth();
          return false;
        }

        // Set initial state from stored data
        await this.setToken(authState.token);
        this.user = authState.user;
        this.isAuthenticated = true;
        this.offlineMode = !navigator.onLine;

        // Only verify with server if online
        if (navigator.onLine) {
          try {
            const response = await http.get('/api/me');
            this.user = response.data;
            return true;
          } catch (error) {
            if (error.response?.status === 401) {
              await this.clearAuth();
              return false;
            }
            // If server is unreachable but we have valid stored auth, stay logged in
            console.warn('Server unreachable, continuing in offline mode');
            this.offlineMode = true;
            return true;
          }
        }
        
        return true;
      } catch (error) {
        console.error('Auth check failed:', error);
        return false;
      } finally {
        this.isLoading = false;
      }
    },

    async initializeAuth() {
      this.isLoading = true;
      try {
        // Try localStorage first (faster)
        let token = localStorage.getItem('token');
        
        // If not in localStorage, try IndexedDB
        if (!token) {
          const authState = await db.getAuthState();
          token = authState?.token;
          
          // Restore token to localStorage if found in IndexedDB
          if (token) {
            localStorage.setItem('token', token);
          }
        }

        if (token) {
          await this.setToken(token);
          await this.checkAuth();
        }
      } catch (error) {
        console.error('Auth initialization failed:', error);
      } finally {
        this.isLoading = false;
      }
    },
    hasPermission(permission) {
      return this.permissions.includes(permission)
    },

    hasRole(role) {
      return this.roles.includes(role)
    }
  }
});

// Add online/offline listeners
window.addEventListener('online', async () => {
  const authStore = useAuthStore();
  if (authStore.isAuthenticated) {
    authStore.checkAuth(); // Verify auth state when coming back online
  }
});

window.addEventListener('offline', () => {
  const authStore = useAuthStore();
  authStore.isOnline = false;
});
