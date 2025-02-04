<template>
  <div class="container mx-auto max-w-4xl">
    <div class="card bg-base-100 shadow">
      <div class="card-body">
        <h2 class="card-title mb-6">Site Settings</h2>

        <form @submit.prevent="handleSubmit">
          <!-- Site Name -->
          <div class="form-control mb-4">
            <label class="label">
              <span class="label-text">Site Name</span>
            </label>
            <input
              v-model="form.site_name"
              type="text"
              class="input input-bordered"
              :class="{ 'input-error': errors.site_name }"
              placeholder="Enter site name"
            />
            <label class="label" v-if="errors.site_name">
              <span class="label-text-alt text-error">{{ errors.site_name }}</span>
            </label>
          </div>

          <!-- Logo Upload -->
          <div class="form-control mb-4">
            <label class="label">
              <span class="label-text">Site Logo</span>
            </label>
            
            <!-- Current Logo Preview -->
            <div v-if="form.site_logo || imagePreview" class="mb-2">
              <img 
                :src="imagePreview || form.site_logo" 
                alt="Logo Preview" 
                class="h-16 object-contain mb-2"
              />
              <button 
                type="button" 
                class="btn btn-sm btn-primary font-thin"
                @click="removeLogo"
              >
                Remove Logo
              </button>
            </div>

            <!-- File Input -->
            <input
              ref="fileInput"
              type="file"
              class="file-input file-input-bordered w-full"
              :class="{ 'input-error': errors.site_logo }"
              accept="image/*"
              @change="handleFileChange"
            />
            <label class="label" v-if="errors.site_logo">
              <span class="label-text-alt text-error">{{ errors.site_logo }}</span>
            </label>
          </div>

          <!-- Business Name -->
          <div class="form-control mb-4">
            <label class="label">
              <span class="label-text">Business Name</span>
            </label>
            <input
              v-model="form.business_name"
              type="text"
              class="input input-bordered"
              :class="{ 'input-error': errors.business_name }"
              placeholder="Enter business name"
            />
            <label class="label" v-if="errors.business_name">
              <span class="label-text-alt text-error">{{ errors.business_name }}</span>
            </label>
          </div>

          <!-- Business Address -->
          <div class="form-control mb-6">
            <label class="label">
              <span class="label-text">Business Address</span>
            </label>
            <textarea
              v-model="form.business_address"
              class="textarea textarea-bordered h-24"
              :class="{ 'textarea-error': errors.business_address }"
              placeholder="Enter business address"
            ></textarea>
            <label class="label" v-if="errors.business_address">
              <span class="label-text-alt text-error">{{ errors.business_address }}</span>
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
const fileInput = ref(null)
const imagePreview = ref(null)

const form = ref({
  site_name: '',
  site_logo: null,
  business_name: '',
  business_address: '',
})

const handleFileChange = (event) => {
  const file = event.target.files[0]
  if (file) {
    // Create preview
    imagePreview.value = URL.createObjectURL(file)
    form.value.site_logo = file
  }
}

const removeLogo = () => {
  form.value.site_logo = null
  imagePreview.value = null
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

const handleSubmit = async () => {
  try {
    errors.value = {}
    
    const dataToSend = {
      site_name: form.value.site_name,
      business_name: form.value.business_name,
      business_address: form.value.business_address,
      site_logo: form.value.site_logo instanceof File ? null : form.value.site_logo
    }

    // Only append logo if it's a File object
    if (form.value.site_logo instanceof File) {
      const formData = new FormData()
      Object.entries(dataToSend).forEach(([key, value]) => {
        if (value !== null) formData.append(key, value)
      })
      formData.append('site_logo', form.value.site_logo)
      await settingsStore.updateSettings(formData)
    } else {
      await settingsStore.updateSettings(dataToSend)
    }

    swalHelper.toast('success', 'Settings updated successfully')
    imagePreview.value = null
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
