<template>
  <dialog class="modal modal-bottom sm:modal-middle" :open="true">
    <div class="modal-box max-w-md">
      <h3 class="font-bold text-lg mb-6">
        {{ company ? 'Edit Company' : 'Create New Company' }}
      </h3>
      
      <form @submit.prevent="handleSubmit" class="space-y-6">
        <div class="form-control">
          <label class="label">Company Name</label>
          <input
            v-model="formData.name"
            type="text"
            class="input input-bordered w-full"
            required
            placeholder="Enter company name"
          />
        </div>

        <div class="form-control">
          <label class="label">Logo</label>
          <div class="flex items-start space-x-4">
            <div class="flex-shrink-0">
              <div v-if="formData.logo" class="relative w-20 h-20 rounded-lg overflow-hidden">
                <img :src="formData.logo" class="w-full h-full object-cover" />
                <button 
                  type="button"
                  @click="formData.logo = ''"
                  class="absolute top-1 right-1 bg-red-500 text-white rounded-full p-1 hover:bg-red-600"
                >
                  <svg class="w-4 h-4" viewBox="0 0 20 20" fill="currentColor">
                    <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
                  </svg>
                </button>
              </div>
              <div 
                v-else 
                class="w-20 h-20 rounded-lg border-2 border-dashed border-gray-300 flex items-center justify-center"
              >
                <svg class="w-8 h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
              </div>
            </div>
            <div class="flex-grow">
              <input
                type="file"
                accept="image/*"
                @change="handleLogoUpload"
                class="file-input file-input-bordered w-full"
              />
              <p class="text-xs text-gray-500 mt-1">
                Upload a company logo (optional)
              </p>
            </div>
          </div>
        </div>

        <div class="modal-action pt-4">
          <button type="button" class="btn btn-ghost" @click="$emit('close')">
            Cancel
          </button>
          <button type="submit" class="btn btn-primary" :disabled="isLoading">
            {{ isLoading ? 'Saving...' : 'Save Company' }}
          </button>
        </div>
      </form>
    </div>
    <form method="dialog" class="modal-backdrop">
      <button @click="$emit('close')">close</button>
    </form>
  </dialog>
</template>

<script setup>
import { ref } from 'vue'
import { useCompanyStore } from '@/stores/companyStore'

const props = defineProps({
  company: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['close', 'saved'])
const companyStore = useCompanyStore()
const isLoading = ref(false)

const formData = ref({
  name: props.company?.name || '',
  logo: props.company?.logo || ''
})

const handleLogoUpload = async (event) => {
  const file = event.target.files[0]
  if (file) {
    const reader = new FileReader()
    reader.onload = (e) => {
      formData.value.logo = e.target.result
    }
    reader.readAsDataURL(file)
  }
}

const handleSubmit = async () => {
  try {
    isLoading.value = true
    const result = await companyStore.createCompany(formData.value)
    emit('saved', result)
  } catch (error) {
    console.error('Error saving company:', error)
  } finally {
    isLoading.value = false
  }
}
</script>
