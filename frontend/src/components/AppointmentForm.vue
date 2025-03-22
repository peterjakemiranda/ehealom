<template>
  <div class="space-y-4">
    <form @submit.prevent="onSubmit" class="card bg-white p-4">
      <!-- Counselor Selection -->
      <div class="form-control mb-4" v-if="showCounselorSelection && !isCounselor">
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

      <!-- Student Selection (for counselors) -->
      <div v-if="isCounselor" class="form-control mb-4">
        <div class="flex items-center justify-between mb-2">
          <label class="label">
            <span class="label-text text-gray-700">Student</span>
          </label>
          <div v-if="!isEditing" class="form-control">
            <label class="label cursor-pointer">
              <span class="label-text mr-2">New Student</span>
              <input 
                type="checkbox" 
                class="toggle toggle-primary" 
                v-model="isNewStudent"
                @change="handleNewStudentToggle"
              />
            </label>
          </div>
        </div>

        <!-- Show student name when editing -->
        <div v-if="isEditing && appointment.student" class="text-gray-600">
          {{ appointment.student.name }}
        </div>

        <!-- New Student Form -->
        <div v-else-if="!isEditing && isNewStudent" class="space-y-4">
          <input
            type="text"
            v-model="newStudent.name"
            class="input input-bordered bg-gray-50"
            placeholder="Student Name"
            required
          />
          <input
            type="text"
            v-model="newStudent.idNumber"
            class="input input-bordered bg-gray-50"
            placeholder="Student ID Number"
            required
          />
          <input
            type="email"
            v-model="newStudent.email"
            class="input input-bordered bg-gray-50"
            placeholder="Student Email"
            required
          />
        </div>

        <!-- Existing Student Search -->
        <div v-else>
          <div class="relative">
            <input
              type="text"
              v-model="studentSearchQuery"
              class="input input-bordered bg-gray-50 w-full"
              placeholder="Search student by name or ID"
              @input="debounceSearch"
            />
            <div v-if="isSearching" class="absolute right-2 top-2">
              <span class="loading loading-spinner loading-sm"></span>
            </div>
          </div>

          <!-- Search Results -->
          <div v-if="studentSearchResults.length > 0" class="mt-2 max-h-48 overflow-y-auto border rounded-lg">
            <div
              v-for="student in studentSearchResults"
              :key="student.id"
              class="p-2 hover:bg-gray-100 cursor-pointer"
              @click="selectStudent(student)"
            >
              {{ student.name }} ({{ student.student_id || 'No ID' }})
            </div>
          </div>
        </div>
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
      <div v-if="canUpdateStatus && isEditing" class="form-control mb-4">
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

      <!-- Category -->
      <div class="form-control mb-4">
        <label class="label">
          <span class="label-text text-gray-700">Category</span>
        </label>
        <select 
          v-model="formData.category_id" 
          class="select select-bordered bg-gray-50"
          required
        >
          <option value="">Select a category</option>
          <option 
            v-for="category in categories" 
            :key="category.id" 
            :value="category.id"
          >
            {{ category.title }}
          </option>
        </select>
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
import { useCategoryStore } from '@/stores/categoryStore'
import { format, parseISO } from 'date-fns'
import { formatInTimeZone } from 'date-fns-tz'
import http from '@/utils/http'
import swalHelper from '@/utils/swalHelper'
import { debounce } from 'lodash'

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
const categoryStore = useCategoryStore()
const isLoading = ref(false)
const counselors = ref([])
const categories = ref([])
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
  return !canManageAppointments.value || 
         (authStore.user?.permissions?.includes('manage users') && !isCounselor.value)
})

const availableSlots = computed(() => {
  return appointmentStore.availableSlots || []
})

const formData = ref({
  uuid: props.appointment.uuid || null,
  counselor_id: props.appointment.counselor_id || (isCounselor.value ? authStore.user?.user?.id : ''),
  appointment_date: props.appointment.appointment_date || '',
  reason: props.appointment.reason || '',
  category_id: props.appointment.category_id || '',
  status: props.appointment.status || 'pending',
  location_type: props.appointment.location_type || 'online',
  location: props.appointment.location || '',
  student_id: props.appointment.student?.id || null
})

const isNewStudent = ref(false)
const studentSearchQuery = ref('')
const studentSearchResults = ref([])
const isSearching = ref(false)
const selectedStudent = ref(null)
const newStudent = ref({
  name: '',
  idNumber: '',
  email: ''
})

// Get counselors from userStore
onMounted(async () => {
  try {
    console.log('Component mounted, initial state:', {
      isCounselor: isCounselor.value,
      currentUserId: authStore.user?.user?.id,
      appointment: props.appointment
    })

    // Fetch both counselors and categories
    const [counselorsData, categoriesData] = await Promise.all([
      userStore.fetchCounselors(),
      categoryStore.fetchCategories()
    ])
    
    counselors.value = counselorsData
    categories.value = categoriesData
    
    // If editing, set initial values
    if (props.appointment?.counselor_id && props.appointment?.appointment_date) {
      console.log('Editing existing appointment')
      formData.value.counselor_id = props.appointment.counselor_id
      const appointmentDate = parseISO(props.appointment.appointment_date)
      
      // Set date and time from appointment
      selectedDate.value = format(appointmentDate, 'yyyy-MM-dd')
      selectedTime.value = format(appointmentDate, 'HH:mm')
      formData.value.appointment_date = props.appointment.appointment_date

      // Set selected student if editing
      if (props.appointment.student) {
        selectedStudent.value = props.appointment.student
      }
      
      await loadAvailableSlots()
    } else if (isCounselor.value) {
      // Set counselor_id to current user for new appointments
      console.log('Setting counselor_id for new appointment')
      formData.value.counselor_id = authStore.user?.user?.id
      console.log('Updated formData:', formData.value)
    }
  } catch (error) {
    console.error('Failed to fetch data:', error)
    swalHelper.toast('error', 'Failed to load form data')
  }
})

// Update watch handler to preserve counselor_id and set student_id
watch(() => props.appointment, (newVal) => {
  if (newVal) {
    const currentCounselorId = formData.value.counselor_id
    formData.value = { 
      ...formData.value, 
      ...newVal,
      counselor_id: newVal.counselor_id || currentCounselorId,
      student_id: newVal.student?.id || null
    }
    
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

// Debounced search function
const debounceSearch = debounce(async () => {
  if (studentSearchQuery.value.length < 2) {
    studentSearchResults.value = []
    return
  }

  isSearching.value = true
  try {
    const response = await http.get('/api/users/search', {
      params: { 
        query: studentSearchQuery.value,
        role: 'student'
      }
    })
    
    if (response.data && Array.isArray(response.data)) {
      studentSearchResults.value = response.data
    } else {
      console.error('Invalid response format:', response.data)
      studentSearchResults.value = []
    }
  } catch (error) {
    console.error('Failed to search students:', error)
    studentSearchResults.value = []
    if (error.response?.status === 404) {
      swalHelper.toast('info', 'No students found')
    } else {
      swalHelper.toast('error', 'Failed to search students')
    }
  } finally {
    isSearching.value = false
  }
}, 300)

function handleNewStudentToggle() {
  if (isNewStudent.value) {
    selectedStudent.value = null
    studentSearchQuery.value = ''
    studentSearchResults.value = []
  } else {
    newStudent.value = {
      name: '',
      idNumber: '',
      email: ''
    }
  }
}

function selectStudent(student) {
  selectedStudent.value = student
  studentSearchQuery.value = student.name
  studentSearchResults.value = []
}

// Update form validation
const isValidForm = computed(() => {
  if (isEditing.value && !canEditDateTime.value) {
    return true
  }

  // Add student validation for counselors
  if (isCounselor.value) {
    if (isNewStudent.value) {
      return formData.value.counselor_id && 
             selectedDate.value && 
             (selectedTime.value || formData.value.appointment_date) && 
             formData.value.reason &&
             formData.value.category_id &&
             newStudent.value.name &&
             newStudent.value.idNumber &&
             newStudent.value.email
    } else {
      return formData.value.counselor_id && 
             selectedDate.value && 
             (selectedTime.value || formData.value.appointment_date) && 
             formData.value.reason &&
             formData.value.category_id &&
             (selectedStudent.value || formData.value.student_id)
    }
  }

  return formData.value.counselor_id && 
         selectedDate.value && 
         (selectedTime.value || formData.value.appointment_date) && 
         formData.value.reason &&
         formData.value.category_id 
})

async function loadAvailableSlots() {
  console.log('loadAvailableSlots called with:', {
    counselorId: formData.value.counselor_id,
    selectedDate: selectedDate.value,
    isCounselor: isCounselor.value,
    currentUserId: authStore.user?.user?.id,
    showTimeSlots: showTimeSlots.value
  })

  if (!formData.value.counselor_id || !selectedDate.value) {
    console.log('Missing required data:', { 
      counselorId: formData.value.counselor_id, 
      date: selectedDate.value,
      isCounselor: isCounselor.value,
      currentUserId: authStore.user?.user?.id,
      formData: formData.value
    })
    return
  }
  
  isLoadingSlots.value = true
  timeSlots.value = []
  
  try {
    const params = {
      counselor_id: formData.value.counselor_id,
      date: selectedDate.value
    }
    console.log('Fetching slots with params:', params)

    const response = await http.get('/api/appointments/available-slots', { params })
    console.log('API Response:', response)

    if (response && response.data) {
      timeSlots.value = response.data.slots || []
      console.log('Updated timeSlots:', timeSlots.value)
      
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
    console.error('Error response:', error.response?.data)
    timeSlots.value = []
    swalHelper.toast('error', 'Failed to load available time slots')
  } finally {
    isLoadingSlots.value = false
  }
}

// Update watch for selectedDate to use the same logic
watch(selectedDate, (newDate) => {
  console.log('selectedDate changed:', newDate)
  console.log('Current formData:', formData.value)
  if (newDate && formData.value.counselor_id) {
    loadAvailableSlots()
  }
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

// Add reset function
function resetForm() {
  formData.value = {
    uuid: null,
    counselor_id: isCounselor.value ? authStore.user?.user?.id : '',
    appointment_date: '',
    reason: '',
    category_id: '',
    status: 'pending',
    location_type: 'online',
    location: '',
    student_id: null
  }
  
  selectedDate.value = ''
  selectedTime.value = ''
  timeSlots.value = []
  
  // Reset student-related fields
  isNewStudent.value = false
  studentSearchQuery.value = ''
  studentSearchResults.value = []
  selectedStudent.value = null
  newStudent.value = {
    name: '',
    idNumber: '',
    email: ''
  }
}

// Update onSubmit function
async function onSubmit() {
  try {
    isLoading.value = true
    const appointmentData = { ...formData.value }

    // Add student data for counselors
    if (isCounselor.value) {
      if (isNewStudent.value) {
        // Format new student data according to API expectations
        appointmentData.student_name = newStudent.value.name
        appointmentData.student_id_number = newStudent.value.idNumber
        appointmentData.student_email = newStudent.value.email
      } else {
        // Use either selectedStudent or existing student_id
        appointmentData.student_id = selectedStudent.value?.id || formData.value.student_id
      }
    }

    await emit('save', appointmentData)
    
    // Reset form after successful submission
    if (!isEditing.value) {
      resetForm()
    }
  } finally {
    isLoading.value = false
  }
}

// Add watch for props.appointment to reset form when it changes
watch(() => props.appointment, (newVal) => {
  if (!newVal?.id) {
    resetForm()
  }
}, { immediate: true })
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