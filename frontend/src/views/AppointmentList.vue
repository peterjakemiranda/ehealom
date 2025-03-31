<template>
  <div class="container mx-auto p-4">
    <!-- Header with Add Button -->
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-6">
      <h2 class="text-xl font-bold text-primary">Appointments</h2>
      <button 
        v-if="!isStudent" 
        @click="createAppointment" 
        class="btn btn-primary mt-2 sm:mt-0"
      >
        Book Appointment
      </button>
    </div>

    <!-- Counselor Filters -->
    <div v-if="isCounselor" class="mb-6">
      <div class="flex flex-wrap gap-4 items-center">
        <!-- User Type Filter -->
        <div class="form-control">
          <select 
            v-model="selectedUserType" 
            class="select select-bordered bg-gray-50"
            @change="handleFiltersChange"
          >
            <option value="all">All Users</option>
            <option value="student">Students</option>
            <option value="personnel">Personnel</option>
          </select>
        </div>

        <!-- Search by Name -->
        <div class="form-control flex-1">
          <div class="relative">
            <input
              v-model="searchQuery"
              type="text"
              placeholder="Search by name..."
              class="input input-bordered w-full bg-gray-50"
              @input="handleFiltersChange"
            />
            <button
              v-if="searchQuery"
              @click="clearSearch"
              class="absolute right-2 top-1/2 -translate-y-1/2 btn btn-ghost btn-sm"
            >
              <i class="fas fa-times"></i>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Status Filters with Counts -->
    <div class="mb-6">
      <div class="inline-flex bg-base-100 rounded-lg p-1 shadow-sm">
        <button 
          v-for="filter in statusFilters" 
          :key="filter.value"
          class="px-4 py-2 rounded-md text-sm font-medium transition-colors"
          :class="[
            statusFilter === filter.value 
              ? 'bg-primary text-white' 
              : 'text-gray-600 hover:bg-gray-100'
          ]"
          @click="handleStatusFilterChange(filter.value)"
        >
          {{ filter.label }} ({{ counts[filter.value] || 0 }})
        </button>
      </div>
    </div>

    <!-- Appointments List -->
    <div v-if="!appointmentStore.isLoading" class="space-y-6">
      <div v-for="(group, month) in groupedAppointments" :key="month">
        <div class="text-lg font-semibold text-gray-600 mb-4">{{ month }}</div>
        <div class="space-y-4">
          <AppointmentCard
            v-for="appointment in group"
            :key="appointment.id"
            :appointment="appointment"
            @edit="editAppointment"
            @update-status="handleStatusUpdate"
          >
            <!-- Add slot for action buttons -->
            <template #actions>
              <div class="flex gap-2">
                <button 
                  v-if="canConfirmAppointment(appointment)"
                  @click="handleStatusUpdate(appointment, 'confirmed')"
                  class="btn btn-success btn-sm text-white"
                >
                  Confirm
                </button>
                <button 
                  v-if="canCompleteAppointment(appointment)"
                  @click="handleStatusUpdate(appointment, 'completed')"
                  class="btn btn-info btn-sm text-white"
                >
                  Complete
                </button>
                <button 
                  v-if="canEditAppointment(appointment)"
                  @click="editAppointment(appointment)"
                  class="btn btn-primary btn-sm"
                >
                  Edit
                </button>
                <button 
                  v-if="canDeleteAppointment(appointment)"
                  @click="confirmDeleteAppointment(appointment)"
                  class="btn btn-error btn-sm"
                >
                  <TrashIcon class="w-4 h-4" />
                </button>
              </div>
            </template>
          </AppointmentCard>
        </div>
      </div>

      <div v-if="Object.keys(groupedAppointments).length === 0" 
           class="text-center py-8 text-gray-500">
        No appointments found
      </div>
    </div>

    <!-- Loading State -->
    <div v-else class="flex justify-center py-8">
      <span class="loading loading-spinner loading-lg"></span>
    </div>

    <!-- Appointment Form Drawer -->
    <Drawer v-model="showDrawer" :title="drawerTitle">
      <AppointmentForm
        :appointment="selectedAppointment"
        @save="handleSave"
        @cancel="closeDrawer"
      />
    </Drawer>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { format, parseISO } from 'date-fns'
import { useAppointmentStore } from '@/stores/appointmentStore'
import { useAuthStore } from '@/stores/auth'
import AppointmentCard from '@/components/AppointmentCard.vue'
import AppointmentForm from '@/components/AppointmentForm.vue'
import Drawer from '@/components/common/BaseDrawer.vue'
import { swalHelper } from '@/utils/swalHelper'
import http from '@/utils/http'
import { TrashIcon } from '@heroicons/vue/24/outline';

const appointmentStore = useAppointmentStore()
const authStore = useAuthStore()
const showDrawer = ref(false)
const selectedAppointment = ref({})
const statusFilter = ref('pending')
const searchQuery = ref('')
const counts = ref({
  upcoming: 0,
  pending: 0,
  history: 0
})

const selectedUserType = ref('all')
const isStudent = computed(() => authStore.user?.user_type === 'student')
const isCounselor = computed(() => authStore.user?.roles.includes('counselor'))

const statusFilters = [
  { value: 'pending', label: 'Pending' },
  { value: 'upcoming', label: 'Upcoming' },
  { value: 'history', label: 'History' }
]

const drawerTitle = computed(() => {
  return selectedAppointment.value?.id ? 'Edit Appointment' : 'Book Appointment'
})

const filteredAppointments = computed(() => {
  return appointmentStore.appointments
})

const groupedAppointments = computed(() => {
  const groups = {}
  filteredAppointments.value.forEach(appointment => {
    const monthKey = format(parseISO(appointment.appointment_date), 'MMMM yyyy')
    if (!groups[monthKey]) {
      groups[monthKey] = []
    }
    groups[monthKey].push(appointment)
  })
  return groups
})

onMounted(() => {
  fetchAppointments()
})

watch(statusFilter, () => {
  fetchAppointments()
})

function clearSearch() {
  searchQuery.value = ''
  handleFiltersChange()
}

function handleStatusFilterChange(value) {
  statusFilter.value = value
  fetchAppointments(1)
}

async function fetchAppointments(page = 1) {
  try {
    const filters = {
      page,
      status: statusFilter.value
    }

    if (isCounselor.value) {
      if (selectedUserType.value !== 'all') {
        filters.user_type = selectedUserType.value
      }
      if (searchQuery.value) {
        filters.search = searchQuery.value
      }
    }

    console.log('Fetching with filters:', filters)
    await Promise.all([
      appointmentStore.fetchAppointments(filters),
      fetchCounts(filters)
    ])
  } catch (error) {
    console.error('Failed to fetch appointments:', error)
  }
}

function createAppointment() {
  selectedAppointment.value = {
    id: null,
    appointment_date: '',
    reason: '',
    counselor_id: '',
    status: 'pending',
    notes: '',
    location_type: 'online',
    location: ''
  }
  showDrawer.value = true
}

function editAppointment(appointment) {
  selectedAppointment.value = {
    ...appointment,
    counselor_id: appointment.counselor?.id || appointment.counselor_id,
    student_id: appointment.student?.id || appointment.student_id
  }
  showDrawer.value = true
}

async function handleStatusUpdate(appointment, newStatus) {
  try {
    await appointmentStore.updateAppointmentStatus(appointment.uuid, newStatus)
    await fetchCounts()
    //fetch appointments
    await fetchAppointments()
    swalHelper.toast('success', 'Appointment status updated')
  } catch (error) {
    console.error('Failed to update status:', error)
    swalHelper.toast('error', 'Failed to update appointment status')
  }
}

function closeDrawer() {
  showDrawer.value = false
  selectedAppointment.value = null
}

async function handleSave(appointmentData) {
  try {
    if (selectedAppointment.value.uuid) {
      await appointmentStore.updateAppointment(selectedAppointment.value.uuid, appointmentData)
      swalHelper.toast('success', 'Appointment updated successfully')
    } else {
      await appointmentStore.createAppointment(appointmentData)
      swalHelper.toast('success', 'Appointment booked successfully')
    }
    closeDrawer()
    await fetchAppointments(appointmentStore.currentPage)
  } catch (error) {
    console.error('Appointment save error:', error)
    swalHelper.toast('error', `Failed to ${selectedAppointment.value.id ? 'update' : 'book'} appointment`)
  }
}

const canManageAppointments = computed(() => {
  return authStore.user?.permissions?.includes('manage appointments')
})

const canConfirmAppointment = (appointment) => {
  return canManageAppointments.value && appointment.status === 'pending'
}

const canCompleteAppointment = (appointment) => {
  return canManageAppointments.value && 
    appointment.status === 'confirmed'
}

const canEditAppointment = (appointment) => {
  if (!canManageAppointments.value) {
    return appointment.status === 'pending' && appointment.student_id === authStore.user?.id
  }
  return canManageAppointments.value && ['pending', 'confirmed'].includes(appointment.status)
}

const canDeleteAppointment = (appointment) => {
  return authStore.user?.roles?.includes('counselor');
}

async function confirmDeleteAppointment(appointment) {
  try {
    const result = await swalHelper.confirm({
      title: 'Delete Appointment',
      text: `Are you sure you want to delete this appointment? This action cannot be undone.`,
      icon: 'warning',
      confirmButtonText: 'Yes, delete it!',
      confirmButtonColor: '#ef4444'
    })

    if (result.isConfirmed) {
      await appointmentStore.deleteAppointment(appointment.uuid)
      swalHelper.toast('success', 'Appointment deleted successfully')
      await fetchAppointments()
      await fetchCounts()
    }
  } catch (error) {
    console.error('Failed to delete appointment:', error)
    swalHelper.toast('error', 'Failed to delete appointment')
  }
}

async function fetchCounts(filters = {}) {
  try {
    console.log('Fetching counts with filters:', filters)
    const response = await http.get('/api/appointments/counts', { params: filters })
    counts.value = response.data
  } catch (error) {
    console.error('Failed to fetch counts:', error)
  }
}

function handleFiltersChange() {
  fetchAppointments(1)
}

watch([selectedUserType, searchQuery, statusFilter], ([newUserType, newSearch, newStatus], [oldUserType, oldSearch, oldStatus]) => {
  console.log('Filter changed:', {
    userType: { old: oldUserType, new: newUserType },
    search: { old: oldSearch, new: newSearch },
    status: { old: oldStatus, new: newStatus }
  })
  handleFiltersChange()
})
</script>

<style scoped>
.tabs-boxed {
  @apply bg-base-200 rounded-lg p-1;
}

.tab {
  @apply px-4 py-2 rounded-md transition-colors;
}

.tab-active {
  @apply bg-primary text-primary-content;
}
</style> 