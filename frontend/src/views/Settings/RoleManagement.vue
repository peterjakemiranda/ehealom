<template>
  <div class="container mx-auto p-4">
    <!-- Header -->
    <div class="flex justify-between items-center mb-6">
      <div>
        <h1 class="text-2xl font-bold">Roles</h1>
        <p class="text-gray-600">Manage system roles and their permissions</p>
      </div>
      <button @click="createRole" class="btn btn-primary">
        <PlusCircleIcon class="h-5 w-5 mr-2" />
        Add Role
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="roleStore.isLoading" class="text-center py-12">
      <div class="loading loading-spinner loading-lg"></div>
      <p class="mt-4 text-gray-600">Loading roles...</p>
    </div>

    <!-- Error State -->
    <div v-else-if="roleStore.error" class="alert alert-error shadow-sm">
      <ExclamationCircleIcon class="h-6 w-6" />
      <span>{{ roleStore.error }}</span>
      <button class="btn btn-sm btn-ghost" @click="fetchRoles">Retry</button>
    </div>

    <!-- Roles Grid -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <div 
        v-for="role in roleStore.roles" 
        :key="role.id"
        class="card bg-base-100 shadow-sm"
      >
        <div class="card-body">
          <div class="flex justify-between items-start">
            <div>
              <h3 class="font-bold">{{ role.name }}</h3>
            </div>
          </div>

          <div class="mt-4">
            <h4 class="text-sm font-semibold text-gray-600 mb-2">Permissions:</h4>
            <div class="flex flex-wrap gap-1">
              <span 
                v-for="permission in role.permissions" 
                :key="permission.id"
                class="badge badge-sm"
              >
                {{ permission }}
              </span>
            </div>
          </div>
          <!-- Add Actions section at the bottom -->
          <div class="card-actions justify-end mt-4">
            <button 
              class="btn btn-primary btn-sm" 
              @click="editRole(role)"
            >
              Edit Role
            </button>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div v-if="!roleStore.roles.length" class="col-span-full text-center py-12">
        <ShieldCheckIcon class="h-16 w-16 mx-auto text-gray-400 mb-4" />
        <h2 class="text-2xl font-semibold text-gray-700 mb-2">No custom roles yet</h2>
        <p class="text-gray-500 mb-4">Create custom roles to manage user permissions</p>
        <button @click="createRole" class="btn btn-primary">
          Add Custom Role
        </button>
      </div>
    </div>

    <!-- Role Form Drawer -->
    <BaseDrawer
      v-model="showDrawer"
      :title="isEditing ? 'Edit Role' : 'Add Role'"
    >
      <RoleForm
        v-if="selectedRole"
        :role="selectedRole"
        :permissions="roleStore.permissions"
        @save="handleSave"
        @cancel="closeDrawer"
      />
    </BaseDrawer>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoleStore } from '@/stores/roleStore'
import { PlusCircleIcon, PencilIcon, ShieldCheckIcon, ExclamationCircleIcon } from '@heroicons/vue/24/outline'
import BaseDrawer from '@/components/common/BaseDrawer.vue'
import RoleForm from '@/components/RoleForm.vue'
import { swalHelper } from '@/utils/swalHelper'

const roleStore = useRoleStore()
const showDrawer = ref(false)
const selectedRole = ref(null)
const isEditing = computed(() => !!selectedRole.value?.id)

onMounted(async () => {
  await fetchRoles()
})

async function fetchRoles() {
  await Promise.all([
    roleStore.fetchRoles(),
    roleStore.fetchPermissions()
  ])
}

function createRole() {
  selectedRole.value = {
    name: '',
    permissions: []
  }
  showDrawer.value = true
}

function editRole(role) {
  selectedRole.value = { ...role }
  showDrawer.value = true
}

function closeDrawer() {
  showDrawer.value = false
  selectedRole.value = null
}

async function handleSave(roleData) {
  try {
    if (isEditing.value) {
      await roleStore.updateRole(roleData.id, roleData)
      swalHelper.toast('success', 'Role updated successfully')
    } else {
      await roleStore.createRole(roleData)
      swalHelper.toast('success', 'Role created successfully')
    }
    closeDrawer()
  } catch (error) {
    swalHelper.toast('error', `Failed to ${isEditing.value ? 'update' : 'create'} role`)
  }
}
</script>
