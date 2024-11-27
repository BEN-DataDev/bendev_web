<script lang="ts">
	import { Button } from 'svelte-5-ui-lib';
	import {
		ChevronDoubleLeftOutline,
		ChevronDoubleRightOutline,
		ChevronDoubleUpOutline,
		ChevronDoubleDownOutline
	} from 'flowbite-svelte-icons';
	import { browser } from '$app/environment';

	interface Props {
		leftSidebarOpen?: boolean;
		rightSidebarOpen?: boolean;
		leftSidebarWidth?: string;
		rightSidebarWidth?: string;
		leftSidebarContent?: import('svelte').Snippet;
		righttSidebarContent?: import('svelte').Snippet;
		children?: import('svelte').Snippet;
	}

	let {
		leftSidebarOpen = $bindable(false),
		rightSidebarOpen = $bindable(false),
		leftSidebarWidth = '250px',
		rightSidebarWidth = '250px',
		leftSidebarContent,
		righttSidebarContent,
		children
	}: Props = $props();

	let leftSidebarCollapsed = $state(false);
	let rightSidebarCollapsed = $state(false);

	const collapsedWidth = '48px';

	let windowWidth = $state(0);

	$effect(() => {
		if (browser) {
			windowWidth = window.innerWidth;
			const handleResize = () => {
				windowWidth = window.innerWidth;
			};
			window.addEventListener('resize', handleResize);
			return () => window.removeEventListener('resize', handleResize);
		}
	});
</script>

<div class="flex w-full flex-col overflow-hidden md:flex-row">
	{#if leftSidebarOpen}
		<aside
			class="relative order-first flex w-full shrink-0 flex-col overflow-hidden bg-fill-100 shadow-lg transition-all duration-300 ease-in-out dark:bg-fill-900"
			style="height: {leftSidebarCollapsed && browser && windowWidth < 768
				? collapsedWidth
				: 'auto'}; width: {leftSidebarCollapsed && browser && windowWidth >= 768
				? collapsedWidth
				: browser && windowWidth >= 768
					? leftSidebarWidth
					: '100%'};"
		>
			<Button
				color="alternative"
				class="bottom-0 w-full p-1 md:absolute md:bottom-auto md:right-0 md:top-2 md:w-auto"
				onclick={() => (leftSidebarCollapsed = !leftSidebarCollapsed)}
			>
				{#if leftSidebarCollapsed}
					<ChevronDoubleRightOutline class="hidden h-5 w-5 md:block" />
					<ChevronDoubleDownOutline class="h-5 w-5 md:hidden" />
				{:else}
					<ChevronDoubleLeftOutline class="hidden h-5 w-5 md:block" />
					<ChevronDoubleUpOutline class="h-5 w-5 md:hidden" />
				{/if}
			</Button>

			<div
				class="flex-1 overflow-y-auto pt-10 transition-all duration-300 ease-in-out md:mt-0
                    {leftSidebarCollapsed
					? 'invisible w-0 p-0 opacity-0'
					: 'visible p-4 opacity-100'}"
			>
				{@render leftSidebarContent?.()}
			</div>
		</aside>
	{/if}

	<main class="order-2 flex-1 overflow-y-auto p-4 md:order-none">
		{@render children?.()}
	</main>

	{#if rightSidebarOpen}
		<aside
			class="relative order-last flex w-full shrink-0 flex-col overflow-hidden bg-fill-100 shadow-lg transition-all duration-300 ease-in-out dark:bg-fill-900"
			style="height: {rightSidebarCollapsed && browser && windowWidth < 768
				? collapsedWidth
				: 'auto'}; width: {rightSidebarCollapsed && browser && windowWidth >= 768
				? collapsedWidth
				: browser && windowWidth >= 768
					? rightSidebarWidth
					: '100%'};"
		>
			<Button
				color="alternative"
				class="top-0 w-full p-1 md:absolute md:left-0 md:top-2 md:w-auto"
				onclick={() => (rightSidebarCollapsed = !rightSidebarCollapsed)}
			>
				{#if rightSidebarCollapsed}
					<ChevronDoubleLeftOutline class="hidden h-5 w-5 md:block" />
					<ChevronDoubleUpOutline class="h-5 w-5 md:hidden" />
				{:else}
					<ChevronDoubleRightOutline class="hidden h-5 w-5 md:block" />
					<ChevronDoubleDownOutline class="h-5 w-5 md:hidden" />
				{/if}
			</Button>

			<div
				class="flex-1 overflow-y-auto pt-10 transition-all duration-300 ease-in-out md:mt-0
                    {rightSidebarCollapsed
					? 'invisible w-0 p-0 opacity-0'
					: 'visible p-4 opacity-100'}"
			>
				{@render righttSidebarContent?.()}
			</div>
		</aside>
	{/if}
</div>
