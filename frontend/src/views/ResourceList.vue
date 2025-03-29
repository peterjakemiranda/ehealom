<template>
  <div class="container mx-auto p-4">
    <!-- Header -->
    <div class="flex justify-between items-center mb-6">
      <div>
        <h1 class="text-2xl font-bold">Resources</h1>
        <p class="text-gray-600">Access mental health resources and guides</p>
      </div>
      <button v-if="showAddButton" @click="createResource()" class="btn btn-primary">
        <PlusCircleIcon class="h-5 w-5 mr-2" />
        Add Resource
      </button>
    </div>

    <!-- Filters -->
    <div class="mb-6 flex gap-4">
      <div class="w-full max-w-xs">
        <select 
          v-model="selectedCategory"
          class="select select-bordered w-full"
          :disabled="resourceStore.isLoading"
        >
          <option value="">All Categories</option>
          <option v-for="category in categories" 
                  :key="category.id" 
                  :value="category.id">
            {{ category.title }}
          </option>
        </select>
      </div>

      <input 
        ref="searchInput"
        type="text"
        v-model="searchQuery"
        placeholder="Search resources..."
        class="input input-bordered w-full max-w-xs"
        :disabled="resourceStore.isLoading"
      />
    </div>

    <!-- Loading State -->
    <div v-if="resourceStore.isLoading" class="text-center py-12">
      <div class="loading loading-spinner loading-lg"></div>
      <p class="mt-4 text-gray-600">Loading resources...</p>
    </div>

    <!-- Error State -->
    <div v-else-if="resourceStore.error" class="alert alert-error shadow-sm">
      <ExclamationCircleIcon class="h-6 w-6" />
      <span>{{ resourceStore.error }}</span>
      <button class="btn btn-sm btn-ghost" @click="fetchResources">Retry</button>
    </div>

    <!-- Resources Grid -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div 
        v-for="resource in resourceStore.resources" 
        :key="resource.uuid" 
        class="card bg-base-100 shadow-xl overflow-hidden"
      >
        <!-- Image -->
        <figure class="relative h-48">
          <img 
            :src="resource.image_url || '/images/placeholder.jpg'" 
            :alt="resource.title"
            class="w-full h-full object-cover"
          />
          <div class="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent"></div>
          <div class="absolute bottom-0 left-0 right-0 p-4">
            <h3 class="text-xl font-bold text-white">{{ resource.title }}</h3>
          </div>
        </figure>

        <div class="card-body">
          <!-- Categories -->
          <div class="flex flex-wrap gap-2 mb-4">
            <div v-for="category in resource.categories" 
                 :key="category.id"
                 class="badge badge-primary">
              {{ category.title }}
            </div>
          </div>

          <!-- Content -->
          <p class="text-sm text-gray-600">{{ truncateContent(resource.content) }}</p>

          <!-- Status Badge -->
          <div v-if="showEditButton" 
               class="absolute top-4 right-4 badge" 
               :class="resource.is_published ? 'badge-success text-white' : 'badge-ghost'">
            {{ resource.is_published ? 'Published' : 'Draft' }}
          </div>

          <!-- Actions -->
          <div class="card-actions justify-end mt-4">
            <button 
              v-if="showEditButton"
              class="btn btn-primary btn-sm" 
              @click="editResource(resource)"
            >
              Edit
            </button>
            <button 
              v-if="showDeleteButton" 
              @click="confirmDelete(resource)" 
              class="btn btn-error btn-sm"
            >
              Delete
            </button>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div v-if="!resourceStore.hasResources" class="col-span-full text-center py-12">
        <DocumentIcon class="h-16 w-16 mx-auto text-gray-400 mb-4" />
        <h2 class="text-2xl font-semibold text-gray-700 mb-2">
          No resources found
        </h2>
        <p class="text-gray-500 mb-4">
          {{ selectedCategory || searchQuery ? 'Try adjusting your filters' : 'Check back later for new resources!' }}
        </p>
        <button v-if="showAddButton" @click="createResource" class="btn btn-primary">
          Add Your First Resource
        </button>
      </div>
    </div>

    <!-- Pagination -->
    <div class="mt-6">
      <PaginationBar
        v-if="resourceStore.totalPages > 1"
        :current-page="resourceStore.currentPage"
        :last-page="resourceStore.totalPages"
        @page-change="changePage"
      />
    </div>

    <!-- Resource Form Drawer -->
    <BaseDrawer
      v-model="showDrawer"
      :title="isEditing ? 'Edit Resource' : 'Add Resource'"
    >
      <ResourceForm
        v-if="selectedResource"
        :resource="selectedResource"
        @cancel="closeDrawer"
        @save="handleSave"
      />
    </BaseDrawer>
  </div>
</template>

<script setup>
import { ref, onMounted, watch, computed, onUnmounted } from 'vue'
import { useResourceStore } from '@/stores/resourceStore'
import { useCategoryStore } from '@/stores/categoryStore'
import { useAuthStore } from '@/stores/auth'
import {
  PlusCircleIcon,
  ExclamationCircleIcon,
  DocumentIcon
} from '@heroicons/vue/24/outline'
import PaginationBar from '@/components/PaginationBar.vue'
import BaseDrawer from '@/components/common/BaseDrawer.vue'
import ResourceForm from '@/components/ResourceForm.vue'
import { swalHelper } from '@/utils/swalHelper'
import debounce from 'lodash/debounce'

const resourceStore = useResourceStore()
const categoryStore = useCategoryStore()
const authStore = useAuthStore()

const selectedCategory = ref('')
const searchQuery = ref('')
const categories = ref([])
const showDrawer = ref(false)
const selectedResource = ref(null)
const searchInput = ref(null)

const canManageResources = computed(() => {
  return authStore.user?.permissions?.includes('manage resources')
})

const canViewResources = computed(() => {
  return authStore.user?.permissions?.includes('view resources')
})

const showAddButton = computed(() => canManageResources.value)
const showEditButton = computed(() => canManageResources.value)
const showDeleteButton = computed(() => canManageResources.value)

const isAdmin = computed(() => authStore.user?.roles?.includes('admin'))
const isEditing = computed(() => !!selectedResource.value?.uuid)

// Create debounced search function
const debouncedSearch = debounce(async (value) => {
  await fetchResources(1)
  // Refocus the input after search is complete
  searchInput.value?.focus()
}, 300)

// Load categories on mount
onMounted(async () => {
  categories.value = await categoryStore.fetchCategories()
  fetchResources()
})

// Watch for filter changes
watch(selectedCategory, () => {
  fetchResources(1)
})

// Separate watch for search query with debounce
watch(searchQuery, (newValue) => {
  debouncedSearch(newValue)
})

// Clean up debounce on component unmount
onUnmounted(() => {
  debouncedSearch.cancel()
})

async function fetchResources(page = 1) {
  await resourceStore.fetchResources({
    page,
    category: selectedCategory.value,
    search: searchQuery.value
  })
}

function truncateContent(content, length = 150) {
  if (content.length <= length) return content
  return content.substring(0, length) + '...'
}

function createResource() {
  selectedResource.value = {
    title: '',
    content: '',
    type: '',
    category: '',
    is_published: false,
    created_at: new Date().toISOString()
  }
  showDrawer.value = true
}

function editResource(resource) {
  selectedResource.value = { ...resource }
  showDrawer.value = true
}

function closeDrawer() {
  showDrawer.value = false
  selectedResource.value = null
}

async function handleSave(resourceData) {
  try {
    if (isEditing.value) {
      await resourceStore.updateResource(resourceData.uuid, resourceData)
      swalHelper.toast('success', 'Resource updated successfully')
    } else {
      await resourceStore.createResource(resourceData)
      swalHelper.toast('success', 'Resource created successfully')
    }
    closeDrawer()
    await fetchResources(resourceStore.currentPage)
  } catch (error) {
    console.error('Resource save error:', error)
    swalHelper.toast('error', `Failed to ${isEditing.value ? 'update' : 'create'} resource`)
  }
}

function changePage(page) {
  fetchResources(page)
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

async function confirmDelete(resource) {
  try {
    const result = await swalHelper.confirm({
      title: 'Delete Resource',
      text: `Are you sure you want to delete "${resource.title}"? This action cannot be undone.`,
      icon: 'warning',
      confirmButtonText: 'Yes, delete it!',
      confirmButtonColor: '#ef4444'
    })

    if (result.isConfirmed) {
      await resourceStore.deleteResource(resource.uuid)
      swalHelper.toast('success', 'Resource deleted successfully')
      await fetchResources()
    }
  } catch (error) {
    console.error('Failed to delete resource:', error)
    swalHelper.toast('error', 'Failed to delete resource')
  }
}
</script> 