import { Controller } from "@hotwired/stimulus";

// Handles Paddle Billing checkout.
// Paddle.js is loaded via a <script> tag on the page — not via importmap.
export default class extends Controller {
  static values = {
    clientToken: String,
    priceId: String,
    email: String,
    checkoutCompleteUrl: String,
    autoOpen: { type: Boolean, default: false },
    sandbox: { type: Boolean, default: false },
  };

  connect() {
    if (typeof Paddle === "undefined") return;

    if (this.sandboxValue) {
      Paddle.Environment.set("sandbox");
    }

    Paddle.Initialize({
      token: this.clientTokenValue,
      eventCallback: (event) => {
        if (event.name === "checkout.completed") {
          this.#onCheckoutCompleted(event.data);
        }
      },
    });

    if (this.autoOpenValue) {
      setTimeout(() => this.openCheckout(), 300);
    }
  }

  openCheckout() {
    if (typeof Paddle === "undefined") return;

    Paddle.Checkout.open({
      items: [{ priceId: this.priceIdValue, quantity: 1 }],
      customer: { email: this.emailValue },
    });
  }

  async #onCheckoutCompleted(data) {
    const customerId = data?.customer?.id;
    if (!customerId) return;

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
      const response = await fetch(this.checkoutCompleteUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
        },
        body: JSON.stringify({ customer_id: customerId }),
      });

      if (!response.ok) {
        console.error("checkout_complete failed:", response.status);
      }
    } catch (e) {
      console.error("checkout_complete error:", e);
    } finally {
      window.location.reload();
    }
  }
}
