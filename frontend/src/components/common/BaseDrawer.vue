<template>
  <div>
    <div 
      class="drawer-overlay fixed inset-0 bg-black bg-opacity-50 transition-opacity z-40"
      :class="{ 'opacity-0 pointer-events-none': !modelValue, 'opacity-100': modelValue }"
      @click="$emit('update:modelValue', false)"
    ></div>
    <div 
      class="drawer-content fixed inset-y-0 right-0 top-0 w-[32rem] bg-base-100 shadow-xl z-50 transition-transform duration-300 transform"
      :class="{ 'translate-x-full': !modelValue, 'translate-x-0': modelValue }"
    >
      <div class="p-8 h-full overflow-y-auto">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-bold">{{ title }}</h3>
          <button class="btn btn-ghost btn-sm" @click="$emit('update:modelValue', false)">
            <XMarkIcon class="h-6 w-6" />
          </button>
        </div>
        
        <slot></slot>
      </div>
    </div>
  </div>
</template>

<script setup>
import { XMarkIcon } from '@heroicons/vue/24/outline'

defineProps({
  modelValue: {
    type: Boolean,
    required: true
  },
  title: {
    type: String,
    required: true
  }
})

defineEmits(['update:modelValue'])
</script>

<style scoped>
.drawer-overlay {
  transition: opacity 0.3s ease-in-out;
  margin: 0 !important;
}
.drawer-content {
  transition: transform 0.3s ease-in-out;
  max-width: 100%;
  height: 100%;
  margin: 0 !important;
}
</style>
