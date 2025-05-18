import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import AuthenticatedLayout from '@/layouts/AuthenticatedLayout.vue'
import LoginView from '@/views/LoginView.vue'
import RegisterView from '@/views/RegisterView.vue'
import CategoryList from '@/views/CategoryList.vue'
import ResourceList from '@/views/ResourceList.vue'
import AppointmentList from '@/views/AppointmentList.vue'
import CounselorSchedule from '@/views/Settings/CounselorSchedule.vue'
import ProfileView from '@/views/ProfileView.vue'
import ReportPage from '@/views/ReportPage.vue'

const routes = [
  {
    path: '/',
    component: AuthenticatedLayout,
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        name: 'dashboard',
        component: AppointmentList
      },
      {
        path: '/categories',
        name: 'Categories',
        component: CategoryList
      },
      {
        path: '/resources',
        name: 'Resources',
        component: ResourceList
      }, 
      {
        path: '/appointments',
        name: 'appointments',
        component: AppointmentList
      },
      {
        path: '/schedule',
        name: 'CounselorSchedule',
        component: CounselorSchedule,
        meta: { 
          requiresAuth: true, 
          roles: ['counselor']
        }
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
            meta: { requiresAuth: true, permission: 'manage users' }
          }
        ]
      },
      {
        path: '/profile',
        name: 'profile',
        component: ProfileView,
        meta: {
          requiresAuth: true,
          title: 'My Profile'
        }
      },
      {
        path: '/reports',
        name: 'Reports',
        component: ReportPage,
        meta: {
          requiresAuth: true,
          permission: 'view reports'
        }
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

  // Wait for the auth check to complete
  if (authStore.isLoading) {
    await authStore.checkAuth()
  }

  // Add error handling for auth check
  try {
    if (to.meta.requiresAuth && !authStore.isAuthenticated) {
      next('/login')
    } else if (to.meta.guestOnly && authStore.isAuthenticated) {
      next('/appointments')
    } else {
      next()
    }
  } catch (error) {
    console.error('Navigation error:', error)
    next('/login')
  }
})

export default router
