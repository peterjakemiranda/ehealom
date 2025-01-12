<template>
  <form @submit.prevent="onSubmit" class="space-y-4">
    <div class="form-control">
      <label class="label">Name</label>
      <input
        v-model="formData.name"
        type="text"
        class="input input-bordered"
        required
      />
    </div>

    <div class="form-control">
      <label class="label">Email</label>
      <input
        v-model="formData.email"
        type="email"
        class="input input-bordered"
        required
      />
    </div>

    <div class="form-control">
      <label class="label">
        <span class="label-text">Password</span>
        <span v-if="isEditing" class="label-text-alt text-gray-500">
          Leave blank to keep current password
        </span>
      </label>
      <input
        v-model="formData.password"
        type="password"
        class="input input-bordered"
        :required="!isEditing"
        :placeholder="isEditing ? 'Enter new password (optional)' : 'Enter password'"
      />
    </div>

    <div class="form-control">
      <label class="label">Role</label>
      <select 
        v-model="formData.roles[0]"
        class="select select-bordered w-full"
        required
      >
        <option value="" disabled selected>Select a role</option>
        <option 
          v-for="role in roles" 
          :key="role.name"
          :value="role.name"
        >
          {{ role.name }}
        </option>
      </select>
    </div>

    <div class="form-control">
      <label class="label cursor-pointer">
        <span class="label-text">Active Status</span>
        <input
          type="checkbox"
          v-model="formData.status"
          class="toggle"
        />
      </label>
    </div>

    <div class="mt-6 flex gap-4">
      <button type="button" class="btn btn-ghost w-1/2" @click="$emit('cancel')">
        Cancel
      </button>
      <button type="submit" class="btn btn-primary w-1/2" :disabled="isLoading">
        {{ isEditing ? 'Update' : 'Create' }} User
      </button>
    </div>
  </form>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { v4 as uuidv4 } from 'uuid'

const props = defineProps({
  user: {
    type: Object,
    required: true
  },
  roles: {
    type: Array,
    required: true
  }
})

const emit = defineEmits(['save', 'cancel'])
const isLoading = ref(false)
const isEditing = computed(() => !!props.user.id)

const formData = ref({
  id: null,
  uuid: '',
  name: '',
  email: '',
  password: '',
  roles: [''], // Initialize with empty string for single role
  status: true,
  sync_status: 'pending',
  created_at: null,
  updated_at: null
})

// Watch for user changes and update form
watch(() => props.user, (newUser) => {
  formData.value = {
    ...newUser,
    uuid: newUser.uuid || uuidv4(),
    password: '', // Always reset password
    // Handle both object and string array formats
    roles: newUser.roles?.length 
      ? Array.isArray(newUser.roles[0]) 
        ? newUser.roles 
        : [newUser.roles[0]?.name || newUser.roles[0] || '']
      : [''],
    sync_status: newUser.id ? 'synced' : 'pending',
    created_at: newUser.created_at || new Date().toISOString(),
    updated_at: new Date().toISOString()
  }
}, { immediate: true })

async function onSubmit() {
  try {
    isLoading.value = true
    const userData = { ...formData.value }
    
    // Only include password if it's set
    if (!userData.password) {
      delete userData.password
    }

    // Ensure roles is a string array
    userData.roles = userData.roles.filter(Boolean)
    
    await emit('save', userData)
  } finally {
    isLoading.value = false
  }
}
</script>
