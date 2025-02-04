<template>
  <div class="space-y-4">
    <form @submit.prevent="onSubmit" class="card bg-white p-4">
      <div class="form-control mb-4">
        <label class="label">
          <span class="label-text text-gray-700">Title</span>
        </label>
        <input 
          v-model="formData.title" 
          type="text" 
          class="input input-bordered bg-gray-50" 
          required 
        />
      </div>

      <div class="form-control mb-4">
        <label class="label">
          <span class="label-text text-gray-700">Description</span>
        </label>
        <textarea
          v-model="formData.description"
          class="textarea textarea-bordered bg-gray-50"
          rows="3"
        ></textarea>
      </div>

      <!-- Tag Input -->
      <div class="form-control mb-4">
        <label class="label">
          <span class="label-text text-gray-700">Tags</span>
        </label>
        <div class="relative">
          <div class="flex flex-wrap gap-2 p-2 border rounded-lg bg-gray-50 min-h-[3rem]">
            <!-- Selected Tags -->
            <div v-for="tag in selectedTags" :key="tag"
                 class="badge badge-primary gap-1">
              {{ tag }}
              <button type="button" @click="removeTag(tag)" class="btn btn-ghost btn-xs px-1">
                ×
              </button>
            </div>
            
            <!-- Input -->
            <input
              v-model="tagInput"
              @keydown.enter.prevent="addTag"
              @keydown.backspace="handleBackspace"
              @focus="showSuggestions = true"
              type="text"
              class="input input-ghost input-sm flex-1 min-w-[100px]"
              placeholder="Type to add tags..."
            />
          </div>

          <!-- Suggestions Dropdown -->
          <div v-if="showSuggestions && filteredSuggestions.length > 0"
               class="suggestions-dropdown absolute z-10 w-full mt-1 bg-white border rounded-lg shadow-lg">
            <div v-for="suggestion in filteredSuggestions" 
                 :key="suggestion"
                 @click="selectSuggestion(suggestion)"
                 class="px-4 py-2 hover:bg-gray-100 cursor-pointer">
              {{ suggestion }}
            </div>
          </div>
        </div>
      </div>

      <div class="form-control mb-4">
        <label class="label">
          <span class="label-text text-gray-700">Category Image</span>
        </label>
        <input
          type="file"
          @change="handleFileChange"
          class="file-input file-input-bordered bg-gray-50 w-full"
          accept="image/*"
        />
        <label class="label">
          <span class="label-text-alt text-gray-500">
            Max file size: 2MB. Supported formats: JPG, PNG, GIF
          </span>
        </label>
        
        <!-- Preview image -->
        <div v-if="imagePreview" class="mt-2">
          <img :src="imagePreview" alt="Preview" class="w-32 h-32 object-cover rounded-lg" />
        </div>
      </div>

      <div class="mt-6 flex gap-4">
        <button type="button" class="btn btn-ghost w-1/2" @click="$emit('cancel')">
          Cancel
        </button>
        <button type="submit" class="btn btn-primary w-1/2" :disabled="isLoading">
          {{ formData.uuid ? 'Update' : 'Create' }} Category
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, watch, onUnmounted, computed, onMounted } from 'vue'

const props = defineProps({
  category: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['save', 'cancel'])
const isLoading = ref(false)
const imagePreview = ref(null)
const tagInput = ref('')
const selectedTags = ref([])
const showSuggestions = ref(false)

// Example tag suggestions - you can replace with your own list
const tagSuggestions = [
  'Anxiety', 'Depression', 'Stress', 'Self-Care', 'Mindfulness',
  'Relationships', 'Academic', 'Career', 'Personal Growth', 'Wellness'
]

const filteredSuggestions = computed(() => {
  if (!tagInput.value) return []
  return tagSuggestions.filter(tag => 
    tag.toLowerCase().includes(tagInput.value.toLowerCase()) &&
    !selectedTags.value.includes(tag)
  )
})

const formData = ref({
  uuid: props.category.uuid || crypto.randomUUID(),
  title: props.category.title || '',
  description: props.category.description || '',
  image: null
})

function addTag() {
  const tag = tagInput.value.trim()
  if (tag && !selectedTags.value.includes(tag)) {
    selectedTags.value.push(tag)
  }
  tagInput.value = ''
}

function removeTag(tag) {
  selectedTags.value = selectedTags.value.filter(t => t !== tag)
}

function selectSuggestion(tag) {
  if (!selectedTags.value.includes(tag)) {
    selectedTags.value.push(tag)
  }
  tagInput.value = ''
  showSuggestions.value = false
}

function handleBackspace(event) {
  if (!tagInput.value && selectedTags.value.length > 0) {
    event.preventDefault()
    selectedTags.value.pop()
  }
}

// Handle click outside manually
function handleClickOutside(event) {
  const dropdown = document.querySelector('.suggestions-dropdown')
  if (dropdown && !dropdown.contains(event.target)) {
    showSuggestions.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
  if (imagePreview.value && !imagePreview.value.includes('http')) {
    URL.revokeObjectURL(imagePreview.value)
  }
})

watch(() => props.category, (newVal) => {
  formData.value = {
    ...formData.value,
    uuid: newVal.uuid,
    title: newVal.title,
    description: newVal.description
  }
  // Set image preview if category has an image
  if (newVal.image_path) {
    imagePreview.value = newVal.image_path
  }
}, { deep: true, immediate: true })  // Added immediate: true to run on mount

function handleFileChange(event) {
  const file = event.target.files[0]
  if (file) {
    if (!file.type.startsWith('image/')) {
      alert('Please select an image file')
      event.target.value = ''
      return
    }
    formData.value.image = file
    // Create preview URL and revoke old one if exists
    if (imagePreview.value && !imagePreview.value.includes('http')) {
      URL.revokeObjectURL(imagePreview.value)
    }
    imagePreview.value = URL.createObjectURL(file)
  }
}

async function onSubmit() {
  try {
    isLoading.value = true
    await emit('save', { ...formData.value })
  } finally {
    isLoading.value = false
  }
}
</script>

<style scoped>
.input-ghost {
  @apply bg-transparent border-none focus:outline-none focus:ring-0;
}

.input-ghost::placeholder {
  @apply text-gray-400;
}
</style>
