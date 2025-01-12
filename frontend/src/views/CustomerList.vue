<template>
  <div class="container mx-auto p-4">
    <!-- Header -->
    <div class="flex justify-between items-center mb-6">
      <div>
        <h1 class="text-2xl font-bold">Customers</h1>
        <p class="text-gray-600">Manage customer information</p>
      </div>
      <button @click="createCustomer()" class="btn btn-primary">
        <PlusCircleIcon class="h-5 w-5 mr-2" />
        Add Customer
      </button>
    </div>

    <div class="mb-6 flex items-center gap-2">
      <div class="relative flex-1">
        <input
          ref="searchInput"
          v-model="searchQuery"
          type="text"
          placeholder="Search customers..."
          class="input input-bordered w-full max-w-xs text-lg"
          @input="handleSearch"
        />
        <div v-if="isLoading" class="absolute right-3 top-1/2 transform -translate-y-1/2">
          <span class="loading loading-spinner loading-sm"></span>
        </div>
      </div>
      <button class="btn btn-square" @click="clearSearch" v-if="searchQuery">
        <XMarkIcon class="h-6 w-6" />
      </button>
    </div>

    <nav class="h-full overflow-y-auto rounded-lg bg-white shadow-sm p-5" aria-label="Directory">
      <div v-if="Object.keys(groupedCustomers).length > 0">
        <div v-for="letter in Object.keys(groupedCustomers)" :key="letter" class="relative">
          <div
            class="sticky top-0 z-10 border border-gray-200 rounded-lg px-3 py-1.5 text-lg font-semibold leading-6 text-gray-900"
          >
            <h3>{{ letter }}</h3>
          </div>
          <ul role="list" class="divide-y divide-gray-100">
            <li
              v-for="customer in groupedCustomers[letter]"
              :key="customer.id"
              class="flex gap-x-4 px-3 py-4 hover:bg-gray-50"
              @click="viewCustomer(customer)"
            >
              <div class="avatar placeholder mr-4">
                <div class="bg-neutral-focus text-neutral-content rounded-full w-12 h-12 border">
                  <span class="text-md">{{ getInitials(customer) }}</span>
                </div>
              </div>
              <div class="min-w-0 flex-auto">
                <div class="flex justify-between items-start">
                  <div>
                    <p class="text-lg font-semibold leading-6 text-gray-900">
                      {{ formatName(customer) }}
                    </p>
                    <p class="mt-1 text-sm leading-5 text-gray-500" v-if="customer.phone_number">
                      <span class="flex items-center">
                        <DevicePhoneMobileIcon class="h-4 w-4 mr-1" />
                        {{ customer.phone_number }}
                      </span>
                    </p>
                  </div>
                  <div class="flex items-center gap-2">
                    <!-- Add View and Edit buttons -->
                    <button class="btn btn-sm btn-ghost" @click.stop="viewCustomer(customer)">
                      View
                    </button>
                    <button class="btn btn-sm btn-primary" @click.stop="editCustomer(customer)">
                      Edit
                    </button>
                  </div>
                </div>
              </div>
            </li>
          </ul>
        </div>
      </div>

      <!-- Empty State -->
      <div v-else class="text-center py-12">
        <UserGroupIcon class="h-16 w-16 mx-auto text-gray-400 mb-4" />
        <h2 class="text-2xl font-semibold text-gray-700 mb-2">
          {{ searchQuery ? 'No customers found' : 'No customers yet' }}
        </h2>
        <p class="text-gray-500 mb-4">
          {{
            searchQuery
              ? 'Try adjusting your search terms'
              : 'Get started by adding your first customer!'
          }}
        </p>
        <button v-if="!searchQuery" @click="createCustomer" class="btn btn-primary">
          Add Your First Customer
        </button>
      </div>
    </nav>

    <!-- Replace old pagination with new PaginationBar -->
    <PaginationBar
      v-if="customerStore.pagination.last_page > 1"
      :current-page="customerStore.pagination.current_page"
      :last-page="customerStore.pagination.last_page"
      @page-change="changePage"
    />

    <!-- Customer Form Drawer -->
    <BaseDrawer v-model="showDrawer" :title="drawerTitle">
      <CustomerForm
        v-if="showDrawer"
        :customer="editingCustomer"
        @cancel="closeDrawer"
        @saved="handleSave"
      />
    </BaseDrawer>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useCustomerStore } from '@/stores/customerStore'
import {
  MapPinIcon,
  UserGroupIcon,
  UserPlusIcon,
  DevicePhoneMobileIcon,
  XMarkIcon,
  PlusCircleIcon,
  EyeIcon,
  PencilSquareIcon,
  EnvelopeIcon
} from '@heroicons/vue/24/outline'
import { swalHelper } from '@/utils/swalHelper'
import PaginationBar from '@/components/PaginationBar.vue'
import BaseDrawer from '@/components/common/BaseDrawer.vue'
import CustomerForm from '@/components/CustomerForm.vue'
import debounce from 'lodash/debounce'

const router = useRouter()
const customerStore = useCustomerStore()

// State
const searchQuery = ref('')
const isLoading = ref(false)
const showDrawer = ref(false)
const showEditDrawer = ref(false)
const editingCustomer = ref(null)

// Add searchInput ref
const searchInput = ref(null)

const drawerTitle = computed(() => 
  editingCustomer.value ? 'Edit Customer' : 'Add New Customer'
)

const groupedCustomers = computed(() => {
  const customers = customerStore.customers
  const grouped = {}
  
  customers.forEach((customer) => {
    const firstLetter = (customer.last_name || '').charAt(0).toUpperCase()
    if (!grouped[firstLetter]) {
      grouped[firstLetter] = []
    }
    grouped[firstLetter].push(customer)
  })
  
  return Object.keys(grouped)
    .sort()
    .reduce((acc, key) => {
      acc[key] = grouped[key].sort((a, b) => {
        const lastNameCompare = a.last_name.localeCompare(b.last_name)
        if (lastNameCompare !== 0) return lastNameCompare
        return a.first_name.localeCompare(b.first_name)
      })
      return acc
    }, {})
})

// Methods
async function fetchCustomers(page = 1) {
  isLoading.value = true
  try {
    await customerStore.fetchCustomers({
      page,
      filters: { search: searchQuery.value }
    })
  } catch (error) {
    swalHelper.toast('error', 'Failed to fetch customers')
  } finally {
    isLoading.value = false
  }
}

function clearSearch() {
  searchQuery.value = ''
}

function createCustomer() {
  editingCustomer.value = null
  showDrawer.value = true
}

function closeDrawer() {
  showDrawer.value = false
  editingCustomer.value = null
}

async function handleSave(savedCustomer) {
  closeDrawer()
  router.push({
    name: 'CustomerView',
    params: { uuid: savedCustomer.uuid }
  })
}

function viewCustomer(customer) {
  router.push({ 
    name: 'CustomerView',
    params: { uuid: customer.uuid }
  })
}

function editCustomer(customer) {
  editingCustomer.value = { ...customer }
  showDrawer.value = true
}

function changePage(page) {
  fetchCustomers(page)
}

function getInitials(customer) {
  const lastName = customer.last_name || ''
  const firstName = customer.first_name || ''
  
  const lastInitial = lastName.charAt(0)
  const firstInitial = firstName.charAt(0)
  
  if (!lastInitial && !firstInitial) return '##'
  if (!lastInitial) return firstInitial.toUpperCase()
  if (!firstInitial) return lastInitial.toUpperCase()
  
  return `${lastInitial}${firstInitial}`.toUpperCase()
}

function formatName(customer) {
  const lastName = customer.last_name || ''
  const firstName = customer.first_name || ''
  
  if (!lastName && !firstName) return 'Unknown Name'
  if (!lastName) return firstName
  if (!firstName) return lastName
  
  return `${lastName}, ${firstName}`
}

// Setup
onMounted(() => {
  fetchCustomers()
})

// Watch search query with debounce
const debouncedSearch = debounce(async () => {
  await fetchCustomers(1)
  searchInput.value?.focus()
}, 300)

watch(searchQuery, (newValue) => {
  debouncedSearch()
})
</script>