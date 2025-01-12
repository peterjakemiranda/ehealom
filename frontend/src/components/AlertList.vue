<template>
  <ul>
    <li v-for="alert in alerts" :key="alert.id" class="flex items-center justify-between py-2">
      <p>{{ alert.message }}</p>
      <button class="text-blue-500 hover:text-primary">
        <ArrowRightIcon class="w-5 h-5" />
      </button>
    </li>
  </ul>
</template>

<script setup>
import { ArrowRightIcon } from '@heroicons/vue/24/solid'

defineProps({
  alerts: Array
})
</script>
