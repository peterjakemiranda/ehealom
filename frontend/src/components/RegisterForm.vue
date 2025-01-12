<template>
  <form @submit.prevent="handleSubmit" class="space-y-4">
    <div>
      <label for="name" class="block mb-2 text-sm font-medium text-gray-900">Name</label>
      <input
        type="text"
        id="name"
        v-model="name"
        required
        class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-yellow-500 focus:border-yellow-500 block w-full p-2.5"
      />
    </div>
    <div>
      <label for="email" class="block mb-2 text-sm font-medium text-gray-900">Email</label>
      <input
        type="email"
        id="email"
        v-model="email"
        required
        class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-yellow-500 focus:border-yellow-500 block w-full p-2.5"
      />
    </div>
    <div>
      <label for="password" class="block mb-2 text-sm font-medium text-gray-900">Password</label>
      <input
        type="password"
        id="password"
        v-model="password"
        required
        class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-yellow-500 focus:border-yellow-500 block w-full p-2.5"
      />
    </div>
    <div>
      <label for="password_confirmation" class="block mb-2 text-sm font-medium text-gray-900"
        >Confirm Password</label
      >
      <input
        type="password"
        id="password_confirmation"
        v-model="passwordConfirmation"
        required
        class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-yellow-500 focus:border-yellow-500 block w-full p-2.5"
      />
    </div>
    <div>
      <label for="companyName" class="block mb-2 text-sm font-medium text-gray-900">Company Name (Optional)</label>
      <input
        type="text"
        id="companyName"
        v-model="companyName"
        class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-yellow-500 focus:border-yellow-500 block w-full p-2.5"
      />
    </div>
    <button
      type="submit"
      class="w-full text-white bg-yellow-600 hover:bg-yellow-700 focus:ring-4 focus:outline-none focus:ring-yellow-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center"
    >
      Register
    </button>
  </form>
</template>

<script setup>
import { ref } from 'vue'
import { useAuthStore } from '@/stores/auth'

const emit = defineEmits(['registration-success'])
const auth = useAuthStore()

const name = ref('')
const email = ref('')
const password = ref('')
const passwordConfirmation = ref('')
const companyName = ref('')

const handleSubmit = async () => {
  try {
    const success = await auth.register(
      name.value,
      email.value,
      password.value,
      passwordConfirmation.value,
      companyName.value || name.value // Use name as company name if companyName is empty
    )
    if (success) {
      emit('registration-success')
    } else {
      // Handle registration error (e.g., show error message)
      console.error('Registration failed')
    }
  } catch (error) {
    console.error('An error occurred during registration:', error)
  }
}
</script>
