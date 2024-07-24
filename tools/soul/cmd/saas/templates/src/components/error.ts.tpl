class AppError extends HTMLElement {
    constructor() {
      super();
    }
  
    connectedCallback(): void {
      console.log("AppError connected");
    }
  }
  
  customElements.define("app-error", AppError);
  