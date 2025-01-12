/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#1f2937',
          focus: '#111827', // Darker shade for hover/focus
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
          ...require('daisyui/src/theming/themes')['[data-theme=light]'],
          primary: '#1f2937',
          'primary-focus': '#111827',
          'primary-content': '#ffffff',
          '--btn-text-case': 'none',
          // Button specific colors
          '.btn-outline': {
            '--tw-border-opacity': '1',
            'border-color': '#1f2937',
            color: '#1f2937',
            '&:hover': {
              'background-color': '#1f2937',
              'border-color': '#1f2937',
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
