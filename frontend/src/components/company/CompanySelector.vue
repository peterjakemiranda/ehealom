<template>
  <BaseDropdown position="right" width="w-72" class="dropdown">
    <template #trigger="{ toggle, isOpen }">
      <button
        @click="toggle()"
        class="flex items-center space-x-3 py-2 hover:opacity-80 transition-opacity"
      >
        <div class="w-8 h-8 flex-shrink-0">
          <img
            v-if="currentCompany?.logo"
            :src="currentCompany.logo"
            class="w-full h-full rounded-full object-cover ring-2 ring-gray-100"
            :alt="currentCompany?.name"
          />
          <div
            v-else
            class="w-full h-full rounded-full bg-primary flex items-center justify-center text-white font-medium shadow-sm"
          >
            {{ currentCompany?.name?.charAt(0) || '?' }}
          </div>
        </div>
        <div class="flex items-center space-x-2">
          <div class="flex flex-col items-start">
            <span class="text-sm font-medium text-gray-900">
              {{ currentCompany?.name || 'Select Company' }}
            </span>
            <span class="text-xs text-gray-500">Switch company</span>
          </div>
          <svg
            class="w-4 h-4 text-gray-400 transition-transform"
            :class="{ 'rotate-180': isOpen }"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7" />
          </svg>
        </div>
      </button>
    </template>

    <div class="py-2 divide-y divide-gray-100">
      <!-- Companies List -->
      <div class="py-2">
        <div class="px-4 pb-2 text-xs font-medium text-gray-500 uppercase tracking-wider">
          Your Companies
        </div>
        <template v-if="companies.length">
          <button
            v-for="company in companies"
            :key="company.uuid"
            @click="switchCompany(company)"
            class="w-full px-4 py-2 text-sm text-left hover:bg-gray-50 flex items-center space-x-3"
            :class="{ 'bg-gray-50': company.uuid === currentCompany?.uuid }"
          >
            <div class="w-8 h-8 flex-shrink-0">
              <img
                v-if="company.logo"
                :src="company.logo"
                class="w-full h-full rounded-full object-cover"
                :alt="company.name"
              />
              <div
                v-else
                class="w-full h-full rounded-full bg-primary flex items-center justify-center text-white text-sm font-medium"
              >
                {{ company.name.charAt(0) }}
              </div>
            </div>
            <div class="flex-grow">
              <div class="font-medium text-gray-900">{{ company.name }}</div>
              <div class="text-xs text-gray-500">{{ company.email }}</div>
            </div>
            <div v-if="company.pivot.is_default" class="flex items-center">
              <span class="inline-flex items-center rounded-full bg-primary/10 px-2 py-1 text-xs font-medium text-primary">
                Default
              </span>
            </div>
          </button>
        </template>
        <div v-else class="px-4 py-2 text-sm text-gray-500">
          No companies found
        </div>
      </div>

      <!-- Add New Company Button -->
      <div class="py-2">
        <button
          @click="showCompanyModal = true"
          class="w-full px-4 py-2 text-sm text-left hover:bg-gray-50 text-primary flex items-center space-x-2"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
          </svg>
          <span class="font-medium">Add New Company</span>
        </button>
      </div>
    </div>
  </BaseDropdown>

  <CompanyModal
    v-if="showCompanyModal"
    @close="showCompanyModal = false"
    @saved="onCompanyCreated"
  />
</template>

<script setup>
import { ref } from 'vue'
import { storeToRefs } from 'pinia'
import { useCompanyStore } from '@/stores/companyStore'
import BaseDropdown from '@/components/ui/BaseDropdown.vue'
import CompanyModal from './CompanyModal.vue'

const companyStore = useCompanyStore()
const { companies, currentCompany } = storeToRefs(companyStore)
const showCompanyModal = ref(false)

const switchCompany = async (company) => {
  await companyStore.setCurrentCompany(company)
}

const onCompanyCreated = (company) => {
  showCompanyModal.value = false
  companyStore.fetchUserCompanies()
}
</script>
