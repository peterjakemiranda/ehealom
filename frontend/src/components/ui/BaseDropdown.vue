<template>
  <div class="relative">
    <slot name="trigger" :toggle="toggle" :isOpen="isOpen"></slot>

    <transition
      enter-active-class="transition duration-100 ease-out"
      enter-from-class="transform scale-95 opacity-0"
      enter-to-class="transform scale-100 opacity-100"
      leave-active-class="transition duration-75 ease-in"
      leave-from-class="transform scale-100 opacity-100"
      leave-to-class="transform scale-95 opacity-0"
    >
      <div
        v-show="isOpen"
        class="absolute z-50 mt-2 rounded-md shadow-lg bg-base-100 ring-1 ring-black ring-opacity-5"
        :class="[position === 'right' ? 'right-0' : 'left-0', width]"
        @click="closeOnClick && toggle(false)"
      >
        <slot :close="() => toggle(false)"></slot>
      </div>
    </transition>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  closeOnClick: {
    type: Boolean,
    default: true
  },
  position: {
    type: String,
    default: 'left'
  },
  width: {
    type: String,
    default: 'w-48'
  }
})

const isOpen = ref(false)

const toggle = (value) => {
  isOpen.value = value ?? !isOpen.value
}

const handleClickOutside = (event) => {
  if (!event.target.closest('.dropdown')) {
    toggle(false)
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})

defineExpose({ toggle, isOpen })
</script>
