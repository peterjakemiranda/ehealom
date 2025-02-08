<template>
  <div class="p-4 max-w-2xl mx-auto">
    <h2 class="text-xl font-bold mb-6">My Profile</h2>
    
    <div v-if="error" class="alert alert-error mb-4">
      {{ error }}
    </div>

    <form @submit.prevent="handleSubmit" class="space-y-6 bg-white shadow-sm rounded-lg p-6">
      <!-- Name Field -->
      <div>
        <label for="name" class="block text-sm font-medium text-gray-700">
          Full Name
        </label>
        <div class="mt-1">
          <input
            id="name"
            type="text"
            v-model="form.name"
            required
            :disabled="isLoading"
            class="input input-bordered w-full"
          />
        </div>
      </div>

      <!-- Email Field (Read Only) -->
      <div>
        <label for="email" class="block text-sm font-medium text-gray-700">
          Email
        </label>
        <div class="mt-1">
          <input
            id="email"
            type="email"
            v-model="form.email"
            disabled
            class="input input-bordered w-full bg-gray-50"
          />
        </div>
      </div>

      <!-- Current Password Field -->
      <div>
        <label for="current_password" class="block text-sm font-medium text-gray-700">
          Current Password
        </label>
        <div class="mt-1">
          <input
            id="current_password"
            type="password"
            v-model="form.current_password"
            :disabled="isLoading"
            class="input input-bordered w-full"
            placeholder="Enter only if changing password"
          />
        </div>
      </div>

      <!-- New Password Field -->
      <div>
        <label for="new_password" class="block text-sm font-medium text-gray-700">
          New Password
        </label>
        <div class="mt-1">
          <input
            id="new_password"
            type="password"
            v-model="form.new_password"
            :disabled="isLoading"
            class="input input-bordered w-full"
            placeholder="Enter only if changing password"
          />
        </div>
      </div>

      <!-- Submit Button -->
      <div class="flex justify-end">
        <button 
          type="submit" 
          class="btn btn-primary"
          :disabled="isLoading || !isFormValid"
        >
          <span v-if="isLoading">
            <span class="loading loading-spinner"></span>
            Saving...
          </span>
          <span v-else>Save Changes</span>
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { swalHelper } from '@/utils/swalHelper'

const auth = useAuthStore()
const isLoading = ref(false)
const error = ref('')

const form = ref({
  name: auth.user?.user?.name || '',
  email: auth.user?.user?.email || '',
  current_password: '',
  new_password: ''
})

const isFormValid = computed(() => {
  if (!form.value.name) return false
  
  // If either password field is filled, both must be filled
  if (form.value.current_password || form.value.new_password) {
    return form.value.current_password && form.value.new_password
  }
  
  return true
})

const handleSubmit = async () => {
  error.value = ''
  isLoading.value = true
  
  try {
    const payload = {
      name: form.value.name
    }

    // Only include password fields if both are filled
    if (form.value.current_password && form.value.new_password) {
      payload.current_password = form.value.current_password
      payload.new_password = form.value.new_password
    }

    await auth.updateProfile(payload)
    swalHelper.toast('success', 'Profile updated successfully')
    
    // Clear password fields after successful update
    form.value.current_password = ''
    form.value.new_password = ''
  } catch (err) {
    error.value = err.response?.data?.message || 'Failed to update profile'
  } finally {
    isLoading.value = false
  }
}
</script> 