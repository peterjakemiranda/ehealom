/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#1C0FD6',
          focus: '#1609A3', // Slightly darker shade for hover/focus
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
          primary: '#1C0FD6',
          'primary-focus': '#1609A3',
          'primary-content': '#ffffff',
          '--btn-text-case': 'none',
          // Button specific colors
          '.btn-outline': {
            '--tw-border-opacity': '1',
            'border-color': '#1C0FD6',
            color: '#1C0FD6',
            '&:hover': {
              'background-color': '#1C0FD6',
              'border-color': '#1C0FD6',
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
