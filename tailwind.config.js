/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Montserrat', 'sans-serif'],
      },
      colors: {
        orange: {
          DEFAULT: '#eb691c',
          light:   '#f07f3c',
          pale:    '#fdf0e8',
          deep:    '#c45a10',
        },
        gray: {
          100: '#f4f3f0',
          200: '#e8e6e1',
          400: '#b0aba3',
          600: '#6e6a62',
          800: '#2e2b26',
        },
      },
      borderRadius: {
        DEFAULT: '10px',
      },
    },
  },
  plugins: [],
}
