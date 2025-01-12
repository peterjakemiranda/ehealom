<template>
  <div class="flex justify-center mt-4">
    <div class="join">
      <!-- Previous button -->
      <button
        class="join-item btn btn-sm hover:bg-base-300 transition-colors"
        :class="{ 'btn-disabled opacity-50': currentPage === 1 }"
        @click="handlePageChange(currentPage - 1)"
        aria-label="Previous page"
      >
        <ChevronLeftIcon class="h-4 w-4" />
      </button>

      <!-- Pagination items -->
      <template v-for="item in paginationItems" :key="item.value || item.type">
        <!-- Regular page button -->
        <button
          v-if="item.type === 'page'"
          class="join-item btn btn-sm min-w-[2.5rem] transition-colors"
          :class="{
            'btn-active bg-primary text-primary-content': item.value === currentPage,
            'hover:bg-base-300': item.value !== currentPage
          }"
          @click="handlePageChange(item.value)"
        >
          {{ item.value }}
        </button>

        <!-- Ellipsis -->
        <button
          v-else
          class="join-item btn btn-sm btn-disabled min-w-[2.5rem] cursor-default"
          tabindex="-1"
        >
          •••
        </button>
      </template>

      <!-- Next button -->
      <button
        class="join-item btn btn-sm hover:bg-base-300 transition-colors"
        :class="{ 'btn-disabled opacity-50': currentPage === lastPage }"
        @click="handlePageChange(currentPage + 1)"
        aria-label="Next page"
      >
        <ChevronRightIcon class="h-4 w-4" />
      </button>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { ChevronLeftIcon, ChevronRightIcon } from '@heroicons/vue/24/outline'

const props = defineProps({
  currentPage: {
    type: Number,
    required: true,
    validator: (value) => value > 0
  },
  lastPage: {
    type: Number,
    required: true,
    validator: (value) => value > 0
  },
  maxVisiblePages: {
    type: Number,
    default: 7,
    validator: (value) => value >= 5 && value % 2 === 1
  }
})

const emit = defineEmits(['page-change'])

function handlePageChange(page) {
  if (page >= 1 && page <= props.lastPage && page !== props.currentPage) {
    emit('page-change', page)
  }
}

const paginationItems = computed(() => {
  const { currentPage, lastPage, maxVisiblePages } = props
  const items = []

  // If we have 7 or fewer pages, show all pages
  if (lastPage <= maxVisiblePages) {
    for (let i = 1; i <= lastPage; i++) {
      items.push({ type: 'page', value: i })
    }
    return items
  }

  // Always show first page
  items.push({ type: 'page', value: 1 })

  // Calculate the range of pages to show around current page
  const sidePages = Math.floor((maxVisiblePages - 3) / 2) // subtract 3 for first, last, and current page
  const leftBound = currentPage - sidePages
  const rightBound = currentPage + sidePages

  // Add ellipsis after first page if needed
  if (leftBound > 2) {
    items.push({ type: 'ellipsis' })
  } else {
    // If we're close to the start, show early pages
    for (let i = 2; i < leftBound; i++) {
      items.push({ type: 'page', value: i })
    }
  }

  // Add pages around current page
  for (let i = Math.max(2, leftBound); i <= Math.min(lastPage - 1, rightBound); i++) {
    items.push({ type: 'page', value: i })
  }

  // Add ellipsis before last page if needed
  if (rightBound < lastPage - 1) {
    items.push({ type: 'ellipsis' })
  }

  // Always show last page if not already included
  if (lastPage > 1) {
    items.push({ type: 'page', value: lastPage })
  }

  // Remove duplicates
  return items.filter(
    (item, index, self) =>
      item.type === 'ellipsis' ||
      index === self.findIndex((t) => t.type === 'page' && t.value === item.value)
  )
})
</script>
