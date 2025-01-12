<template>
  <form @submit.prevent="onSubmit" class="space-y-4">
    <div class="form-control">
      <label class="label">Role Name</label>
      <input
        v-model="formData.name"
        type="text"
        class="input input-bordered"
        required
        placeholder="Enter role name"
      />
    </div>

    <div class="form-control">
      <label class="label">
        <span class="label-text">Permissions</span>
        <span class="label-text-alt">{{ selectedPermissions.length }} selected</span>
      </label>
      
      <!-- Group permissions by category -->
      <div class="space-y-4">
        <div v-for="(group, category) in groupedPermissions" :key="category" class="card bg-base-100 border">
          <div class="card-body p-4">
            <h3 class="font-medium text-sm text-gray-600 mb-2 capitalize">{{ category }}</h3>
            <div class="grid grid-cols-2 gap-2">
              <label 
                v-for="permission in group" 
                :key="permission.name" 
                class="flex items-center gap-2 hover:bg-base-200 p-1 rounded cursor-pointer"
              >
                <input
                  type="checkbox"
                  :value="permission.name"
                  v-model="selectedPermissions"
                  class="checkbox checkbox-sm checkbox-primary"
                />
                <span class="text-sm">{{ permission.name }}</span>
              </label>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="mt-6 flex gap-4">
      <button type="button" class="btn btn-ghost w-1/2" @click="$emit('cancel')">
        Cancel
      </button>
      <button 
        type="submit" 
        class="btn btn-primary w-1/2" 
        :disabled="isLoading"
      >
        {{ isEditing ? 'Update' : 'Create' }} Role
      </button>
    </div>
  </form>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { v4 as uuidv4 } from 'uuid'

const props = defineProps({
  role: {
    type: Object,
    required: true
  },
  permissions: {
    type: Array,
    required: true
  }
})

const emit = defineEmits(['save', 'cancel'])
const isLoading = ref(false)
const isEditing = computed(() => !!props.role.id)

const selectedPermissions = ref([])

// Initialize form data and selected permissions
watch(() => props.role, (newRole) => {
  selectedPermissions.value = newRole.permissions?.map(item => item) || []
}, { immediate: true })

const formData = computed(() => ({
  id: props.role.id,
  uuid: props.role.uuid || uuidv4(),
  name: props.role.name || '',
  permissions: selectedPermissions.value,
  sync_status: props.role.id ? 'synced' : 'pending',
  created_at: props.role.created_at || new Date().toISOString(),
  updated_at: new Date().toISOString()
}))

// Group permissions by their prefix (before first space)
const groupedPermissions = computed(() => {
  return props.permissions.reduce((groups, permission) => {
    const category = permission.name.split(' ')[0]
    if (!groups[category]) {
      groups[category] = []
    }
    groups[category].push(permission)
    return groups
  }, {})
})

async function onSubmit() {
  try {
    isLoading.value = true
    await emit('save', formData.value)
  } finally {
    isLoading.value = false
  }
}
</script>
