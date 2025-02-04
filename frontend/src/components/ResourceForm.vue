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
          <span class="label-text text-gray-700">Content</span>
        </label>
        <textarea
          v-model="formData.content"
          class="textarea textarea-bordered bg-gray-50"
          rows="6"
          required
        ></textarea>
      </div>

      <div class="form-control mb-4">
        <label class="label">
          <span class="label-text text-gray-700">Categories</span>
        </label>
        <div class="flex flex-wrap gap-2 p-2 border rounded-lg bg-gray-50 min-h-[3rem]">
          <div v-for="category in categories" :key="category.id"
               class="badge badge-lg cursor-pointer"
               :class="formData.categories.includes(category.id) ? 
                      'badge-primary text-white' : 
                      'badge-outline hover:badge-primary'"
               @click="toggleCategory(category.id)">
            {{ category.title }}
          </div>
          <div v-if="categories.length === 0" class="text-gray-500 text-sm p-2">
            No categories available
          </div>
        </div>
        <label class="label">
          <span class="label-text-alt text-red-500" v-if="formData.categories.length === 0">
            Please select at least one category
          </span>
        </label>
      </div>

      <div class="form-control mt-4">
        <label class="label">
          <span class="label-text text-gray-700">Resource Image</span>
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
        
        <!-- Preview image if available -->
        <div v-if="imagePreview" class="mt-2">
          <img :src="imagePreview" alt="Preview" class="w-32 h-32 object-cover rounded-lg" />
        </div>
      </div>

      <div class="form-control mt-4">
        <label class="label cursor-pointer">
          <span class="label-text text-gray-700">Publish Immediately?</span>
          <input
            type="checkbox"
            class="toggle toggle-primary"
            v-model="formData.is_published"
          />
        </label>
      </div>

      <div class="mt-6 flex gap-4">
        <button type="button" class="btn btn-ghost w-1/2" @click="$emit('cancel')">
          Cancel
        </button>
        <button type="submit" class="btn btn-primary w-1/2" :disabled="isLoading">
          {{ isEditing ? 'Update' : 'Create' }} Resource
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, computed, watch, onUnmounted, onMounted } from 'vue'
import { useCategoryStore } from '../stores/categoryStore'

const props = defineProps({
  resource: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['save', 'cancel'])
const isLoading = ref(false)

const categoryStore = useCategoryStore()
const categories = ref([])

const formData = ref({
  uuid: props.resource.uuid || crypto.randomUUID(),
  title: props.resource.title || '',
  content: props.resource.content || '',
  categories: [],
  is_published: Boolean(props.resource.is_published),
  image: null,
  created_at: props.resource.created_at || new Date().toISOString(),
  updated_at: new Date().toISOString()
})

const acceptedFileTypes = computed(() => {
  switch (formData.value.type) {
    case 'video':
      return '.mp4,.mov,.avi'
    case 'article':
      return '.pdf,.doc,.docx'
    case 'guide':
      return '.pdf,.doc,.docx'
    default:
      return '*'
  }
})

const imagePreview = ref(null)

// Add computed property for checking edit mode
const isEditing = computed(() => !!props.resource.uuid)

watch(() => props.resource, (newVal) => {
  formData.value = {
    ...formData.value,
    uuid: newVal.uuid,
    title: newVal.title,
    content: newVal.content,
    categories: newVal.categories?.map(c => c.id) || [],
    is_published: Boolean(newVal.is_published)
  }
}, { deep: true })

function handleFileChange(event) {
  const file = event.target.files[0]
  if (file) {
    if (!file.type.startsWith('image/')) {
      alert('Please select an image file')
      event.target.value = ''
      return
    }
    formData.value.image = file
    // Create preview URL
    imagePreview.value = URL.createObjectURL(file)
  }
}

// Clean up preview URL when component is unmounted
onUnmounted(() => {
  if (imagePreview.value) {
    URL.revokeObjectURL(imagePreview.value)
  }
})

onMounted(async () => {
  await loadCategories()
  // Initialize categories and image preview when editing
  if (props.resource) {
    if (props.resource.categories) {
      formData.value.categories = props.resource.categories.map(c => c.id)
    }
    if (props.resource.image_url) {
      imagePreview.value = props.resource.image_url
    }
  }
})

async function loadCategories() {
  categories.value = await categoryStore.fetchCategories()
}

function toggleCategory(categoryId) {
  const index = formData.value.categories.indexOf(categoryId)
  if (index === -1) {
    formData.value.categories.push(categoryId)
  } else {
    formData.value.categories.splice(index, 1)
  }
}

async function onSubmit() {
  try {
    isLoading.value = true
    const formDataToSend = { ...formData.value }
    
    // Ensure categories is sent as a comma-separated string
    if (Array.isArray(formDataToSend.categories)) {
      formDataToSend.categories = formDataToSend.categories.join(',')
    }
    
    await emit('save', formDataToSend)
  } finally {
    isLoading.value = false
  }
}
</script> 