// src/utils/swalHelper.js
import Swal from 'sweetalert2'

export const swalHelper = {
  toast(icon, title) {
    Swal.fire({
      icon,
      title,
      toast: true,
      position: 'top-end',
      showConfirmButton: false,
      timer: 3000,
      timerProgressBar: true
    })
  },
  confirm(title, text, confirmButtonText = 'Yes') {
    return Swal.fire({
      title,
      text,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#3085d6',
      cancelButtonColor: '#d33',
      confirmButtonText
    })
  }
}
