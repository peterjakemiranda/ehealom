<template>
  <div class="container mx-auto px-4 py-8">
    <!-- Header -->
    <div class="flex justify-between items-center mb-8">
      <h1 class="text-3xl font-bold text-gray-800">Dashboard</h1>
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
