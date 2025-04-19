<template>
  <div class="min-h-screen flex bg-[#f6f6f6]">
    <!-- Show loading state while permissions are being loaded -->
    <div v-if="isLoading" class="flex-1 flex items-center justify-center">
      <div class="loading loading-spinner loading-lg text-primary"></div>
    </div>

    <!-- Only show the layout once permissions are loaded -->
    <template v-else>
      <!-- Sidebar for desktop -->
      <div class="hidden lg:flex lg:flex-shrink-0 lg:w-64">
        <div class="flex flex-col w-64 border-r border-gray-200 bg-white">
          <!-- Logo section in desktop sidebar -->
          <div class="flex h-16 flex-shrink-0 items-center px-4">
            <img 
              src="@/assets/logo.png"
              alt="E-Healom"
              class="w-4/5 w-auto"
            />
          </div>
          <nav class="flex flex-1 flex-col overflow-y-auto">
            <ul class="flex flex-1 flex-col gap-y-7 px-6 py-6">
              <li>
                <ul class="-mx-2 space-y-3">
                  <li v-for="item in visibleNavigation" :key="item.name">
                    <template v-if="item.children">
                      <router-link
                        :to="item.href"
                        custom
                        v-slot="{ navigate }"
                      >
                        <div
                          :class="[
                            isParentActive(item.href)
                              ? 'bg-yellow-50 text-yellow-600'
                              : 'text-gray-700 hover:bg-yellow-50 hover:text-yellow-600',
                            'group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6',
                            isItemDisabled(item) ? 'opacity-50 cursor-not-allowed items-center' : ''
                          ]"
                          @click="!isItemDisabled(item) && navigate()"
                        >
                          <component
                            :is="item.icon"
                            :class="[
                              isParentActive(item.href)
                                ? 'text-yellow-600'
                                : 'text-gray-400 group-hover:text-yellow-600',
                              'h-6 w-6 shrink-0',
                              isItemDisabled(item) ? 'opacity-50' : ''
                            ]"
                            aria-hidden="true"
                          />
                          {{ item.name }}
                          <span v-if="isItemDisabled(item)" class="ml-2 text-xs text-gray-400">(Offline)</span>
                        </div>
                      </router-link>
                      <ul v-if="isParentActive(item.href) && !isItemDisabled(item)" class="space-y-1 mt-1 ml-2">
                        <li v-for="child in item.children" :key="child.name">
                          <router-link
                            :to="child.href"
                            :class="[
                              $route.path === child.href
                                ? 'bg-yellow-50 text-yellow-600'
                                : 'text-gray-700 hover:bg-yellow-50 hover:text-yellow-600',
                              'group flex gap-x-3 rounded-md p-2 pl-5 text-sm leading-6'
                            ]"
                          >
                            <component
                              :is="child.icon"
                              :class="[
                                $route.path === child.href
                                  ? 'text-yellow-600'
                                  : 'text-gray-400 group-hover:text-yellow-600',
                                'h-5 w-5 shrink-0'
                              ]"
                              aria-hidden="true"
                            />
                            {{ child.name }}
                          </router-link>
                        </li>
                      </ul>
                    </template>
                    <router-link
                      v-else
                      :to="item.href"
                      custom
                      v-slot="{ navigate }"
                    >
                      <div
                        :class="getMenuItemClass(item, $route.path === item.href)"
                        @click="!isItemDisabled(item) && navigate()"
                      >
                        <component
                          :is="item.icon"
                          :class="[
                            $route.path === item.href
                              ? 'text-yellow-600'
                              : 'text-gray-400 group-hover:text-yellow-600',
                            'h-6 w-6 shrink-0',
                            isItemDisabled(item) ? 'opacity-50' : ''
                          ]"
                          aria-hidden="true"
                        />
                        {{ item.name }}
                        <span v-if="isItemDisabled(item)" class="ml-2 text-xs text-gray-400">(Offline)</span>
                      </div>
                    </router-link>
                  </li>
                </ul>
              </li>
            </ul>
          </nav>
        </div>
      </div>

      <!-- Main content area -->
      <div class="flex flex-1 flex-col overflow-hidden">
        <!-- Top navigation -->
        <header class="bg-white border-b border-gray-200 shadow-sm">
          <div class="flex h-16 items-center gap-x-4 px-4 sm:gap-x-6 sm:px-6 lg:px-8">
            <!-- Sidebar toggle, controls the 'sidebarOpen' state. -->
            <button
              type="button"
              class="-m-2.5 p-2.5 text-gray-700 lg:hidden"
              @click="sidebarOpen = true"
            >
              <span class="sr-only">Open sidebar</span>
              <Bars3Icon class="h-6 w-6" aria-hidden="true" />
            </button>

            <div class="flex flex-1 gap-x-4 self-stretch lg:gap-x-6">
              <div class="relative flex flex-1"></div>
              
              <div class="flex items-center gap-x-4 lg:gap-x-6">
                

                <!-- Profile dropdown -->
                <Menu as="div" class="relative">
                  <MenuButton class="-m-1.5 flex items-center p-1.5">
                    <span class="sr-only">Open user menu</span>
                    <div
                      v-if="!authStore.user?.avatar"
                      class="h-8 w-8 rounded-full bg-primary flex items-center justify-center text-white font-medium"
                    >
                      {{ userInitials }}
                    </div>
                    <img
                      v-else
                      class="h-8 w-8 rounded-full bg-gray-50"
                      :src="authStore.user.avatar"
                      :alt="authStore.user?.username"
                    />
                    <span class="hidden lg:flex lg:items-center">
                      <span
                        class="ml-4 text-sm font-semibold leading-6 text-gray-900"
                        aria-hidden="true"
                      >
                        {{ authStore.user?.username }}
                      </span>
                      <ChevronDownIcon class="ml-2 h-5 w-5 text-gray-400" aria-hidden="true" />
                    </span>
                  </MenuButton>
                  <transition
                    enter-active-class="transition ease-out duration-100"
                    enter-from-class="transform opacity-0 scale-95"
                    enter-to-class="transform opacity-100 scale-100"
                    leave-active-class="transition ease-in duration-75"
                    leave-from-class="transform opacity-100 scale-100"
                    leave-to-class="transform opacity-0 scale-95"
                  >
                    <MenuItems
                      class="absolute right-0 z-10 mt-2.5 w-32 origin-top-right rounded-md bg-white py-2 shadow-sm ring-1 ring-gray-900/5 focus:outline-none"
                    >
                      <MenuItem v-for="item in userNavigation" :key="item.name" v-slot="{ active }">
                        <a
                          :href="item.href"
                          :class="[
                            active ? 'bg-gray-50' : '',
                            'block px-3 py-3 text-sm leading-6 text-gray-900'
                          ]"
                          @click="item.action && item.action()"
                        >
                          {{ item.name }}
                        </a>
                      </MenuItem>
                    </MenuItems>
                  </transition>
                </Menu>
              </div>
            </div>
          </div>
        </header>

        <!-- Main content -->
        <main class="flex-1 overflow-y-auto">
          <div class="py-5 px-4 sm:px-6 lg:px-8">
            <router-view></router-view>
          </div>
        </main>
      </div>
    </template>
  </div>
  <!-- Mobile sidebar -->
  <TransitionRoot as="template" :show="sidebarOpen">
    <Dialog as="div" class="relative z-50 lg:hidden" @close="sidebarOpen = false">
      <TransitionChild
        as="template"
        enter="transition-opacity ease-linear duration-300"
        enter-from="opacity-0"
        enter-to="opacity-100"
        leave="transition-opacity ease-linear duration-300"
        leave-from="opacity-100"
        leave-to="opacity-0"
      >
        <div class="fixed inset-0 bg-gray-900/80" />
      </TransitionChild>

      <div class="fixed inset-0 flex">
        <TransitionChild
          as="template"
          enter="transition ease-in-out duration-300 transform"
          enter-from="-translate-x-full"
          enter-to="translate-x-0"
          leave="transition ease-in-out duration-300 transform"
          leave-from="translate-x-0"
          leave-to="-translate-x-full"
        >
          <DialogPanel class="relative mr-16 flex w-full max-w-xs flex-1">
            <TransitionChild
              as="template"
              enter="ease-in-out duration-300"
              enter-from="opacity-0"
              enter-to="opacity-100"
              leave="ease-in-out duration-300"
              leave-from="opacity-100"
              leave-to="opacity-0"
            >
              <div class="absolute left-full top-0 flex w-16 justify-center pt-5">
                <button type="button" class="-m-2.5 p-2.5" @click="sidebarOpen = false">
                  <span class="sr-only">Close sidebar</span>
                  <XMarkIcon class="h-6 w-6 text-white" aria-hidden="true" />
                </button>
              </div>
            </TransitionChild>
            <!-- Sidebar component for mobile -->
            <div class="flex grow flex-col gap-y-5 overflow-y-auto bg-white px-6 pb-2">
              <!-- Logo in mobile sidebar -->
              <div class="flex h-16 shrink-0 items-center">
                <img 
                  src="@/assets/logo.png"
                  alt="E-Healom"
                  class="h-8 w-auto"
                />
              </div>
              <nav class="flex flex-1 flex-col">
                <ul role="list" class="flex flex-1 flex-col gap-y-7">
                  <li>
                    <ul role="list" class="-mx-2 space-y-1">
                      <li v-for="item in visibleNavigation" :key="item.name">
                        <template v-if="item.children">
                          <router-link
                            :to="item.href"
                            custom
                            v-slot="{ navigate }"
                          >
                            <div
                              :class="[
                                isParentActive(item.href)
                                  ? 'bg-yellow-50 text-yellow-600'
                                  : 'text-gray-700 hover:bg-yellow-50 hover:text-yellow-600',
                                'group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6',
                                isItemDisabled(item) ? 'opacity-50 cursor-not-allowed' : ''
                              ]"
                              @click="!isItemDisabled(item) && navigate()"
                            >
                              <component
                                :is="item.icon"
                                :class="[
                                  isParentActive(item.href)
                                    ? 'text-yellow-600'
                                    : 'text-gray-400 group-hover:text-yellow-600',
                                  'h-6 w-6 shrink-0'
                                ]"
                                aria-hidden="true"
                              />
                              {{ item.name }}
                              <span v-if="isItemDisabled(item)" class="ml-2 text-xs text-gray-400">(Offline)</span>
                            </div>
                          </router-link>
                          <ul v-if="isParentActive(item.href) && !isItemDisabled(item)" class="mt-1 ml-2 space-y-1">
                            <li v-for="child in item.children" :key="child.name">
                              <router-link
                                :to="child.href"
                                :class="[
                                  $route.path === child.href
                                    ? 'bg-yellow-50 text-yellow-600'
                                    : 'text-gray-700 hover:bg-yellow-50 hover:text-yellow-600',
                                  'group flex gap-x-3 rounded-md p-2 pl-5 text-sm leading-6'
                                ]"
                                @click="closeSidebar"
                              >
                                <component
                                  :is="child.icon"
                                  :class="[
                                    $route.path === child.href
                                      ? 'text-yellow-600'
                                      : 'text-gray-400 group-hover:text-yellow-600',
                                    'h-5 w-5 shrink-0'
                                  ]"
                                  aria-hidden="true"
                                />
                                {{ child.name }}
                              </router-link>
                            </li>
                          </ul>
                        </template>
                        <router-link
                          v-else
                          :to="item.href"
                          :class="getMenuItemClass(item, $route.path === item.href)"
                          @click="closeSidebar"
                        >
                          <component
                            :is="item.icon"
                            :class="[
                              $route.path === item.href
                                ? 'text-yellow-600'
                                : 'text-gray-400 group-hover:text-yellow-600',
                              'h-6 w-6 shrink-0'
                            ]"
                            aria-hidden="true"
                          />
                          {{ item.name }}
                          <span v-if="isItemDisabled(item)" class="ml-2 text-xs text-gray-400">(Offline)</span>
                        </router-link>
                      </li>
                    </ul>
                  </li>
                </ul>
              </nav>
            </div>
          </DialogPanel>
        </TransitionChild>
      </div>
    </Dialog>
  </TransitionRoot>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import {
  Dialog,
  DialogPanel,
  Menu,
  MenuButton,
  MenuItem,
  MenuItems,
  TransitionChild,
  TransitionRoot
} from '@headlessui/vue'
import {
  Bars3Icon,
  BellIcon,
  XMarkIcon,
  HomeIcon,
  UserGroupIcon,
  BuildingOfficeIcon,
  ChartBarIcon,
  BanknotesIcon,
  ExclamationTriangleIcon,
  BuildingStorefrontIcon,
  ClipboardDocumentListIcon,
  ShoppingBagIcon,
  CurrencyDollarIcon,
  Cog6ToothIcon,
  UsersIcon,
  KeyIcon,
  PhoneIcon,
  ListBulletIcon,
  CalendarIcon,
  TagIcon,
  QueueListIcon,
  ClockIcon
} from '@heroicons/vue/24/outline'
import { ChevronDownIcon, MagnifyingGlassIcon } from '@heroicons/vue/20/solid'
import router from '../router'

const sidebarOpen = ref(false)
const authStore = useAuthStore()
const route = useRoute()
const isOnline = ref(navigator.onLine)
const isLoading = ref(true)

// Simplify the watcher to be more direct
watch(
  () => authStore.user?.permissions,
  (permissions) => {
    if (permissions) {
      isLoading.value = false
    }
  },
  { immediate: true }
)

// Remove the checkAuth call from onMounted since it's already handled by the router
onMounted(() => {
  window.addEventListener('online', updateOnlineStatus)
  window.addEventListener('offline', updateOnlineStatus)
})

onUnmounted(() => {
  window.removeEventListener('online', updateOnlineStatus)
  window.removeEventListener('offline', updateOnlineStatus)
})

const updateOnlineStatus = () => {
  isOnline.value = navigator.onLine
}

const navigation = [
  { 
    name: 'Appointments', 
    href: '/appointments', 
    icon: CalendarIcon, 
    requiresOnline: true,
    requiresPermission: 'view appointments'
  },
  { 
    name: 'Categories', 
    href: '/categories', 
    icon: QueueListIcon, 
    requiresOnline: true,
    requiresPermission: 'view resources'
  },
  { 
    name: 'Resources', 
    href: '/resources', 
    icon: ListBulletIcon, 
    requiresOnline: true,
    requiresPermission: 'view resources'
  },
  { 
    name: 'My Schedule', 
    href: '/schedule', 
    icon: ClockIcon, 
    requiresOnline: true,
    requiresRole: 'counselor'
  },
  { 
    name: 'Settings', 
    href: '/settings',
    requiresOnline: true,
    icon: Cog6ToothIcon,
    requiresPermission: 'manage users',
    children: [
      { 
        name: 'Users', 
        href: '/settings/users',
        icon: UsersIcon,
        requiresOnline: true,
        requiresPermission: 'manage users'
      },
      { 
        name: 'Roles & Permissions', 
        href: '/settings/roles',
        icon: KeyIcon,
        requiresOnline: true,
        requiresPermission: 'manage users'
      },
      {
        name: 'Site Settings',
        href: '/settings/site',
        icon: Cog6ToothIcon,
        requiresOnline: true,
        requiresPermission: 'manage users'
      }
    ]
  }
]

const isParentActive = (parentPath) => {
  return route.path.startsWith(parentPath)
}

const userNavigation = computed(() => {
  const hasManageUsers = authStore.user?.permissions?.includes('manage users')
  return [
    { name: 'My Profile', href: '/profile' },
    ...(hasManageUsers ? [{ name: 'Settings', href: '/settings' }] : []),
    { name: 'Sign Out', href: '/', action: () => handleLogout() }
  ]
})

const handleLogout = () => {
  authStore.logout()
  router.push('/login')
}

const closeSidebar = () => {
  sidebarOpen.value = false
}

const isItemDisabled = (item) => {
  // Check for online requirement
  if (item.requiresOnline && !isOnline.value) {
    return true;
  }
  
  // Check for permission requirement
  if (item.requiresPermission && !authStore.user?.permissions?.includes(item.requiresPermission)) {
    return true;
  }
  
  // Check for role requirement
  if (item.requiresRole && !authStore.user?.roles?.includes(item.requiresRole)) {
    return true;
  }
  
  // If it's a parent with children, check if all children are disabled
  if (item.children) {
    const allChildrenDisabled = item.children.every(child => 
      (child.requiresOnline && !isOnline.value) || 
      (child.requiresPermission && !authStore.user?.permissions?.includes(child.requiresPermission)) ||
      (child.requiresRole && !authStore.user?.roles?.includes(child.requiresRole))
    );
    return allChildrenDisabled;
  }
  
  return false;
}

// Replace the NavigationLink computed with a simpler approach
const getMenuItemClass = (item, isActive) => {
  return [
    isActive ? 'bg-yellow-50 text-yellow-600' : 'text-gray-700 hover:bg-yellow-50 hover:text-yellow-600',
    'group flex gap-x-3 rounded-md p-2 text-sm leading-6',
    isItemDisabled(item) ? 'opacity-50 cursor-not-allowed items-center' : ''
  ];
};

// Add this computed property
const userInitials = computed(() => {
  if (!authStore.user?.user?.name) return '?';
  const username = authStore.user.user.name;
  if (username.includes(' ')) {
    // If username has spaces, take first letter of each word
    return username
      .split(' ')
      .map(word => word.charAt(0).toUpperCase())
      .slice(0, 2)
      .join('');
  }
  // Otherwise just take the first letter
  return username.charAt(0).toUpperCase();
});

// Update visibleNavigation to be more defensive
const visibleNavigation = computed(() => {
  const permissions = authStore.user?.permissions
  if (!permissions) {
    return []
  }

  return navigation.filter(item => {
    if (item.children) {
      const hasAccessibleChildren = item.children.some(child => !isItemDisabled(child))
      return hasAccessibleChildren
    }
    return !isItemDisabled(item)
  })
})

// Add a debug log to check permissions
// console.log('User Permissions:', authStore.user?.permissions)

</script>

<style scoped>
.cursor-not-allowed {
  pointer-events: none;
}
</style>
