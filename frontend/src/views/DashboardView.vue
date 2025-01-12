<template>
  <div class="container mx-auto px-4 py-8">
    <!-- Header -->
    <div class="flex justify-between items-center mb-8">
      <h1 class="text-3xl font-bold text-gray-800">Dashboard</h1>
      <button
        class="bg-yellow-500 hover:bg-yellow-600 text-white font-bold py-2 px-4 rounded-full shadow-sm transition duration-300"
      >
        + Add New Tenant
      </button>
    </div>

    <!-- Summary Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
      <div class="bg-white rounded-xl shadow-sm p-6 flex flex-col">
        <h3 class="text-lg font-semibold text-gray-600 mb-2">Total Due</h3>
        <p class="text-3xl font-bold text-yellow-500">${{ totalDue.toLocaleString() }}</p>
        <div class="mt-4 flex items-center text-sm text-gray-500">
          <span class="font-medium">{{ dueTenants }}/{{ totalTenants }}</span>
          <span class="ml-2">Tenants</span>
        </div>
      </div>
      <div class="bg-white rounded-xl shadow-sm p-6 flex flex-col">
        <h3 class="text-lg font-semibold text-gray-600 mb-2">Collected</h3>
        <p class="text-3xl font-bold text-green-500">${{ collected.toLocaleString() }}</p>
        <div class="mt-4 flex items-center text-sm text-gray-500">
          <span class="font-medium">{{ paidTenants }}/{{ totalTenants }}</span>
          <span class="ml-2">Tenants</span>
        </div>
      </div>
      <div class="bg-white rounded-xl shadow-sm p-6 flex flex-col">
        <h3 class="text-lg font-semibold text-gray-600 mb-2">Pending</h3>
        <p class="text-3xl font-bold text-red-500">${{ pending.toLocaleString() }}</p>
        <div class="mt-4 flex items-center text-sm text-gray-500">
          <span class="font-medium">{{ pendingTenants }}/{{ totalTenants }}</span>
          <span class="ml-2">Tenants</span>
        </div>
      </div>
      <div class="bg-white rounded-xl shadow-sm p-6 flex flex-col">
        <h3 class="text-lg font-semibold text-gray-600 mb-2">Occupancy</h3>
        <p class="text-3xl font-bold text-blue-500">{{ occupancyRate }}%</p>
        <div class="mt-4 flex items-center text-sm text-gray-500">
          <span class="font-medium">{{ occupiedUnits }}/{{ totalUnits }}</span>
          <span class="ml-2">Units Occupied</span>
        </div>
      </div>
    </div>

    <!-- Main Content -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <!-- Left Column -->
      <div class="lg:col-span-2 space-y-8">
        <!-- Payment Reminder -->
        <div class="bg-yellow-100 rounded-xl shadow-sm p-6">
          <h3 class="text-xl font-bold text-yellow-800 mb-4">Payment Reminders</h3>
          <p class="text-yellow-700 mb-4">
            You have {{ pendingTenants }} tenants with pending payments.
          </p>
          <button
            class="bg-yellow-500 hover:bg-yellow-600 text-white font-bold py-2 px-4 rounded-full shadow transition duration-300"
          >
            Send Reminders
          </button>
        </div>

        <!-- Recent Activities -->
        <div class="bg-white rounded-xl shadow-sm p-6">
          <h3 class="text-xl font-bold text-gray-800 mb-4">Recent Activities</h3>
          <ul class="space-y-4">
            <li
              v-for="activity in recentActivities"
              :key="activity.id"
              class="flex items-center space-x-4"
            >
              <img :src="activity.avatar" :alt="activity.name" class="w-10 h-10 rounded-full" />
              <div>
                <p class="font-semibold text-gray-700">{{ activity.name }}</p>
                <p class="text-sm text-gray-500">{{ activity.action }}</p>
              </div>
              <span class="ml-auto text-sm text-gray-400">{{ activity.time }}</span>
            </li>
          </ul>
        </div>
      </div>

      <!-- Right Column -->
      <div class="space-y-8">
        <!-- Upcoming Lease Expirations -->
        <div class="bg-white rounded-xl shadow-sm p-6">
          <h3 class="text-xl font-bold text-gray-800 mb-4">Upcoming Lease Expirations</h3>
          <ul class="space-y-4">
            <li
              v-for="lease in upcomingLeaseExpirations"
              :key="lease.id"
              class="flex items-center justify-between"
            >
              <div>
                <p class="font-semibold text-gray-700">{{ lease.tenant }}</p>
                <p class="text-sm text-gray-500">{{ lease.unit }}</p>
              </div>
              <span
                :class="[
                  'px-2 py-1 rounded-full text-xs font-semibold',
                  lease.daysLeft <= 7 ? 'bg-red-100 text-red-800' : 'bg-yellow-100 text-yellow-800'
                ]"
              >
                {{ lease.daysLeft }} days left
              </span>
            </li>
          </ul>
        </div>

        <!-- Maintenance Requests -->
        <div class="bg-white rounded-xl shadow-sm p-6">
          <h3 class="text-xl font-bold text-gray-800 mb-4">Maintenance Requests</h3>
          <ul class="space-y-4">
            <li
              v-for="request in maintenanceRequests"
              :key="request.id"
              class="flex items-center justify-between"
            >
              <div>
                <p class="font-semibold text-gray-700">{{ request.title }}</p>
                <p class="text-sm text-gray-500">{{ request.tenant }} - {{ request.unit }}</p>
              </div>
              <span
                :class="[
                  'px-2 py-1 rounded-full text-xs font-semibold',
                  request.status === 'urgent'
                    ? 'bg-red-100 text-red-800'
                    : 'bg-blue-100 text-primary'
                ]"
              >
                {{ request.status }}
              </span>
            </li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import AuthenticatedLayout from '@/layouts/AuthenticatedLayout.vue'

// Dummy data (replace with real data from your API)
const totalDue = ref(25000)
const collected = ref(15000)
const pending = ref(10000)
const totalTenants = ref(200)
const dueTenants = ref(180)
const paidTenants = ref(110)
const pendingTenants = ref(70)
const occupancyRate = ref(85)
const totalUnits = ref(100)
const occupiedUnits = ref(85)

const recentActivities = ref([
  {
    id: 1,
    name: 'John Doe',
    action: 'Paid rent',
    time: '2h ago',
    avatar: 'https://i.pravatar.cc/150?img=1'
  },
  {
    id: 2,
    name: 'Jane Smith',
    action: 'Submitted maintenance request',
    time: '4h ago',
    avatar: 'https://i.pravatar.cc/150?img=2'
  },
  {
    id: 3,
    name: 'Bob Johnson',
    action: 'Signed new lease',
    time: '1d ago',
    avatar: 'https://i.pravatar.cc/150?img=3'
  }
])

const upcomingLeaseExpirations = ref([
  { id: 1, tenant: 'Alice Cooper', unit: 'Apt 301', daysLeft: 5 },
  { id: 2, tenant: 'David Lee', unit: 'Apt 205', daysLeft: 12 },
  { id: 3, tenant: 'Emma Watson', unit: 'Apt 102', daysLeft: 20 }
])

const maintenanceRequests = ref([
  { id: 1, title: 'Leaky faucet', tenant: 'Frank Sinatra', unit: 'Apt 401', status: 'urgent' },
  { id: 2, title: 'Broken AC', tenant: 'Gloria Estefan', unit: 'Apt 302', status: 'pending' },
  { id: 3, title: 'Paint touch-up', tenant: 'Harry Styles', unit: 'Apt 103', status: 'scheduled' }
])
</script>
