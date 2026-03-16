/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  theme: {
    extend: {
      colors: {
        paypay: {
          red: '#ff0033', // PayPay Red
          background: '#ffffff',
          lightGray: '#f6f6f6',
        }
      }
    },
  },
  plugins: [],
}
