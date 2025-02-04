// src/utils/swalHelper.js
import Swal from 'sweetalert2'

export const swalHelper = {
  toast(type, message) {
    const Toast = Swal.mixin({
      toast: true,
      position: 'top-end',
      showConfirmButton: false,
      timer: 3000,
      timerProgressBar: true,
    })

    Toast.fire({
      icon: type,
      title: message
    })
  },

  confirm(options = {}) {
    return Swal.fire({
      title: options.title || 'Are you sure?',
      text: options.text || "You won't be able to revert this!",
      icon: options.icon || 'warning',
      showCancelButton: true,
      confirmButtonColor: '#3085d6',
      cancelButtonColor: '#d33',
      confirmButtonText: options.confirmButtonText || 'Yes',
      cancelButtonText: options.cancelButtonText || 'Cancel'
    })
  }
}

export default swalHelper
