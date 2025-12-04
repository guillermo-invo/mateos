const {heroui} = require('@heroui/theme');

/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: 'class',
  content: [
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./node_modules/@heroui/theme/dist/**/*.{js,ts,jsx,tsx}"
  ],
  theme: {
    extend: {
      colors: {
        'mateos-primary': '#4682b4',
        'mateos-success': '#68bb7b',
        'mateos-warning': '#ffa500',
        'mateos-neutral': '#696969',
        'mateos-accent': '#fceab0',
        'mateos-dark': '#1e1f21',
      }
    }
  },
  plugins: [
    heroui({
      themes: {
        light: {
          colors: {
            primary: {
              DEFAULT: '#4682b4',
              foreground: '#ffffff',
            },
            success: {
              DEFAULT: '#68bb7b',
              foreground: '#ffffff',
            },
            warning: {
              DEFAULT: '#ffa500',
              foreground: '#ffffff',
            },
          }
        },
        dark: {
          colors: {
            primary: {
              DEFAULT: '#4682b4',
              foreground: '#ffffff',
            },
            success: {
              DEFAULT: '#68bb7b',
              foreground: '#ffffff',
            },
            warning: {
              DEFAULT: '#ffa500',
              foreground: '#ffffff',
            },
            background: '#1e1f21',
            foreground: '#ffffff',
          }
        }
      }
    })
  ]
}