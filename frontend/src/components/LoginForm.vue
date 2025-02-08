<template>
  <form @submit.prevent="handleSubmit" class="space-y-6">
    <div v-if="error" class="alert alert-error text-sm">
      {{ error }}
    </div>

    <div>
      <label for="email" class="block text-sm font-medium text-base-content">
        Email address
      </label>
      <div class="mt-1">
        <input
          id="email"
          type="email"
          required
          v-model="email"
          :disabled="isLoading"
          class="input input-bordered w-full"
          placeholder="Enter your email"
        />
      </div>
    </div>

    <div>
      <label for="password" class="block text-sm font-medium text-base-content">
        Password
      </label>
      <div class="mt-1">
        <input
          id="password"
          type="password"
          required
          v-model="password"
          :disabled="isLoading"
          class="input input-bordered w-full"
          placeholder="Enter your password"
        />
      </div>
    </div>

    <div>
      <button 
        type="submit" 
        class="btn btn-primary w-full"
        :disabled="isLoading"
      >
        <span v-if="isLoading">
          <span class="loading loading-spinner"></span>
          Signing in...
        </span>
        <span v-else>Sign in</span>
      </button>
    </div>
  </form>
</template>

<script setup>
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'
import { useSettingsStore } from '@/stores/settingsStore'

const auth = useAuthStore()
const router = useRouter()
const settingsStore = useSettingsStore()

const email = ref('')
const password = ref('')
const error = ref('')
const isLoading = ref(false)

const handleSubmit = async () => {
  error.value = ''
  isLoading.value = true
  
  try {
    const success = await auth.login(email.value, password.value)
    if (success) {
      // No need to fetch settings anymore
      await router.push('/appointments')
    }
  } catch (err) {
    error.value = err.response?.data?.message || 'Failed to sign in'
  } finally {
    isLoading.value = false
  }
}
</script>
