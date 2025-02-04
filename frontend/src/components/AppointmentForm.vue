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
        <div class="grid grid-cols-4 gap-2">
          <button
            v-for="slot in timeSlots"
            :key="slot.time"
            type="button"
            class="btn btn-sm w-full"
            :class="[
              selectedTime === slot.time ? 'btn-primary' : 'btn-outline',
              { 'btn-disabled': !slot.available && selectedTime !== slot.time }
            ]"
            @click="selectTimeSlot(slot.time)"
            :disabled="!canEditDateTime || (!slot.available && selectedTime !== slot.time)"
          >
            {{ slot.display_time }}
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
import { format, parseISO } from 'date-fns'
import { formatInTimeZone } from 'date-fns-tz'
import http from '@/utils/http'

const props = defineProps({
  appointment: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['save', 'cancel'])
const userStore = useUserStore()
const authStore = useAuthStore()
const isLoading = ref(false)
const counselors = ref([])
const timeSlots = ref([])
const selectedDate = ref('')
const selectedTime = ref('')

const isCounselor = computed(() => authStore.user?.roles.includes('counselor'))
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
      selectedDate.value = format(parseISO(newVal.appointment_date), 'yyyy-MM-dd')
      selectedTime.value = format(parseISO(newVal.appointment_date), 'HH:mm')
      
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
  if (!formData.value.counselor_id || !selectedDate.value) return
  
  try {
    isLoading.value = true
    
    const response = await http.get('/api/appointments/available-slots', {
      params: {
        counselor_id: formData.value.counselor_id,
        date: selectedDate.value,
        current_appointment_id: isEditing.value ? props.appointment.id : null
      }
    })
    timeSlots.value = response.data.data.slots

    // If editing, handle time slot preselection
    if (isEditing.value && props.appointment.appointment_date) {
      const appointmentDate = parseISO(props.appointment.appointment_date)
      const selectedDateObj = parseISO(selectedDate.value)
      
      // Only preselect if we're on the same date
      if (format(appointmentDate, 'yyyy-MM-dd') === format(selectedDateObj, 'yyyy-MM-dd')) {
        selectedTime.value = format(appointmentDate, 'HH:mm')
        formData.value.appointment_date = props.appointment.appointment_date
      } else {
        // Clear selection if date is different
        selectedTime.value = ''
        formData.value.appointment_date = ''
      }
    }
  } catch (error) {
    console.error('Failed to load time slots:', error)
    timeSlots.value = []
  } finally {
    isLoading.value = false
  }
}

// Update watch for selectedDate to use the same logic
watch(selectedDate, () => {
  loadAvailableSlots()
})

function selectTimeSlot(time) {
  selectedTime.value = time
  const localDateTime = `${selectedDate.value}T${time}`
  
  // Convert local time to UTC for storage using formatInTimeZone
  formData.value.appointment_date = formatInTimeZone(
    new Date(localDateTime),
    'UTC',
    "yyyy-MM-dd'T'HH:mm:ssXXX"
  )
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