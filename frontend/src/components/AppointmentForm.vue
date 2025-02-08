<template>
  <div class="space-y-4">
    <form @submit.prevent="onSubmit" class="card bg-white p-4">
      <!-- Counselor Selection -->
      <div class="form-control mb-4" v-if="showCounselorSelection">
        <label class="label">
          <span class="label-text text-gray-700">Select Counselor</span>
        </label>
        <select 
          v-model="formData.counselor_id" 
          class="select select-bordered bg-gray-50" 
          required
          @change="loadAvailableSlots"
        >
          <option value="">Select a counselor</option>
          <option 
            v-for="counselor in counselors" 
            :key="counselor.id" 
            :value="counselor.id"
          >
            {{ counselor.name }}
          </option>
        </select>
      </div>

      <!-- Date Selection -->
      <div class="form-control mb-4">
        <label class="label">
          <span class="label-text text-gray-700">Select Date</span>
        </label>
        <input
          type="date"
          v-model="selectedDate"
          class="input input-bordered bg-gray-50"
          :min="minDate"
          required
          @change="loadAvailableSlots"
          :disabled="!canEditDateTime"
        />
      </div>

      <!-- Time Slots -->
      <div v-if="showTimeSlots" class="form-control mb-4">
        <label class="label">
          <span class="label-text text-gray-700">Available Time Slots</span>
        </label>
        
        <div v-if="isLoadingSlots" class="flex justify-center py-4">
          <span class="loading loading-spinner loading-md"></span>
        </div>
        
        <div v-else-if="!timeSlots.length" class="text-sm text-gray-500 py-2">
          No available time slots for this date
        </div>
        
        <div v-else class="grid grid-cols-3 gap-2">
          <button
            v-for="slot in timeSlots"
            :key="slot"
            type="button"
            :class="[
              'btn btn-sm',
              selectedTime === slot ? 'btn-primary' : 'btn-outline'
            ]"
            @click="selectedTime = slot"
          >
            {{ formatTime(slot) }}
          </button>
        </div>
      </div>

      <!-- Current Time (when editing and can't change) -->
      <div v-else-if="formData.appointment_date" class="form-control mb-4">
        <label class="label">
          <span class="label-text text-gray-700">Appointment Time</span>
        </label>
        <div class="text-gray-600">
          {{ format(parseISO(formData.appointment_date), 'MMMM d, yyyy h:mm a') }}
        </div>
      </div>

      <!-- Status Selection (for counselor) -->
      <div v-if="canUpdateStatus" class="form-control mb-4">
        <label class="label">
          <span class="label-text text-gray-700">Status</span>
        </label>
        <select v-model="formData.status" class="select select-bordered bg-gray-50">
          <option v-for="status in availableStatuses" :key="status" :value="status">
            {{ status }}
          </option>
        </select>
      </div>

      <!-- Reason for Appointment -->
      <div class="form-control mb-4">
        <label class="label">
          <span class="label-text text-gray-700">Reason for Appointment</span>
        </label>
        <textarea
          v-model="formData.reason"
          class="textarea textarea-bordered bg-gray-50"
          rows="3"
          required
        ></textarea>
      </div>

      <!-- Notes (for counselor) -->
      <div v-if="isCounselor" class="form-control mb-4">
        <label class="label">
          <span class="label-text text-gray-700">Notes</span>
        </label>
        <textarea
          v-model="formData.notes"
          class="textarea textarea-bordered bg-gray-50"
          rows="3"
        ></textarea>
      </div>

      <!-- Location Type -->
      <div class="form-control mb-4">
        <label class="label">
          <span class="label-text text-gray-700">Location Type</span>
        </label>
        <select 
          v-model="formData.location_type" 
          class="select select-bordered bg-gray-50"
          required
        >
          <option value="online">Online</option>
          <option value="on-site">On-site</option>
        </select>
      </div>

      <!-- Location -->
      <div v-if="formData.location_type === 'on-site'" class="form-control mb-4">
        <label class="label">
          <span class="label-text text-gray-700">Location</span>
        </label>
        <input
          type="text"
          v-model="formData.location"
          class="input input-bordered bg-gray-50"
          placeholder="Enter location details"
          required
        />
      </div>

      <div class="mt-6 flex gap-4">
        <button type="button" class="btn btn-ghost w-1/2" @click="$emit('cancel')">
          Cancel
        </button>
        <button type="submit" class="btn btn-primary w-1/2" :disabled="isLoading || !isValidForm">
          {{ isEditing ? 'Update' : 'Book' }} Appointment
        </button>
      </div>
    </form>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useUserStore } from '@/stores/userStore'
import { useAuthStore } from '@/stores/auth'
import { useAppointmentStore } from '@/stores/appointmentStore'
import { format, parseISO } from 'date-fns'
import { formatInTimeZone } from 'date-fns-tz'
import http from '@/utils/http'
import swalHelper from '@/utils/swalHelper'

const props = defineProps({
  appointment: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['save', 'cancel'])
const userStore = useUserStore()
const authStore = useAuthStore()
const appointmentStore = useAppointmentStore()
const isLoading = ref(false)
const counselors = ref([])
const timeSlots = ref([])
const selectedDate = ref('')
const selectedTime = ref('')
const isLoadingSlots = ref(false)

const isCounselor = computed(() => {
  return authStore.user?.roles?.includes('counselor') || false
})

const isStudent = computed(() => {
  return authStore.user?.roles?.includes('student') || false
})

const isEditing = computed(() => !!props.appointment?.id)

const canManageAppointments = computed(() => {
  return authStore.user?.permissions?.includes('manage appointments')
})

const canEditDateTime = computed(() => {
  if (canManageAppointments.value) return true
  return !isEditing.value || props.appointment?.status === 'pending'
})

const showCounselorSelection = computed(() => {
  return !canManageAppointments.value || authStore.user?.permissions?.includes('manage users')
})

const availableSlots = computed(() => {
  return appointmentStore.availableSlots || []
})

const formData = ref({
  uuid: props.appointment.uuid || null,
  counselor_id: props.appointment.counselor_id || '',
  appointment_date: props.appointment.appointment_date || '',
  reason: props.appointment.reason || '',
  status: props.appointment.status || 'pending',
  notes: props.appointment.notes || '',
  location_type: props.appointment.location_type || 'online',
  location: props.appointment.location || ''
})

// Get counselors from userStore
onMounted(async () => {
  try {
    counselors.value = await userStore.fetchCounselors()
    
    // If editing, set initial values
    if (props.appointment?.counselor_id && props.appointment?.appointment_date) {
      formData.value.counselor_id = props.appointment.counselor_id
      const appointmentDate = parseISO(props.appointment.appointment_date)
      
      // Set date and time from appointment
      selectedDate.value = format(appointmentDate, 'yyyy-MM-dd')
      selectedTime.value = format(appointmentDate, 'HH:mm')
      formData.value.appointment_date = props.appointment.appointment_date
      
      await loadAvailableSlots()
    }
  } catch (error) {
    console.error('Failed to fetch counselors:', error)
  }
})

// Update watch handler to preserve counselor_id
watch(() => props.appointment, (newVal) => {
  if (newVal) {
    formData.value = { ...formData.value, ...newVal }
    
    if (newVal.appointment_date) {
      const appointmentDate = parseISO(newVal.appointment_date)
      selectedDate.value = format(appointmentDate, 'yyyy-MM-dd')
      selectedTime.value = format(appointmentDate, 'HH:mm')
      
      // Ensure we keep the original appointment date if we're not changing it
      formData.value.appointment_date = newVal.appointment_date
      
      if (newVal.counselor_id) {
        formData.value.counselor_id = newVal.counselor_id
        loadAvailableSlots()
      }
    }
  }
}, { immediate: true, deep: true })

const showTimeSlots = computed(() => {
  return formData.value.counselor_id && selectedDate.value && canEditDateTime.value
})

const canUpdateStatus = computed(() => {
  if (!isCounselor.value) return false
  return ['pending', 'confirmed'].includes(formData.value.status)
})

const availableStatuses = computed(() => {
  const statuses = []
  if (formData.value.status === 'pending') {
    statuses.push('pending', 'confirmed', 'cancelled')
  }
  if (formData.value.status === 'confirmed') {
    statuses.push('confirmed', 'completed', 'cancelled')
  }
  return statuses
})

const minDate = computed(() => {
  return format(new Date(), 'yyyy-MM-dd')
})

const isValidForm = computed(() => {
  if (isEditing.value && !canEditDateTime.value) {
    return true // No validation needed if can't edit date/time
  }
  return formData.value.counselor_id && 
         selectedDate.value && 
         (selectedTime.value || formData.value.appointment_date) && 
         formData.value.reason
})

async function loadAvailableSlots() {
  if (!formData.value.counselor_id || !selectedDate.value) {
    console.log('Missing required data:', { 
      counselorId: formData.value.counselor_id, 
      date: selectedDate.value 
    })
    return
  }
  
  isLoadingSlots.value = true
  timeSlots.value = []
  
  try {
    console.log('Fetching slots with:', {
      counselor_id: formData.value.counselor_id,
      date: selectedDate.value
    })

    const response = await http.get('/api/appointments/available-slots', {
      params: {
        counselor_id: formData.value.counselor_id,
        date: selectedDate.value
      }
    })

    console.log('API Response:', response) // Debug log

    if (response && response.data) {
      timeSlots.value = response.data.slots || []
      
      // Clear selected time if it's no longer available
      if (selectedTime.value && !timeSlots.value.includes(selectedTime.value)) {
        selectedTime.value = ''
      }
    } else {
      console.error('Invalid response structure:', response)
      timeSlots.value = []
    }
  } catch (error) {
    console.error('Failed to load time slots:', error)
    console.error('Error response:', error.response?.data) // Log the error response
    timeSlots.value = []
    swalHelper.toast('error', 'Failed to load available time slots')
  } finally {
    isLoadingSlots.value = false
  }
}

// Update watch for selectedDate to use the same logic
watch(selectedDate, () => {
  loadAvailableSlots()
})

// Update the selectTimeSlot function
function selectTimeSlot(time) {
  selectedTime.value = time
  const localDateTime = `${selectedDate.value}T${time}`
  
  try {
    // Create a new Date object in local timezone
    const localDate = new Date(localDateTime)
    
    // Format the date in ISO format with timezone offset
    formData.value.appointment_date = localDate.toISOString()
    
    console.log('Selected datetime:', {
      time,
      localDateTime,
      formattedDate: formData.value.appointment_date
    })
  } catch (error) {
    console.error('Error setting appointment date:', error)
  }
}

// Add a watch for selectedTime to update formData when time is selected
watch(selectedTime, (newTime) => {
  if (newTime && selectedDate.value) {
    selectTimeSlot(newTime)
  }
})

// Add this function to format the time
function formatTime(time) {
  if (!time) return ''
  
  try {
    // Parse the HH:mm time and format it to 12-hour format
    const [hours, minutes] = time.split(':')
    const date = new Date()
    date.setHours(parseInt(hours), parseInt(minutes))
    
    return new Intl.DateTimeFormat('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    }).format(date)
  } catch (error) {
    console.error('Error formatting time:', error)
    return time // Return original value if formatting fails
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
/* Add fixed height to buttons to ensure alignment */
.btn-sm {
  height: 2.5rem;
  min-height: 2.5rem;
  font-size: 0.875rem;
  line-height: 1.25rem;
  padding: 0 0.75rem;
}

/* Ensure text is centered */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  text-align: center;
}
</style> 