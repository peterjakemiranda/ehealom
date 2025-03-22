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
    <div v-if="isCounselor" class="mb-6 space-y-4">
      <!-- User Type Filter -->
      <div class="form-control">
        <label class="label">
          <span class="label-text text-gray-700">Filter by User Type</span>
        </label>
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

      <!-- Department Filter (for students) -->
      <div v-if="selectedUserType === 'student'" class="form-control">
        <label class="label">
          <span class="label-text text-gray-700">Filter by Department</span>
        </label>
        <select 
          v-model="selectedDepartment" 
          class="select select-bordered bg-gray-50"
          @change="handleFiltersChange"
        >
          <option value="">All Departments</option>
          <option 
            v-for="dept in departments" 
            :key="dept" 
            :value="dept"
          >
            {{ dept }}
          </option>
        </select>
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
          @click="statusFilter = filter.value"
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

const appointmentStore = useAppointmentStore()
const authStore = useAuthStore()
const showDrawer = ref(false)
const selectedAppointment = ref({})
const statusFilter = ref('upcoming')
const counts = ref({
  upcoming: 0,
  history: 0
})

const selectedUserType = ref('all')
const selectedDepartment = ref('')
const departments = ref([])

const isStudent = computed(() => authStore.user?.user_type === 'student')
const isCounselor = computed(() => authStore.user?.user_type === 'counselor')

const statusFilters = [
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

onMounted(async () => {
  try {
    const response = await http.get('/api/appointments/departments')
    departments.value = response.data
  } catch (error) {
    console.error('Failed to fetch departments:', error)
  }
})

async function fetchAppointments(page = 1) {
  try {
    const filters = {
      page,
      status: statusFilter.value
    }

    if (isCounselor.value) {
      if (selectedUserType.value !== 'all') {
        filters.userType = selectedUserType.value
      }
      if (selectedDepartment.value) {
        filters.department = selectedDepartment.value
      }
    }

    await Promise.all([
      appointmentStore.fetchAppointments(filters),
      fetchCounts()
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
    await appointmentStore.updateAppointmentStatus(appointment.id, newStatus)
    await fetchCounts()
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
    appointment.status === 'confirmed' &&
    new Date(appointment.appointment_date) <= new Date()
}

const canEditAppointment = (appointment) => {
  if (!canManageAppointments.value) {
    return appointment.status === 'pending' && appointment.student_id === authStore.user?.id
  }
  return canManageAppointments.value && ['pending', 'confirmed'].includes(appointment.status)
}

async function fetchCounts() {
  try {
    const response = await http.get('/api/appointments/counts')
    counts.value = response.data
  } catch (error) {
    console.error('Failed to fetch counts:', error)
  }
}

function handleFiltersChange() {
  fetchAppointments(1)
}

watch([selectedUserType, selectedDepartment], () => {
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