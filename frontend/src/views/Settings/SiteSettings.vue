<template>
  <div class="container mx-auto max-w-4xl">
    <div class="card bg-base-100 shadow">
      <div class="card-body">
        <h2 class="card-title mb-6">Site Settings</h2>

        <form @submit.prevent="handleSubmit">
          <!-- Terms and Conditions -->
          <div class="form-control mb-6">
            <label class="label">
              <span class="label-text">Terms and Conditions</span>
            </label>
            <textarea
              v-model="form.terms_and_conditions"
              class="textarea textarea-bordered h-64"
              :class="{ 'textarea-error': errors.terms_and_conditions }"
              placeholder="Enter terms and conditions"
            ></textarea>
            <label class="label" v-if="errors.terms_and_conditions">
              <span class="label-text-alt text-error">{{ errors.terms_and_conditions }}</span>
            </label>
          </div>

          <div class="flex justify-end gap-2">
            <button type="button" class="btn btn-ghost" @click="resetForm">Reset</button>
            <button type="submit" class="btn btn-primary" :disabled="settingsStore.isLoading">
              <span v-if="settingsStore.isLoading" class="loading loading-spinner"></span>
              Save Changes
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useSettingsStore } from '@/stores/settingsStore'
import { swalHelper } from '@/utils/swalHelper'

const settingsStore = useSettingsStore()
const errors = ref({})

const form = ref({
  terms_and_conditions: '',
})

const handleSubmit = async () => {
  try {
    errors.value = {}
    await settingsStore.updateSettings(form.value)
    swalHelper.toast('success', 'Settings updated successfully')
  } catch (error) {
    if (error.response?.data?.errors) {
      errors.value = error.response.data.errors
    }
    swalHelper.toast('error', 'Failed to update settings')
  }
}

const resetForm = () => {
  form.value = { ...settingsStore.settings }
}

onMounted(async () => {
  try {
    await settingsStore.fetchSettings()
    form.value = { ...settingsStore.settings }
  } catch (error) {
    swalHelper.toast('error', 'Failed to load settings')
  }
})
</script>
