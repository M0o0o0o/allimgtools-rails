import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["monthly", "yearly"];

  toggle(event) {
    const yearly = event.target.checked;
    this.monthlyTargets.forEach((el) => el.classList.toggle("hidden", yearly));
    this.yearlyTargets.forEach((el) => el.classList.toggle("hidden", !yearly));
  }
}
