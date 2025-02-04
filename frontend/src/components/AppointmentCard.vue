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
            <div class="flex items-center gap-2 text-sm text-gray-600">
              <ClockIcon class="h-4 w-4" />
              {{ formatLocalDate(appointment.appointment_date, 'h:mm a') }}
            </div>
          </div>

          <!-- Location and Participant - Second Line -->
          <div class="flex items-center gap-4 mt-1 text-sm text-gray-600">
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
          </div>
        </div>
      </div>

      <!-- Right: Status and Actions -->
      <div class="flex items-center gap-3">
        <span 
          :class="[
            'badge',
            statusClass,
            'capitalize'
          ]"
        >
          {{ appointment.status }}
        </span>

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
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { parseISO } from 'date-fns'
import { formatInTimeZone } from 'date-fns-tz'
import { useAuthStore } from '@/stores/auth'
import { 
  UserIcon, 
  ClockIcon,
  MapPinIcon,
  ClipboardDocumentListIcon, 
  ChatBubbleLeftIcon,
  EllipsisVerticalIcon,
  PencilIcon
} from '@heroicons/vue/24/outline'

const props = defineProps({
  appointment: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['edit', 'update-status'])
const authStore = useAuthStore()

const isStudent = computed(() => authStore.user?.user_type === 'student')
const isCounselor = computed(() => authStore.user?.user_type === 'counselor')

const statusClass = computed(() => {
  switch (props.appointment.status) {
    case 'pending': return 'badge-warning'
    case 'confirmed': return 'badge-success'
    case 'cancelled': return 'badge-error'
    case 'completed': return 'badge-info'
    default: return 'badge-ghost'
  }
})

const canUpdateStatus = computed(() => {
  if (!isCounselor.value) return false
  return ['pending', 'confirmed'].includes(props.appointment.status)
})

const canEdit = computed(() => {
  if (props.appointment.status !== 'pending') return false
  return isStudent.value || isCounselor.value
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