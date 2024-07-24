/** @type {import('tailwindcss').Config} */
export default {
  content: ["./**/*.{html,js,ts,templ,txt,md,yaml,yml}"],
  theme: {
    extend: {},
  },
  plugins: [
    require("@tailwindcss/typography"), 
    require('@tailwindcss/forms'),
  ],
}

