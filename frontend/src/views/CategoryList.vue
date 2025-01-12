<template>
  <div class="container mx-auto p-4">
    <!-- Header -->
    <div class="flex justify-between items-center mb-6">
      <div>
        <h1 class="text-2xl font-bold">Categories</h1>
        <p class="text-gray-600">Manage loan categories and their settings</p>
      </div>
      <button @click="createCategory()" class="btn btn-primary">
        <PlusCircleIcon class="h-5 w-5 mr-2" />
        Add Category
      </button>
    </div>

    <!-- Search -->
    <div class="mb-6">
      <div class="flex items-center gap-2">
        <input 
          type="text"
          v-model="searchQuery"
          placeholder="Search categories..."
          class="input input-bordered w-full max-w-xs"
          :disabled="categoryStore.isLoading"
        />
        <button 
          class="btn btn-square" 
          @click="clearSearch" 
          v-if="searchQuery"
          :disabled="categoryStore.isLoading"
        >
          <XMarkIcon class="h-6 w-6" />
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="categoryStore.isLoading" class="text-center py-12">
      <div class="loading loading-spinner loading-lg"></div>
      <p class="mt-4 text-gray-600">Loading categories...</p>
    </div>

    <!-- Error State -->
    <div v-else-if="categoryStore.error" class="alert alert-error shadow-sm">
      <ExclamationCircleIcon class="h-6 w-6" />
      <span>{{ categoryStore.error }}</span>
      <button class="btn btn-sm btn-ghost" @click="retryFetch">Retry</button>
    </div>

    <!-- Categories Grid -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <div 
        v-for="category in categoryStore.categories" 
        :key="category.uuid" 
        class="card bg-base-100 shadow-sm"
      >
        <div class="card-body">
          <!-- Add sync status indicator -->
          <div class="flex justify-between items-start">
            <div>
              <h3 class="font-bold">{{ category.name }}</h3>
              <p class="text-sm text-gray-500">{{ category.description || 'No description' }}</p>
            </div>
            <div class="flex items-center gap-2">
              <span v-if="category.sync_status === 'pending'" 
                    class="badge badge-warning badge-sm">
                Syncing...
              </span>
              <div class="badge badge-sm" :class="category.is_renewable ? 'badge-outline' : 'badge-neutral'">
                {{ category.is_renewable ? 'Renewable' : 'Non-renewable' }}
              </div>
            </div>
          </div>

          <div class="space-y-2 mt-4">
            <!-- Interest and Penalty Rates -->
            <div class="flex justify-between text-sm">
              <span class="text-gray-600">Interest Rate:</span>
              <span class="font-semibold">{{ category.interest_rate }}%</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-600">Penalty Rate:</span>
              <span class="font-semibold">{{ category.penalty_rate }}%</span>
            </div>

            <!-- Divider -->
            <div class="border-t border-gray-200 my-2"></div>

            <!-- Loan Period Details -->
            <div class="flex justify-between text-sm">
              <span class="text-gray-600">Loan Period:</span>
              <span>{{ category.loan_period }} {{ category.loan_period_type }}(s)</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-600">Grace Period:</span>
              <span>{{ category.loan_period_expiry }} days</span>
            </div>
          </div>

          <!-- Add Actions section at the bottom -->
          <div class="card-actions justify-end mt-4">
            <button 
              class="btn btn-primary btn-sm" 
              @click="editCategory(category)"
            >
              Edit Category
            </button>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div v-if="!categoryStore.hasCategories" class="col-span-full text-center py-12">
        <TagIcon class="h-16 w-16 mx-auto text-gray-400 mb-4" />
        <h2 class="text-2xl font-semibold text-gray-700 mb-2">
          {{ searchQuery ? 'No categories found' : 'No categories yet' }}
        </h2>
        <p class="text-gray-500 mb-4">
          {{ searchQuery ? 'Try adjusting your search terms' : 'Get started by adding your first category!' }}
        </p>
        <button v-if="!searchQuery" @click="createCategory" class="btn btn-primary">
          Add Your First Category
        </button>
      </div>
    </div>

    <!-- Pagination -->
    <div class="mt-6">
      <PaginationBar
        v-if="categoryStore.pagination.last_page > 1"
        :current-page="categoryStore.pagination.current_page"
        :last-page="categoryStore.pagination.last_page"
        @page-change="changePage"
      />
    </div>

    <!-- Category Form Drawer -->
    <BaseDrawer
      v-model="showDrawer"
      :title="isEditing ? 'Edit Category' : 'Add Category'"
    >
      <CategoryForm
        v-if="selectedCategory"
        :category="selectedCategory"
        @cancel="closeDrawer"
        @save="handleSave"
      />
    </BaseDrawer>
  </div>
</template>

<script setup>
import { ref, onMounted, watch, computed, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useCategoryStore } from '@/stores/categoryStore'
import { debounce } from 'lodash'
import {
  PlusCircleIcon,
  XMarkIcon,
  ChevronRightIcon,
  TagIcon,
  ExclamationCircleIcon,
  PencilSquareIcon
} from '@heroicons/vue/24/outline'
import PaginationBar from '@/components/PaginationBar.vue'
import { swalHelper } from '@/utils/swalHelper'
import BaseDrawer from '@/components/common/BaseDrawer.vue'
import CategoryForm from '@/components/CategoryForm.vue'

const router = useRouter()
const categoryStore = useCategoryStore()
const searchQuery = ref('')
const perPage = ref(10)
const showDrawer = ref(false)
const selectedCategory = ref(null)
const isEditing = computed(() => !!selectedCategory.value?.uuid) // Change this line

// Create debounced search function
const debouncedSearch = debounce(() => {
  fetchCategories(1) // Reset to first page when searching
}, 300)

// Watch for search query changes
watch(searchQuery, () => {
  debouncedSearch()
})

onMounted(async () => {
  await fetchCategories()
  
  // Add network status listeners
  window.addEventListener('online', handleNetworkChange)
  window.addEventListener('offline', handleNetworkChange)
})

onUnmounted(() => {
  window.removeEventListener('online', handleNetworkChange)
  window.removeEventListener('offline', handleNetworkChange)
})

// Main fetch function
async function fetchCategories(page = 1) {
  try {
    await categoryStore.fetchCategories({
      page,
      search: searchQuery.value,
      perPage: perPage.value
    })
  } catch (error) {
    console.error('Failed to fetch categories:', error)
  }
}

// Handler functions
function clearSearch() {
  searchQuery.value = ''
  fetchCategories(1)
}

function changePage(page) {
  fetchCategories(page)
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

function handlePerPageChange() {
  fetchCategories(1) // Reset to first page when changing items per page
}

function createCategory() {
  selectedCategory.value = {
    name: '',
    description: '',
    interest_rate: 0,
    penalty_rate: 0,
    loan_period: 1,
    loan_period_type: 'month',
    loan_period_expiry: 0,
    is_renewable: true
  }
  showDrawer.value = true
}

function editCategory(category) {
  selectedCategory.value = { ...category }
  showDrawer.value = true
}

function closeDrawer() {
  showDrawer.value = false
  selectedCategory.value = null
}

async function handleSave(categoryData) {
  try {
    if (isEditing.value) {
      await categoryStore.updateCategory(categoryData.uuid, categoryData) // Change id to uuid
      swalHelper.toast('success', 'Category updated successfully')
    } else {
      await categoryStore.addCategory(categoryData)
      swalHelper.toast('success', 'Category created successfully')
    }
    closeDrawer()
    await fetchCategories(categoryStore.pagination.current_page)
  } catch (error) {
    console.error('Category save error:', error)
    swalHelper.toast('error', `Failed to ${isEditing.value ? 'update' : 'create'} category`)
  }
}

// Clean up debounce on component unmount
onUnmounted(() => {
  debouncedSearch.cancel()
})

function handleNetworkChange() {
  isOnline.value = navigator.onLine
  if (isOnline.value) {
    // Refresh data when coming back online
    fetchCategories()
  }
}

// Add this method to check actual sync status
function calculateSyncStatus(category) {
  return category.sync_status === 'synced' || category.server_id ? 'synced' : 'pending';
}

// Update the computed property
const pendingSync = computed(() => {
  return categoryStore.categories.some(cat => calculateSyncStatus(cat) === 'pending');
});
</script>
