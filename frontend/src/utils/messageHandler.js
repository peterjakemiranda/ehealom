import Swal from 'sweetalert2';

export function handleSuccess(message) {
  Swal.fire({
    toast: true,
    position: "bottom-end",
    showConfirmButton: false,
    timer: 3000,
    icon: "success",
    text: message || "Operation completed successfully.",
    background: "#4caf50",
    iconColor: "#fff",
    color: "#fff",
    padding: "10px",
  });
}

export function handleError(error) {
  console.error("Error occurred:", error);
  const message = error.response?.data?.message || "An unexpected error occurred. Please try again.";
  Swal.fire({
    toast: true,
    position: "bottom-end",
    showConfirmButton: false,
    timer: 3000,
    icon: "error",
    text: message,
    background: "#f44336",
    iconColor: "#fff",
    color: "#fff",
    padding: "10px",
  });
}
