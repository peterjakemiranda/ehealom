import { formatCurrency } from '../utils/currency'

export const vCurrency = {
  mounted(el, binding) {
    const value = binding.value
    el.textContent = formatCurrency(value)
  },
  updated(el, binding) {
    const value = binding.value
    el.textContent = formatCurrency(value)
  }
}