const DURATION = 5000;

// Explicit class strings so Tailwind includes them in the CSS build
const ALERT_CLASSES = {
  error:   "alert-error",
  warning: "alert-warning",
  success: "alert-success",
  info:    "alert-info",
};

// type: "error" | "warning" | "success" | "info"
export function showToast(message, type = "error") {
  const alertClass = ALERT_CLASSES[type] ?? "alert-error";

  const toast = document.createElement("div");
  toast.className = "toast toast-top toast-end z-[200]";
  toast.innerHTML = `<div class="alert ${alertClass} shadow-lg max-w-sm"><span>${message}</span></div>`;
  document.body.appendChild(toast);

  setTimeout(() => {
    toast.style.transition = "opacity 0.3s";
    toast.style.opacity = "0";
    setTimeout(() => toast.remove(), 300);
  }, DURATION);
}
