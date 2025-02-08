<template>
  <div class="min-h-screen relative flex flex-col justify-center py-12 sm:px-6 lg:px-8">
    <!-- Background Image with Overlay -->
    <div 
      class="absolute inset-0 bg-cover bg-center bg-no-repeat"
      :style="{ backgroundImage: `url(${bgImage})` }"
    >
      <div class="absolute inset-0 backdrop-blur-sm"></div>
    </div>

    <!-- Content -->
    <div class="relative z-10">
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <!-- Logo -->
        <img 
          src="@/assets/logo.png"
          class="mx-auto h-16 w-auto"
          alt="E-Healom"
        />
      </div>

      <div class="mt-5 sm:mx-auto sm:w-full sm:max-w-md">
        <div class="bg-base-100/90 backdrop-blur-md py-8 px-4 shadow-2xl rounded-lg sm:px-10 border border-base-content/10">
          <p class="mb-2 text-center text-sm text-base-content/70">
          Sign in to your account to continue
        </p>
          <LoginForm />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import LoginForm from '@/components/LoginForm.vue'
import bg from '@/assets/bg.jpg'

const bgImage = computed(() => {
  return bg
})
</script>

<style scoped>
/* Optional: Add animation for content */
.relative.z-10 {
  animation: fadeIn 0.5s ease-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
