import type { Config } from 'tailwindcss';

export default {
	content: [
		'./src/**/*.{html,js,svelte,ts}',
		'./node_modules/svelte-5-ui-lib/**/*.{html,js,svelte,ts}',
		'./node_modules/flowbite-svelte-icons/**/*.{html,js,svelte,ts}'
	],
	darkMode: 'selector',
	theme: {
		extend: {
			colors: {
				primary: {
					50: '#FFF5F2',
					100: '#FFF1EE',
					200: '#FFE4DE',
					300: '#FFD5CC',
					400: '#FFBCAD',
					500: '#FE795D',
					600: '#EF562F',
					700: '#EB4F27',
					800: '#CC4522',
					900: '#A5371B'
				},
				secondary: {
					50: '#f0f9ff',
					100: '#e0f2fe',
					200: '#bae6fd',
					300: '#7dd3fc',
					400: '#38bdf8',
					500: '#0ea5e9',
					600: '#0284c7',
					700: '#0369a1',
					800: '#075985',
					900: '#0c4a6e'
				},
				tertiary: {
					50: '#f5f7ff',
					100: '#ebf0fe',
					200: '#d7e2fd',
					300: '#b8cbfb',
					400: '#8fa9f7',
					500: '#6b88f3',
					600: '#4a64e5',
					700: '#3a4dcd',
					800: '#2f3ea6',
					900: '#283482'
				},
				success: {
					50: '#f0fdf4',
					100: '#dcfce7',
					200: '#bbf7d0',
					300: '#86efac',
					400: '#4ade80',
					500: '#22c55e',
					600: '#16a34a',
					700: '#15803d',
					800: '#166534',
					900: '#14532d'
				},
				warning: {
					50: '#fff7ed',
					100: '#ffedd5',
					200: '#fed7aa',
					300: '#fdb97f',
					400: '#fb923c',
					500: '#f97316',
					600: '#ea580c',
					700: '#c2410c',
					800: '#9a3412',
					900: '#7c2d12'
				},
				error: {
					50: '#fef2f2',
					100: '#fee2e2',
					200: '#fecaca',
					300: '#fca5a5',
					400: '#f87171',
					500: '#ef4444',
					600: '#dc2626',
					700: '#b91c1c',
					800: '#991b1b',
					900: '#7f1d1d'
				},
				surface: {
					50: '#e3f7e7',
					100: '#c8efcf',
					200: '#90df9f',
					300: '#55ce6b',
					400: '#31aa47',
					500: '#217330',
					600: '#1a5b26',
					700: '#13431c',
					800: '#0e3014',
					900: '#07180a',
					950: '#030c05'
				},
				text: {
					50: '#f9fafb',
					100: '#f3f4f6',
					200: '#e5e7eb',
					300: '#d1d5db',
					400: '#9ca3af',
					500: '#6b7280',
					600: '#4b5563',
					700: '#374151',
					800: '#1f2937',
					900: '#111827'
				},
				fill: {
					50: '#edf0f7',
					100: '#dbe2f0',
					200: '#b8c5e0',
					300: '#94a7d1',
					400: '#718ac1',
					500: '#5170b3',
					600: '#3f5992',
					700: '#30446e',
					800: '#212e4b',
					900: '#111827',
					950: '#090d15'
				}
			},
			fontFamily: {
				sans: ['Poppins', 'sans-serif']
			}
		}
	}
} as Config;
