<template>
  <div class="container mx-auto">
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <!-- Left Column: Customer Details -->
      <div class="md:col-span-1">
        <div class="card shadow-sm bg-white">
          <div class="card-body">
            <div class="flex items-center mb-4">
              <div class="avatar placeholder mr-4">
                <div class="bg-neutral-focus text-neutral-content rounded-full w-15 p-2 border">
                  <span class="text-xl">{{
                    getInitials(customer.first_name + ' ' + customer.last_name)
                  }}</span>
                </div>
              </div>
              <div>
                <h2 class="card-title text-xl">
                  {{ customer.first_name }} {{ customer.last_name }}
                </h2>
                <p class="text-sm">Customer</p>
              </div>
            </div>
            <div class="flex justify-between mb-4">
              <div>
                <p class="font-bold">{{ customer.loans?.length || 0 }}</p>
                <p class="text-sm">Total Loans</p>
              </div>
              <div>
                <p class="font-bold">{{ transactions.length }}</p>
                <p class="text-sm">Transactions</p>
              </div>
              <div>
                <p class="font-bold">{{ activeLoans.length }}</p>
                <p class="text-sm">Active Loans</p>
              </div>
            </div>
            <div class="flex justify-between">
              <button class="btn btn-sm" @click="showEditDrawer">
                <PencilSquareIcon class="h-4 w-4" />
                Edit Customer
              </button>
              <button @click="handleNewLoan" class="btn btn-primary btn-sm">
                Add New Loan
              </button>
            </div>
          </div>
        </div>

        <div class="card shadow-sm bg-base-100 mt-6">
          <div class="card-body">
            <h3 class="card-title text-xl mb-4">Contact Information</h3>
            <div class="space-y-2">
              <p class="flex items-center">
                <PhoneIcon class="h-5 w-5 mr-2" />
                {{ customer.phone_number || 'No phone provided' }}
              </p>
              <div class="flex items-center">
                <MapPinIcon class="h-5 w-5 mr-2" />
                {{ customer.address || 'No address provided' }}
              </div>
              <p class="flex items-center" v-if="customer.email">
                <EnvelopeIcon class="h-5 w-5 mr-2" />
                {{ customer.email }}
              </p>
              <p class="flex items-center">
                <IdentificationIcon class="h-5 w-5 mr-2" />
                {{
                  customer.id_type ? `${customer.id_type}: ${customer.id_number}` : 'No ID provided'
                }}
              </p>
            </div>
          </div>
        </div>

        <div class="card shadow-sm bg-base-100 mt-6">
          <div class="card-body">
            <h3 class="card-title text-xl mb-4">Remarks</h3>
            {{ customer.remarks || 'No Remarks Found' }}
          </div>
        </div>
      </div>

      <!-- Right Column -->
      <div class="md:col-span-2">
        <!-- Loans Section -->
        <div class="card shadow-sm bg-base-100 mb-6">
          <div class="card-body">
            <div class="flex justify-between items-center mb-2">
                <h3 class="card-title text-2xl">Loans</h3>
              <div class="tabs tabs-boxed">
                <a
                  class="tab"
                  :class="{ 'tab-active': loanTab === 'active' }"
                  @click="
                    () => {
                      loanTab = 'active'
                      fetchLoans('active')
                    }
                  "
                  >Active</a
                >
                <a
                  class="tab"
                  :class="{ 'tab-active': loanTab === 'history' }"
                  @click="
                    () => {
                      loanTab = 'history'
                      fetchLoans('history')
                    }
                  "
                  >History</a
                >
              </div>
            </div>

            <div class="space-y-4">
              <div
                v-for="loan in loans"
                :key="loan.id"
                class="card bg-base-100 shadow-sm hover:bg-gray-50 cursor-pointer"
                @click="handleViewLoan(loan)"
              >
                <div class="card-body p-4">
                  <div class="flex items-start">
                    <!-- Left side: Loan basic info - Fixed width -->
                    <div class="space-y-1 w-80 flex-shrink-0">
                      <div class="flex items-center gap-2">
                        <span class="text-sm text-gray-500">Pawn Ticket #:</span>
                        <span class="font-semibold">{{ loan.pawn_ticket_number }}</span>
                      </div>
                      <div>
                        <p v-if="loan.items && loan.items.length > 0">
                          <span v-for="(item, index) in loan.items" :key="item.id">
                            {{ item.description }}{{ index < loan.items.length - 1 ? ', ' : '' }}
                          </span>
                        </p>
                        <p v-else class="truncate">{{ loan.item?.description || 'No items' }}</p>
                      </div>
                      <p class="font-medium" v-currency="loan.loan_amount"></p>
                    </div>

                    <!-- Middle: Dates and Status - Fixed width -->
                    <div class="space-y-2 w-72 flex-shrink-0">
                      <div class="flex items-center gap-1">
                        <span class="text-sm text-gray-500 w-16">Status:</span>
                        <div class="badge" :class="getStatusClass(loan.status)">
                          <BellIcon
                            class="h-4 w-4 mr-1 text-red-600"
                            v-if="loan.status === LoanStatus.PendingPayment"
                          />
                          {{ getStatusLabel(loan.status) }}
                        </div>
                      </div>
                      <div class="flex items-center gap-1">
                        <span class="text-sm text-gray-500 w-16">Maturity:</span>
                        <span :class="{ 'text-red-700': isDatePassed(loan.maturity_date) }">
                          {{ formatDate(loan.maturity_date) }}
                        </span>
                        <BellAlertIcon
                          v-if="isDatePassed(loan.maturity_date)"
                          class="h-5 w-5 text-red-500"
                        />
                      </div>
                      <div class="flex items-center gap-1">
                        <span class="text-sm text-gray-500 w-16">Expiry:</span>
                        <span>{{ formatDate(loan.expiry_date) }}</span>
                        <BellIcon
                          v-if="isDatePassed(loan.expiry_date)"
                          class="h-5 w-5 text-red-500"
                        />
                      </div>
                    </div>

                    <!-- Right side: Actions - Auto width -->
                    <div class="flex gap-2 ml-auto">
                      <button class="btn btn-xs btn-outline" @click.stop="handleViewLoan(loan)">
                        View
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Empty State -->
              <div v-if="!loans.length" class="text-center py-4 text-gray-500">
                No {{ loanTab === 'active' ? 'active' : 'historical' }} loans found
              </div>

              <!-- Pagination -->
              <PaginationBar
                v-if="pagination.last_page > 1"
                :current-page="pagination.current_page"
                :last-page="pagination.last_page"
                @page-change="handlePageChange"
              />
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Add Customer Edit Drawer -->
    <BaseDrawer
      v-model="showDrawer"
      title="Edit Customer"
    >
      <CustomerForm
        v-if="showDrawer && editingCustomer"
        :customer="editingCustomer"
        @cancel="closeDrawer"
        @save="handleSave"
      />
    </BaseDrawer>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useCustomerStore } from '@/stores/customerStore'
import { swalHelper } from '@/utils/swalHelper'
import {
  MapPinIcon,
  PhoneIcon,
  EnvelopeIcon,
  IdentificationIcon,
  BanknotesIcon,
  EyeIcon,
  PlusCircleIcon
} from '@heroicons/vue/24/outline'
import { BellIcon, BellAlertIcon, PencilSquareIcon } from '@heroicons/vue/20/solid'
import LoanStatus, { loanStatusProperties } from '@/common/enums/generated/LoanStatus'
import PaginationBar from '@/components/PaginationBar.vue'
import BaseDrawer from '@/components/common/BaseDrawer.vue'
import CustomerForm from '@/components/CustomerForm.vue'

const route = useRoute()
const router = useRouter()
const customerStore = useCustomerStore()

// Add these functions to replace useLoanStatus
function getStatusClass(status) {
  const statusMap = {
    Active: 'badge-success',
    Completed: 'badge-info',
    Expired: 'badge-error',
    PendingPayment: 'badge-warning',
    Default: 'badge-ghost'
  }
  return statusMap[status] || statusMap.Default
}

function getStatusLabel(status) {
  return status?.replace(/([A-Z])/g, ' $1').trim() || 'Unknown'
}

function isDatePassed(date) {
  if (!date) return false
  return new Date(date) < new Date()
}

// State
const customer = ref({})
const transactions = ref([
  { id: 1, date: '2023-01-01', type: 'Payment', amount: 1000 },
  { id: 2, date: '2023-01-15', type: 'Loan', amount: 5000 },
  { id: 3, date: '2023-02-01', type: 'Payment', amount: 1500 },
])
const loanTab = ref('active')
const loans = ref([])
const pagination = ref({
  current_page: 1,
  last_page: 1
})
const selectedLoan = ref(null)
const showModal = ref(false)
const showDrawer = ref(false)
const editingCustomer = ref(null)

// Computed
const activeLoans = computed(() => {
  return (
    customer.value.loans?.filter((loan) => !['Renewed', 'Cancelled'].includes(loan.status)) || []
  )
})

// Lifecycle hooks
onMounted(async () => {
  clearCustomerData()
  await fetchCustomerDetails()
  await fetchLoans('active')
})

watch(
  () => route.params.uuid,
  async (newId, oldId) => {
    if (newId !== oldId) {
      clearCustomerData() // Clear when customer changes
      await fetchCustomerDetails()
      await fetchLoans('active')
    }
  }
)

// Watchers
watch(
  () => loanTab.value,
  (newTab) => {
    fetchLoans(newTab === 'active' ? 'active' : 'history')
  }
)

function clearCustomerData() {
  customer.value = {}
  transactions.value = [
    { id: 1, date: '2023-01-01', type: 'Payment', amount: 1000 },
    { id: 2, date: '2023-01-15', type: 'Loan', amount: 5000 },
    { id: 3, date: '2023-02-01', type: 'Payment', amount: 1500 },
  ]
  loans.value = []
  loanTab.value = 'active'
}

// Methods
async function fetchCustomerDetails() {
  try {
    customer.value = await customerStore.fetchCustomer(route.params.uuid)
  } catch (error) {
    swalHelper.toast('error', 'Failed to fetch customer details')
  }
}

function fetchLoans(type = 'active', page = 1) {
  // Dummy data for loans
  loans.value = type === 'active' 
    ? [
        {
          id: 1,
          uuid: 'loan-1',
          pawn_ticket_number: 'PT001',
          status: 'Active',
          loan_amount: 5000,
          maturity_date: '2024-03-01',
          expiry_date: '2024-04-01',
          items: [{ id: 1, description: 'Gold Ring' }]
        }
      ]
    : [
        {
          id: 2,
          uuid: 'loan-2',
          pawn_ticket_number: 'PT002',
          status: 'Completed',
          loan_amount: 3000,
          maturity_date: '2023-12-01',
          expiry_date: '2024-01-01',
          items: [{ id: 2, description: 'Silver Necklace' }]
        }
      ]
  
  pagination.value = {
    current_page: page,
    last_page: 1
  }
}

function handlePageChange(page) {
  fetchLoans(loanTab.value, page)
}

function formatDate(dateString) {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

function getInitials(name) {
  if (!name) return ''
  return name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
}

function showEditDrawer() {
  editingCustomer.value = { ...customer.value }
  showDrawer.value = true
}

function closeDrawer() {
  showDrawer.value = false
  editingCustomer.value = null
}

async function handleSave(customerData) {
  try {
    await customerStore.updateCustomer(customerData.uuid, customerData)
    swalHelper.toast('success', 'Customer updated successfully')
    closeDrawer()
    await fetchCustomerDetails() // Refresh the view
  } catch (error) {
    console.error('Customer update error:', error)
    swalHelper.toast('error', 'Failed to update customer')
  }
}

function handleViewLoan(loan) {
  router.push({
    name: 'LoanView',
    params: { uuid: loan.uuid }
  })
}

function handleNewLoan() {
  router.push({ 
    name: 'LoanCreate',
    query: { customerId: customer.value.uuid }
  })
}

// Define emits
const emit = defineEmits(['editLoan', 'viewLoan'])
</script>
