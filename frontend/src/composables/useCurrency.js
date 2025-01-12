import { computed } from 'vue'
import { formatCurrency } from '../utils/currency'

export function useCurrency(value) {
  const formatted = computed(() => formatCurrency(value.value))
  
  return {
    formatted
  }
}