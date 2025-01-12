import './assets/main.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import { useAuthStore } from './stores/auth'
import { vCurrency } from './directives/currency'
import { formatCurrency } from './utils/currency'
import { ensureDbInitialized } from './services/db'
import { backgroundSync } from './services/backgroundSync'

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.directive('currency', vCurrency)

app.config.globalProperties.$currency = formatCurrency

const authStore = useAuthStore()

async function initApp() {
    try {
        await ensureDbInitialized();
        await authStore.initializeAuth();
        
        // Mount the app immediately
        app.mount('#app');
        
        if (authStore.isAuthenticated) {
          backgroundSync.initialize();
        }
    } catch (error) {
        console.error('Failed to initialize app:', error);
    }
}

if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('/sw.js')
        .then(registration => {
          console.log('ServiceWorker registered: ', registration);
        })
        .catch(error => {
          console.log('ServiceWorker registration failed: ', error);
        });
    });
  }

initApp();
