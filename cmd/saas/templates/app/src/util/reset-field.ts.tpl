export function resetField(selector: string): void {
  const field = document.querySelector(selector) as HTMLInputElement;
  if (field) {
    field.value = "";
  }
}
