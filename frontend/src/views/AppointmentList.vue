<template>
  <div class="container mx-auto p-4">
    <!-- Header with Add Button -->
    <div class="flex justify-between items-center mb-6">
      <div>
        <h1 class="text-2xl font-bold">Appointments</h1>
        <p class="text-gray-600">See your scheduled events from your calendar events links.</p>
      </div>
      
      <!-- Add Appointment Button -->
      <button 
        v-if="isStudent"
        class="btn btn-primary"
        @click="createAppointment"
      >
        <PlusIcon class="h-5 w-5 mr-2" />
        Book Appointment
      </button>
    </div>

    <!-- Filters -->
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
          {{ filter.label }}
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
                  class="btn btn-success btn-sm"
                >
                  Confirm
                </button>
                <button 
                  v-if="canCompleteAppointment(appointment)"
                  @click="handleStatusUpdate(appointment, 'completed')"
                  class="btn btn-info btn-sm"
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
import { format, parseISO, startOfMonth } from 'date-fns'
import { useAppointmentStore } from '@/stores/appointmentStore'
import { useAuthStore } from '@/stores/auth'
import { PlusIcon } from '@heroicons/vue/24/outline'
import AppointmentCard from '@/components/AppointmentCard.vue'
import AppointmentForm from '@/components/AppointmentForm.vue'
import Drawer from '@/components/common/BaseDrawer.vue'
import { swalHelper } from '@/utils/swalHelper'

const appointmentStore = useAppointmentStore()
const authStore = useAuthStore()
const showDrawer = ref(false)
const selectedAppointment = ref({})
const statusFilter = ref('upcoming')

const isStudent = computed(() => authStore.user?.user_type === 'student')
const isCounselor = computed(() => authStore.user?.user_type === 'counselor')

const statusFilters = [
  { value: 'upcoming', label: 'Upcoming' },
  { value: 'pending', label: 'Pending' },
  { value: 'recurring', label: 'Recurring' },
  { value: 'past', label: 'Past' },
  { value: 'cancelled', label: 'Cancelled' }
]

const drawerTitle = computed(() => {
  return selectedAppointment.value?.id ? 'Edit Appointment' : 'Book Appointment'
})

const filteredAppointments = computed(() => {
  let appointments = appointmentStore.appointments

  switch (statusFilter.value) {
    case 'upcoming':
      return appointments.filter(apt => 
        ['confirmed', 'pending'].includes(apt.status) && 
        new Date(apt.appointment_date) >= new Date()
      )
    case 'pending':
      return appointments.filter(apt => apt.status === 'pending')
    case 'cancelled':
      return appointments.filter(apt => apt.status === 'cancelled')
    case 'past':
      return appointments.filter(apt => 
        ['confirmed', 'completed'].includes(apt.status) && 
        new Date(apt.appointment_date) < new Date()
      )
    default:
      return appointments
  }
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

async function fetchAppointments(page = 1) {
  try {
    await appointmentStore.fetchAppointments({
      page,
      status: statusFilter.value === 'upcoming' ? '' : statusFilter.value
    })
  } catch (error) {
    console.error('Failed to fetch appointments:', error)
  }
}

function createAppointment() {
  selectedAppointment.value = {
    uuid: null,
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
    if (selectedAppointment.value.id) {
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

function changePage(page) {
  fetchAppointments(page)
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const canManageAppointments = computed(() => {
  return authStore.user?.permissions?.includes('manage appointments')
})

const canViewAppointments = computed(() => {
  return authStore.user?.permissions?.includes('view appointments')
})

const canCancelAppointments = computed(() => {
  return authStore.user?.permissions?.includes('cancel appointments')
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