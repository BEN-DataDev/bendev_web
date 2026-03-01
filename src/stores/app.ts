import { readable } from 'svelte/store';

export type Theme = 'light' | 'dark';

export const themeStore = readable<Theme>('light', (set) => {
	let observer: MutationObserver | undefined;
	let currentTheme: Theme = 'light';

	const updateTheme = () => {
		// Skeleton v4 uses data-mode attribute on <html>, not class="dark"
		const isDark = document.documentElement.getAttribute('data-mode') === 'dark';
		const newTheme: Theme = isDark ? 'dark' : 'light';
		if (newTheme !== currentTheme) {
			currentTheme = newTheme;
			set(currentTheme);
		}
	};

	if (typeof window !== 'undefined') {
		updateTheme();

		// Watch for changes to data-mode on the html element (Skeleton v4)
		observer = new MutationObserver(updateTheme);
		observer.observe(document.documentElement, { attributes: true, attributeFilter: ['data-mode'] });

		return () => {
			observer?.disconnect();
		};
	}

	return () => {};
});
