/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#78B5B0',
          focus: '#5A9994', // Slightly darker shade for hover/focus
          content: '#ffffff' // Text color on primary background
        }
      }
    }
  },
  plugins: [require('daisyui')],
  daisyui: {
    themes: [
      {
        light: {
          ...require('daisyui/src/theming/themes')['light'],
          primary: '#78B5B0',
          'primary-focus': '#5A9994',
          'primary-content': '#ffffff',
          '--btn-text-case': 'none',
          // Button specific colors
          '.btn-outline': {
            '--tw-border-opacity': '1',
            'border-color': '#78B5B0',
            color: '#78B5B0',
            '&:hover': {
              'background-color': '#78B5B0',
              'border-color': '#78B5B0',
              color: '#ffffff'
            }
          }
        }
      }
    ],
    darkTheme: 'light',
    base: true,
    styled: true,
    utils: true,
    prefix: '',
    logs: true,
    themeRoot: ':root'
  }
}
