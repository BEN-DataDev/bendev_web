<script lang="ts">
	import type { Component } from 'svelte';
	import { Button } from 'svelte-5-ui-lib';

	type ButtonColorType =
		| 'primary'
		| 'dark'
		| 'alternative'
		| 'light'
		| 'secondary'
		| 'gray'
		| 'red'
		| 'orange'
		| 'amber'
		| 'yellow'
		| 'lime'
		| 'green'
		| 'emerald'
		| 'teal'
		| 'cyan'
		| 'sky'
		| 'blue'
		| 'indigo'
		| 'violet'
		| 'purple'
		| 'fuchsia'
		| 'pink'
		| 'rose';
	type ButtonSizeType = 'sm' | 'md' | 'lg' | 'xl' | 'xs' | undefined;

	interface ButtonData {
		name: string;
		href: string;
		icon?: Component;
		iconPosition: 'left' | 'right';
		class?: string;
		pill?: boolean;
		outline?: boolean;
		size?: ButtonSizeType;
		color?: ButtonColorType;
	}

	interface Props {
		buttons: ButtonData[];
		children?: import('svelte').Snippet;
	}

	const { buttons }: Props = $props();
</script>

<div class="button-stack">
	{#each buttons as button}
		{#if button.icon && button.iconPosition === 'left'}
			<Button href={button.href} color={button.color} class={button.class}>
				{button.icon}
				{button.name}
			</Button>
		{:else if button.icon && button.iconPosition === 'right'}
			<Button href={button.href} color={button.color} class={button.class}>
				{button.name}
				{button.icon}
			</Button>
		{:else if button.icon && button.iconPosition === 'right'}
			<Button href={button.href} color={button.color} class={button.class}>
				{button.name}
			</Button>
		{/if}
	{/each}
</div>

<style>
	.button-stack {
		display: flex;
		flex-direction: column;
		align-items: flex-end;
		gap: 0.5rem;
	}
</style>
