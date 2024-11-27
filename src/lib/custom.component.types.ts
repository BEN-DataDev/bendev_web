import type { Component, SvelteComponent } from 'svelte';

// Header component props interface
export interface HeaderProps {
	text?: string | undefined;
	icon?: Component;
	customClass?: string;
	iconClass?: string;
	badge?: {
		text: string;
		variant?: 'primary' | 'secondary' | 'warning' | 'danger';
	};
	tooltip?: string;
}
// Content component props interface
export interface ContentProps {
	content?: string | typeof SvelteComponent | undefined;
	customClass?: string;
	loading?: boolean;
	error?: string;
	metadata?: {
		author?: string;
		date?: Date;
		tags?: string[];
	};
	actions?: {
		label: string;
		handler: () => void;
		variant?: 'primary' | 'secondary' | 'text';
	}[];
}

export interface AccordionItemData {
	id: string;
	headerText: string;
	headerIcon?: Component;
	content?: string;
	children?: AccordionItemData[];

	// Custom styling
	headerClass?: string;
	contentClass?: string;
	iconClass?: string;

	// State management
	isOpen?: boolean;

	// Typed custom components
	headerComponent?: typeof SvelteComponent<HeaderProps>;
	contentComponent?: typeof SvelteComponent<ContentProps>;
	customProps?: HeaderProps & ContentProps;

	// Actions and callbacks
	onToggle?: (isOpen: boolean) => void;
	onClick?: () => void;
	onInit?: () => void;
}
