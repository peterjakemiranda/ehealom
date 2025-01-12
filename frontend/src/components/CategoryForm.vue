<template>
  <div class="space-y-4">
    <form @submit.prevent="onSubmit" class="card bg-white p-2">
      <div class="form-control mb-2">
        <label class="label">
          <span class="label-text text-gray-700">Category Name</span>
        </label>
        <input v-model="formData.name" type="text" class="input input-bordered bg-gray-50" required />
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

      <div class="grid grid-cols-2 gap-4">
        <div class="form-control">
          <label class="label">
            <span class="label-text text-gray-700">Interest Rate (%)</span>
          </label>
          <input
            v-model.number="formData.interest_rate"
            type="number"
            step="0.01"
            min="0"
            max="100"
            class="input input-bordered bg-gray-50"
            required
          />
        </div>

        <div class="form-control">
          <label class="label">
            <span class="label-text text-gray-700">Penalty Rate (%)</span>
          </label>
          <input
            v-model.number="formData.penalty_rate"
            type="number"
            step="0.01"
            min="0"
            max="100"
            class="input input-bordered bg-gray-50"
            required
          />
        </div>
      </div>

      <div class="grid grid-cols-2 gap-4 mt-2">
        <div class="form-control">
          <label class="label">
            <span class="label-text text-gray-700">Loan Period</span>
          </label>
          <div class="flex gap-2">
            <input
              v-model.number="formData.loan_period"
              type="number"
              min="1"
              class="input input-bordered bg-gray-50 w-24"
              required
            />
            <select v-model="formData.loan_period_type" class="select select-bordered bg-gray-50 flex-1">
              <option value="day">Days</option>
              <option value="month">Months</option>
              <option value="year">Years</option>
            </select>
          </div>
        </div>
        <div class="form-control">
        <label class="label">
          <span class="label-text text-gray-700">Grace Period (days)</span>
        </label>
        <input
          v-model.number="formData.loan_period_expiry"
          type="number"
          min="0"
          class="input input-bordered bg-gray-50"
          required
        />
        <label class="label">
          <span class="label-text-alt text-gray-500">
            Additional days after maturity before the loan expires
          </span>
        </label>
      </div>

      </div>

      
    <div class="form-control">
      <label class="label cursor-pointer">
        <span class="label-text text-gray-700">Is Renewable?</span>
        <div class="flex items-center gap-2">
        <input
          type="checkbox"
          class="toggle toggle-primary"
          :checked="formData.is_renewable"
          @change="formData.is_renewable = $event.target.checked"
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
          {{ formData.id ? 'Update' : 'Create' }} Category
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { v4 as uuidv4 } from 'uuid'

const props = defineProps({
  category: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['save', 'cancel'])
const isLoading = ref(false)
const formData = ref({
  uuid: props.category.uuid || crypto.randomUUID(),
  localId: props.category.localId || Date.now(),
  name: props.category.name || '',
  description: props.category.description || '',
  interest_rate: props.category.interest_rate || 0,
  penalty_rate: props.category.penalty_rate || 0,
  loan_period: props.category.loan_period || 1,
  loan_period_type: props.category.loan_period_type || 'month',
  loan_period_expiry: props.category.loan_period_expiry || 0,
  is_renewable: Boolean(props.category.is_renewable),
  sync_status: 'pending',
  created_at: props.category.created_at || new Date().toISOString(),
  updated_at: new Date().toISOString()
})

// Update watch handler to preserve uuid
watch(() => props.category, (newVal) => {
  formData.value = {
    ...formData.value,
    ...newVal,
    uuid: formData.value.uuid, // Keep existing uuid
    localId: formData.value.localId, // Keep existing localId
    is_renewable: Boolean(newVal.is_renewable),
    sync_status: 'pending',
    updated_at: new Date().toISOString()
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
