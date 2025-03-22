<template>
  <div class="container mx-auto">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-3xl font-bold text-primary">All Users</h1>
      <button @click="createUser" class="btn btn-primary">
        <UserPlusIcon class="h-5 w-5 mr-2" />
        Add User
      </button>
    </div>

    <!-- Search and Filter -->
    <div class="mb-6 flex items-center gap-2">
      <div class="flex-1 flex items-center gap-2">
        <input
          type="text"
          v-model="searchQuery"
          placeholder="Search users..."
          class="input input-bordered w-full max-w-xs text-lg"
        />
        <button class="btn btn-square" @click="searchQuery = ''" v-if="searchQuery">
          <XMarkIcon class="h-6 w-6" />
        </button>
      </div>
    </div>

    <!-- Users List -->
    <nav class="h-full overflow-y-auto rounded-lg bg-white shadow-sm p-5" aria-label="Users">
      <div v-if="userStore.users.length > 0">
        <ul role="list" class="divide-y divide-gray-100">
          <li
            v-for="user in userStore.users"
            :key="user.id"
            class="flex gap-x-4 px-3 py-4 cursor-pointer hover:bg-gray-50"
            @click="editUser(user)"
          >
            <div class="avatar placeholder mr-4">
              <div class="bg-neutral-focus text-neutral-content rounded-full w-12 h-12 border">
                <span class="text-md">{{ getInitials(user.name) }}</span>
              </div>
            </div>
            <div class="min-w-0 flex-auto">
              <div class="flex justify-between items-start">
                <div>
                  <p class="text-lg font-semibold leading-6 text-gray-900">
                    {{ user.name }}
                  </p>
                  <p class="mt-1 text-sm leading-5 text-gray-500">
                    {{ user.email }}
                  </p>
                  <div class="flex gap-2 mt-1">
                    <span v-for="role in user.roles" :key="role.id" class="badge">
                      {{ role }}
                    </span>
                  </div>
                </div>
                <div class="flex flex-col items-end gap-2">
                  <span :class="['badge', user.status ? 'badge-success' : 'badge-error']">
                    {{ user.status ? 'Active' : 'Inactive' }}
                  </span>
                  <div class="flex gap-2">
                    <button 
                      v-if="canManageUsers"
                      @click.stop="confirmDelete(user)"
                      class="btn btn-ghost btn-sm text-error hover:bg-error hover:text-white"
                    >
                      <TrashIcon class="h-4 w-4" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </li>
        </ul>
      </div>

      <!-- Empty State -->
      <div v-else class="text-center py-12">
        <UserGroupIcon class="h-16 w-16 mx-auto text-gray-400 mb-4" />
        <h2 class="text-2xl font-semibold text-gray-700 mb-2">
          {{ searchQuery ? 'No users found' : 'No users yet'  }}
        </h2>
        <p class="text-gray-500 mb-4">
          {{ 
            searchQuery
              ? 'Try adjusting your search terms'
              : 'Get started by adding your first user!'
          }}
        </p>
        <button v-if="!searchQuery" @click="createUser" class="btn btn-primary">
          Add Your First User
        </button>
      </div>
    </nav>

    <!-- Pagination -->
    <PaginationBar
      v-if="userStore.pagination.last_page > 1"
      :current-page="userStore.pagination.current_page"
      :last-page="userStore.pagination.last_page"
      @page-change="changePage"
    />

    <!-- User Form Drawer -->
    <BaseDrawer
      v-model="showDrawer"
      :title="isEditing ? 'Edit User' : 'Add User'"
    >
      <UserForm
        v-if="selectedUser"
        :user="selectedUser"
        :roles="roleStore.roles"
        @save="handleSave"
        @cancel="closeDrawer"
      />
    </BaseDrawer>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue'
import { useUserStore } from '@/stores/userStore'
import { useRoleStore } from '@/stores/roleStore'
import { useAuthStore } from '@/stores/auth'
import { UserPlusIcon, UserGroupIcon, XMarkIcon, TrashIcon } from '@heroicons/vue/24/outline'
import BaseDrawer from '@/components/common/BaseDrawer.vue'
import UserForm from '@/components/UserForm.vue'
import PaginationBar from '@/components/PaginationBar.vue'
import { swalHelper } from '@/utils/swalHelper'

const userStore = useUserStore()
const roleStore = useRoleStore()
const authStore = useAuthStore()
const searchQuery = ref('')
const showDrawer = ref(false)
const selectedUser = ref(null)
const isEditing = computed(() => !!selectedUser.value?.id)

// Add computed property for user permissions
const canManageUsers = computed(() => {
  return authStore.user?.permissions?.includes('manage users') || false
})

onMounted(async () => {
  await Promise.all([
    fetchUsers(),
    roleStore.fetchRoles() // Keep this to populate role options in form
  ])
})

async function fetchUsers(page = 1) {
  await userStore.fetchUsers({
    page,
    search: searchQuery.value
  })
}

function createUser() {
  selectedUser.value = {
    id: null,
    name: '',
    email: '',
    password: '',
    roles: [], // Using role names array
    status: true
  }
  showDrawer.value = true
}

function editUser(user) {
  selectedUser.value = { ...user }
  showDrawer.value = true
}

function closeDrawer() {
  showDrawer.value = false
  selectedUser.value = null
}

async function handleSave(userData) {
  try {
    if (isEditing.value) {
      await userStore.updateUser(userData.uuid, userData)
      swalHelper.toast('success', 'User updated successfully')
    } else {
      await userStore.createUser(userData)
      swalHelper.toast('success', 'User created successfully')
    }
    closeDrawer()
    await fetchUsers(userStore.pagination.current_page)
  } catch (error) {
    swalHelper.toast('error', `Failed to ${isEditing.value ? 'update' : 'create'} user`)
  }
}

function changePage(page) {
  fetchUsers(page)
}

watch(searchQuery, () => {
  fetchUsers(1)
})

// Add this helper function
function getInitials(name) {
  if (!name) return '##'
  return name
    .split(' ')
    .map(word => word.charAt(0))
    .join('')
    .toUpperCase()
    .substring(0, 2)
}

async function confirmDelete(user) {
  try {
    const result = await swalHelper.confirm({
      title: 'Delete User',
      text: `Are you sure you want to delete ${user.name}?`,
      icon: 'warning',
      confirmButtonText: 'Yes, delete it!',
      confirmButtonColor: '#dc2626'
    })

    if (result.isConfirmed) {
      await userStore.deleteUser(user.uuid)
      swalHelper.toast('success', 'User deleted successfully')
      await fetchUsers(userStore.pagination.current_page)
    }
  } catch (error) {
    swalHelper.toast('error', 'Failed to delete user')
  }
}
</script>
