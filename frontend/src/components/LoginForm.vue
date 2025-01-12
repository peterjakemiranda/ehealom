<template>
  <form @submit.prevent="handleSubmit" class="space-y-4">
    <div>
      <label for="email" class="block mb-2 text-sm font-medium text-gray-900">Email</label>
      <input
        type="email"
        id="email"
        v-model="email"
        required
        class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5"
      />
    </div>
    <div>
      <label for="password" class="block mb-2 text-sm font-medium text-gray-900">Password</label>
      <input
        type="password"
        id="password"
        v-model="password"
        required
        class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5"
      />
    </div>
    <button type="submit" class="btn btn-primary w-full">Login</button>
  </form>
</template>

<script setup>
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'

const auth = useAuthStore()
const router = useRouter()

const email = ref('')
const password = ref('')

const handleSubmit = async () => {
  const success = await auth.login(email.value, password.value)
  if (success) {
    router.push('/')
  } else {
    // Handle login error (e.g., show error message)
  }
}
</script>
