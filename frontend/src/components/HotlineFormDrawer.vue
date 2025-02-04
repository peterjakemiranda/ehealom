<template>
  <div class="space-y-4">
    <form @submit.prevent="onSubmit" class="card bg-white p-2">
      <div class="form-control mb-2">
        <label class="label">
          <span class="label-text text-gray-700">Hotline Name</span>
        </label>
        <input 
          v-model="formData.name" 
          type="text" 
          class="input input-bordered bg-gray-50" 
          required 
        />
      </div>

      <div class="form-control mb-2">
        <label class="label">
          <span class="label-text text-gray-700">Department</span>
        </label>
        <input 
          v-model="formData.department" 
          type="text" 
          class="input input-bordered bg-gray-50" 
          required 
        />
      </div>

      <div class="form-control mb-2">
        <label class="label">
          <span class="label-text text-gray-700">Phone Number</span>
        </label>
        <input 
          v-model="formData.number" 
          type="text" 
          class="input input-bordered bg-gray-50" 
          required 
        />
      </div>

      <div class="form-control mb-2">
        <label class="label">
          <span class="label-text text-gray-700">Description</span>
        </label>
        <textarea
          v-model="formData.description"
          class="textarea textarea-bordered bg-gray-50"
          rows="2"
        ></textarea>
      </div>

      <div class="form-control mb-2">
        <label class="label">
          <span class="label-text text-gray-700">Priority Order</span>
        </label>
        <input
          v-model.number="formData.priority_order"
          type="number"
          min="0"
          class="input input-bordered bg-gray-50"
          required
        />
      </div>

      <div class="form-control">
        <label class="label cursor-pointer">
          <span class="label-text text-gray-700">Is Active?</span>
          <div class="flex items-center gap-2">
            <input
              type="checkbox"
              class="toggle toggle-primary"
              :checked="formData.is_active"
              @change="formData.is_active = $event.target.checked"
            />
            <span class="text-xs text-gray-500">Yes</span>
          </div>
        </label>
      </div>

      <div class="mt-6 flex gap-4">
        <button type="button" class="btn btn-ghost w-1/2" @click="$emit('cancel')">
          Cancel
        </button>
        <button type="submit" class="btn btn-primary w-1/2" :disabled="isLoading">
          {{ formData.id ? 'Update' : 'Create' }} Hotline
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'

const props = defineProps({
  hotline: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['save', 'cancel'])
const isLoading = ref(false)
const formData = ref({
  id: props.hotline.id || null,
  name: props.hotline.name || '',
  department: props.hotline.department || '',
  number: props.hotline.number || '',
  description: props.hotline.description || '',
  priority_order: props.hotline.priority_order || 0,
  is_active: Boolean(props.hotline.is_active)
})

watch(() => props.hotline, (newVal) => {
  formData.value = {
    ...formData.value,
    id: newVal.id,
    name: newVal.name,
    department: newVal.department,
    number: newVal.number,
    description: newVal.description,
    priority_order: newVal.priority_order,
    is_active: Boolean(newVal.is_active)
  }
}, { deep: true })

async function onSubmit() {
  try {
    isLoading.value = true
    await emit('save', { ...formData.value })
  } finally {
    isLoading.value = false
  }
}
</script> 