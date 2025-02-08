<template>
  <div class="bg-white rounded-lg p-4 shadow-sm hover:shadow-md transition-shadow">
    <div class="flex items-center justify-between">
      <!-- Left: Date and Details -->
      <div class="flex items-center gap-4">
        <!-- Date Display -->
        <div class="text-center min-w-[50px]">
          <div class="text-error text-sm font-medium">
            {{ formatLocalDate(appointment.appointment_date, 'EEE') }}
          </div>
          <div class="text-3xl font-bold leading-none mt-1">
            {{ formatLocalDate(appointment.appointment_date, 'dd') }}
          </div>
        </div>

        <!-- Details -->
        <div>
          <!-- Title and Time - First Line -->
          <div class="flex items-center gap-4">
            <span class="font-medium">{{ appointment.reason }}</span>
          </div>

          <!-- Location and Participant - Second Line -->
          <div class="flex items-center gap-4 mt-1 text-sm text-gray-600">
            <div class="flex items-center gap-2 text-sm text-gray-600">
              <ClockIcon class="h-4 w-4" />
              {{ formatLocalDate(appointment.appointment_date, 'h:mm a') }}
            </div>
            <div class="flex items-center gap-2">
              <MapPinIcon class="h-4 w-4" />
              {{ appointment.location_type === 'online' ? 'Online' : appointment.location }}
            </div>
            <div class="flex items-center gap-2">
              <div class="avatar placeholder">
                <div class="bg-neutral-focus text-neutral-content w-6 h-6 rounded-full">
                  <span class="text-xs">
                    {{ getInitials(isStudent ? appointment.counselor?.name : appointment.student?.name) }}
                  </span>
                </div>
              </div>
              {{ isStudent ? appointment.counselor?.name : appointment.student?.name }}
            </div>
            <span 
          :class="[
            'badge text-white',
            statusClass,
            'capitalize'
          ]"
        >
          {{ appointment.status }}
        </span>
          </div>
        </div>
      </div>

      <!-- Right: Status and Actions -->
      <div class="flex items-center gap-3">
        <div class="flex gap-2">
          <div class="dropdown dropdown-end" v-if="canUpdateStatus">
            <label tabindex="0" class="btn btn-sm btn-ghost">
              <EllipsisVerticalIcon class="h-5 w-5" />
            </label>
            <ul tabindex="0" class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52">
              <li v-for="status in availableStatuses" :key="status">
                <a @click="$emit('update-status', appointment, status)">
                  {{ status }}
                </a>
              </li>
            </ul>
          </div>
          <button 
            v-if="canEdit"
            class="btn btn-ghost btn-sm"
            @click="$emit('edit', appointment)"
          >
            <PencilIcon class="h-4 w-4" />
          </button>
          <slot name="actions"></slot>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { formatInTimeZone } from 'date-fns-tz'
import { parseISO } from 'date-fns'
import { 
  MapPinIcon, 
  ClockIcon, 
  UserIcon,
  EllipsisVerticalIcon,
  PencilIcon
} from '@heroicons/vue/24/outline'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const props = defineProps({
  appointment: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['edit', 'update-status'])

const isStudent = computed(() => authStore.user?.user_type === 'student')
const isCounselor = computed(() => authStore.user?.user_type === 'counselor')

const canManageAppointments = computed(() => {
  return authStore.user?.permissions?.includes('manage appointments')
})

const statusClass = computed(() => {
  const classes = {
    pending: 'badge-warning',
    confirmed: 'badge-success',
    completed: 'badge-info',
    cancelled: 'badge-error'
  }
  return classes[props.appointment.status] || 'badge-ghost'
})

const canUpdateStatus = computed(() => {
  if (!isCounselor.value) return false
  return ['pending', 'confirmed'].includes(props.appointment.status)
})

const canEdit = computed(() => {
  if (props.appointment.status !== 'pending') return false
  return isStudent.value || isCounselor.value
})

const canCompleteAppointment = computed(() => {
  return canManageAppointments.value && 
    props.appointment.status === 'confirmed'
})

const availableStatuses = computed(() => {
  const statuses = []
  if (props.appointment.status === 'pending') {
    statuses.push('confirmed', 'cancelled')
  }
  if (props.appointment.status === 'confirmed') {
    statuses.push('completed', 'cancelled')
  }
  return statuses
})

function formatLocalDate(date, formatStr) {
  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone
  return formatInTimeZone(parseISO(date), timezone, formatStr)
}

function getInitials(name) {
  if (!name) return '??'
  return name
    .split(' ')
    .map(word => word[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
}
</script>

<style scoped>
.badge {
  @apply px-3 py-1;
}
</style> 