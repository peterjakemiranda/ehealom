<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8">
      <div>
        <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900">Create your account</h2>
        <p class="mt-2 text-center text-sm text-gray-600">
          Or
          <router-link
            :to="{ name: 'login' }"
            class="font-medium text-yellow-600 hover:text-yellow-500"
          >
            sign in if you already have an account
          </router-link>
        </p>
      </div>
      <RegisterForm @registration-success="onRegistrationSuccess" />
    </div>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'
import RegisterForm from '@/components/RegisterForm.vue'

const router = useRouter()

const onRegistrationSuccess = () => {
  // You can add a success message here if you want
  router.push({ name: 'Appointments' })
}
</script>
