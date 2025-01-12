export async function exportToCsv(data, filename) {
    if (!data?.length) return
  
    // Add BOM for proper UTF-8 encoding in Excel
    const BOM = '\uFEFF'
    
    // Get headers from first row
    const headers = Object.keys(data[0])
    
    // Helper function to clean currency values
    const cleanValue = (value) => {
      if (typeof value === 'string' && value.includes('₱')) {
        // Remove currency symbol and commas, then trim
        return value.replace('₱', '').replace(/,/g, '').trim()
      }
      return value
    }
  
    // Convert data to CSV format
    const csvRows = [
      // Header row
      headers.join(','),
      // Data rows
      ...data.map(row => 
        headers.map(header => {
          const value = cleanValue(row[header])
          // Escape special characters and wrap in quotes if needed
          return typeof value === 'string' && (value.includes(',') || value.includes('"'))
            ? `"${value.replace(/"/g, '""')}"` 
            : value
        }).join(',')
      )
    ]
  
    const csvContent = BOM + csvRows.join('\n')
    const blob = new Blob([csvContent], { 
      type: 'text/csv;charset=utf-8'
    })
    
    // Create download link
    if (navigator.msSaveBlob) { // IE 10+
      navigator.msSaveBlob(blob, filename)
    } else {
      const link = document.createElement('a')
      if (link.download !== undefined) {
        const url = URL.createObjectURL(blob)
        link.setAttribute('href', url)
        link.setAttribute('download', `${filename}.csv`)
        link.style.visibility = 'hidden'
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
        URL.revokeObjectURL(url)
      }
    }
  }