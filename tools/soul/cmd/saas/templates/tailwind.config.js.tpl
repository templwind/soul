/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./internal/**/*.{html,js,ts,templ,txt,md,yaml,yml}",
    "./themes/**/*.{html,js,ts,templ,txt,md,yaml,yml}",
  ],
  theme: {
    extend: {},
  },
  plugins: [
    require("@tailwindcss/typography"),
    require("@tailwindcss/forms"),
    require("daisyui"),
  ],
};
