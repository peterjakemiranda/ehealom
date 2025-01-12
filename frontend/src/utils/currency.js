export const currencyConfig = {
    currency: 'PHP',
    locale: 'en-PH',
    options: {
      style: 'currency',
      currency: 'PHP',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }
  }
  
  export function formatCurrency(value, config = currencyConfig) {
    if (typeof value !== 'number') {
      value = Number(value)
    }
    
    if (isNaN(value)) {
      return '—'
    }
  
    return new Intl.NumberFormat(config.locale, config.options).format(value)
  }
  
  // Optional: Format with custom options on the fly
  export function formatCurrencyWithOptions(value, options = {}) {
    return formatCurrency(value, {
      ...currencyConfig,
      options: { ...currencyConfig.options, ...options }
    })
  }

  export function unformat(value) {
    if (!value) return '0'
    return Number(value).toFixed(2)
  }