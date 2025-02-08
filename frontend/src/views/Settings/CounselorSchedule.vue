<template>
  <div class="p-4">
    <h2 class="text-xl font-bold mb-6">Counselor Schedule Settings</h2>
    
    <div v-if="error" class="alert alert-error mb-4">
      {{ error }}
    </div>

    <!-- Mobile Tabs -->
    <div class="grid grid-cols-1 sm:hidden mb-6">
      <select 
        v-model="activeTab"
        aria-label="Select a tab" 
        class="col-start-1 row-start-1 w-full appearance-none rounded-md bg-white py-2 pl-3 pr-8 text-base text-gray-900 outline outline-1 -outline-offset-1 outline-gray-300 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-primary"
      >
        <option value="schedule">Weekly Schedule</option>
        <option value="excluded">Excluded Dates</option>
      </select>
      <svg 
        class="pointer-events-none col-start-1 row-start-1 mr-2 size-5 self-center justify-self-end fill-gray-500" 
        viewBox="0 0 16 16" 
        fill="currentColor" 
        aria-hidden="true"
      >
        <path fill-rule="evenodd" d="M4.22 6.22a.75.75 0 0 1 1.06 0L8 8.94l2.72-2.72a.75.75 0 1 1 1.06 1.06l-3.25 3.25a.75.75 0 0 1-1.06 0L4.22 7.28a.75.75 0 0 1 0-1.06Z" clip-rule="evenodd" />
      </svg>
    </div>

    <!-- Desktop Tabs -->
    <div class="hidden sm:block mb-6">
      <div class="border-b border-gray-200">
        <nav class="-mb-px flex space-x-8" aria-label="Tabs">
          <a 
            href="#"
            @click.prevent="activeTab = 'schedule'"
            :class="[
              activeTab === 'schedule'
                ? 'border-primary text-primary'
                : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700',
              'group inline-flex items-center border-b-2 px-1 py-4 text-sm font-medium'
            ]"
          >
            <CalendarIcon 
              class="-ml-0.5 mr-2 size-5"
              :class="[
                activeTab === 'schedule'
                  ? 'text-primary'
                  : 'text-gray-400 group-hover:text-gray-500'
              ]"
            />
            <span>Weekly Schedule</span>
          </a>

          <a 
            href="#"
            @click.prevent="activeTab = 'excluded'"
            :class="[
              activeTab === 'excluded'
                ? 'border-primary text-primary'
                : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700',
              'group inline-flex items-center border-b-2 px-1 py-4 text-sm font-medium'
            ]"
          >
            <NoSymbolIcon 
              class="-ml-0.5 mr-2 size-5"
              :class="[
                activeTab === 'excluded'
                  ? 'text-primary'
                  : 'text-gray-400 group-hover:text-gray-500'
              ]"
            />
            <span>Excluded Dates</span>
          </a>
        </nav>
      </div>
    </div>

    <!-- Tab Panels -->
    <div class="mt-6">
      <!-- Weekly Schedule Panel -->
      <div v-show="activeTab === 'schedule'">
        <div class="grid md:grid-cols-2 gap-4">
          <div v-for="day in weekDays" :key="day" class="card bg-base-100 shadow-sm">
            <div class="card-body p-4">
              <div class="flex items-center justify-between mb-4">
                <h4 class="text-lg font-medium capitalize">{{ day }}</h4>
                <input 
                  type="checkbox" 
                  class="toggle toggle-primary"
                  v-model="schedule[day].is_available"
                />
              </div>
              
              <div v-if="schedule[day].is_available">
                <!-- Working Hours -->
                <div class="grid grid-cols-2 gap-4 mb-4">
                  <div class="form-control">
                    <label class="label">Start Time</label>
                    <input 
                      type="time" 
                      class="input input-bordered"
                      v-model="schedule[day].start_time"
                    />
                  </div>
                  <div class="form-control">
                    <label class="label">End Time</label>
                    <input 
                      type="time" 
                      class="input input-bordered"
                      v-model="schedule[day].end_time"
                    />
                  </div>
                </div>
                
                <!-- Break Time -->
                <div class="grid grid-cols-2 gap-4">
                  <div class="form-control">
                    <label class="label">Break Start</label>
                    <input 
                      type="time" 
                      class="input input-bordered"
                      v-model="schedule[day].break_start"
                    />
                  </div>
                  <div class="form-control">
                    <label class="label">Break End</label>
                    <input 
                      type="time" 
                      class="input input-bordered"
                      v-model="schedule[day].break_end"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Save Schedule Button -->
        <div class="flex justify-end mt-6">
          <button 
            class="btn btn-primary"
            :disabled="isLoading"
            @click="saveSchedule"
          >
            {{ isLoading ? 'Saving...' : 'Save Schedule' }}
          </button>
        </div>
      </div>

      <!-- Excluded Dates Panel -->
      <div v-show="activeTab === 'excluded'">
        <div class="flex justify-between items-center mb-6">
          <h3 class="text-lg font-semibold">Excluded Dates</h3>
          <button class="btn btn-primary" @click="openAddDateModal">
            Add Date
          </button>
        </div>

        <!-- Existing Excluded Dates -->
        <div v-if="existingExcludedDates.length > 0">
          <div class="card bg-base-100 shadow-sm">
            <div class="card-body p-4">
              <div class="overflow-x-auto">
                <table class="table">
                  <thead>
                    <tr>
                      <th>Date</th>
                      <th>Reason</th>
                      <th class="w-16"></th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="date in existingExcludedDates" :key="date.id">
                      <td>{{ formatDate(date.excluded_date) }}</td>
                      <td>{{ date.reason || '-' }}</td>
                      <td class="text-right">
                        <button 
                          class="btn btn-ghost btn-sm"
                          @click="deleteExcludedDate(date.id)"
                        >
                          <TrashIcon class="h-5 w-5" />
                        </button>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
        <div v-else class="text-center text-gray-500 py-8">
          No excluded dates found
        </div>
      </div>
    </div>
  </div>

  <!-- Add Date Modal -->
  <dialog id="add_date_modal" class="modal">
    <div class="modal-box">
      <h3 class="font-bold text-lg mb-4">Add Excluded Date</h3>
      
      <form @submit.prevent="saveNewDate">
        <div class="form-control w-full">
          <label class="label">
            <span class="label-text">Date</span>
          </label>
          <input 
            type="date" 
            class="input input-bordered w-full"
            v-model="newDate.date"
            :min="today"
            required
          />
        </div>

        <div class="form-control w-full mt-4">
          <label class="label">
            <span class="label-text">Reason</span>
          </label>
          <input 
            type="text" 
            class="input input-bordered w-full"
            v-model="newDate.reason"
            placeholder="Optional reason"
          />
        </div>

        <div class="modal-action">
          <button 
            type="button" 
            class="btn" 
            @click="closeAddDateModal"
          >
            Cancel
          </button>
          <button 
            type="submit" 
            class="btn btn-primary"
            :disabled="isLoading"
          >
            {{ isLoading ? 'Saving...' : 'Save' }}
          </button>
        </div>
      </form>
    </div>
    <form method="dialog" class="modal-backdrop">
      <button>close</button>
    </form>
  </dialog>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { TrashIcon, CalendarIcon, NoSymbolIcon } from '@heroicons/vue/24/outline'
import { useCounselorScheduleStore } from '@/stores/counselorSchedule'
import { storeToRefs } from 'pinia'
import { swalHelper } from '@/utils/swalHelper'
import { format } from 'date-fns'

const store = useCounselorScheduleStore()
const { schedule, isLoading, error } = storeToRefs(store)

const weekDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
const today = new Date().toISOString().split('T')[0]
const activeTab = ref('schedule')
const newDate = ref({ date: '', reason: '' })

const existingExcludedDates = computed(() => store.getExcludedDates)

const openAddDateModal = () => {
  newDate.value = { date: '', reason: '' }
  document.getElementById('add_date_modal').showModal()
}

const closeAddDateModal = () => {
  document.getElementById('add_date_modal').close()
}

const saveNewDate = async () => {
  try {
    // Create array with only the new date
    const dates = [{
      date: newDate.value.date,
      reason: newDate.value.reason
    }]
    
    await store.updateExcludedDates(dates)
    swalHelper.toast('success', 'Date added successfully')
    closeAddDateModal()
  } catch (error) {
    console.error('Failed to add excluded date:', error)
  }
}

const saveSchedule = async () => {
  try {
    await store.updateSchedule(schedule.value)
    swalHelper.toast('success', 'Schedule updated successfully')
  } catch (error) {
    console.error('Failed to save schedule:', error)
  }
}

const formatDate = (date) => {
  return format(new Date(date), 'MMM dd, yyyy')
}

const deleteExcludedDate = async (id) => {
  try {
    await store.deleteExcludedDate(id)
    swalHelper.toast('success', 'Date removed successfully')
  } catch (error) {
    console.error('Failed to delete excluded date:', error)
  }
}

onMounted(() => {
  store.fetchSchedule()
})
</script> 