import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import AuthenticatedLayout from '@/layouts/AuthenticatedLayout.vue'
import LoginView from '@/views/LoginView.vue'
import RegisterView from '@/views/RegisterView.vue'
import DashboardView from '@/views/DashboardView.vue'
import CategoryList from '@/views/CategoryList.vue'
import CustomerList from '@/views/CustomerList.vue'
import CustomerView from '@/views/CustomerView.vue'

const routes = [
  {
    path: '/',
    component: AuthenticatedLayout,
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        name: 'root',
        component: DashboardView
      },
      {
        path: '/dashboard',
        name: 'Dashboard',
        component: DashboardView
      },
      {
        path: '/customers',
        name: 'Customers',
        component: CustomerList
      },
      {
        path: '/customers/:uuid',
        name: 'CustomerView',
        component: CustomerView,
      },
      {
        path: '/categories',
        name: 'Categories',
        component: CategoryList
      },
      {
        path: '/settings',
        name: 'Settings',
        redirect: '/settings/users',

        children: [
          {
            path: 'roles',
            name: 'RoleManagement',
            component: () => import('@/views/Settings/RoleManagement.vue'),
            meta: { requiresAuth: true, permission: 'manage users' }
          },
          {
            path: 'users',
            name: 'UserManagement',
            component: () => import('@/views/Settings/UserManagement.vue'),
            meta: { requiresAuth: true, permission: 'manage users' }
          },
          {
            path: 'site',
            name: 'SiteSettings',
            component: () => import('@/views/Settings/SiteSettings.vue'),
            meta: { requiresAuth: true, permission: 'manage settings' }
          }
        ]
      }
    ]
  },
  {
    path: '/login',
    name: 'login',
    component: LoginView,
    meta: { guestOnly: true }
  },
  {
    path: '/register',
    name: 'register',
    component: RegisterView,
    meta: { guestOnly: true }
  }
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
})

router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()

  if (authStore.isLoading) {
    // Wait for the auth check to complete
    await authStore.checkAuth()
  }

  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next('/login')
  } else if (to.meta.guestOnly && authStore.isAuthenticated) {
    next('/')
  } else {
    next()
  }
})

export default router
