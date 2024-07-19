/** @type {import('tailwindcss').Config} */
export default {
  content: ["./**/*.{html,js,ts,templ}"],
  theme: {
    extend: {},
  },
  plugins: [
    require("@tailwindcss/typography"), 
    require('@tailwindcss/forms'),
    require('daisyui'),
  ],
}

