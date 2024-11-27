<script lang="ts">
	import { Accordion, AccordionItem } from 'svelte-5-ui-lib';
	import CustomAccordionHeader from '$components/custom/svelte-5-ui-lib/accordion/CustomAccordionHeader.svelte';
	import type { AccordionItemData } from '$lib/custom.component.types';

	interface Props {
		items: AccordionItemData[];
		level?: number;
	}

	let { items, level = 0 }: Props = $props();

	let openStates = $state<Record<string, boolean>>({});

	// Initialize states
	items.forEach((item) => {
		openStates[item.id] = item.isOpen ?? false;
	});

	function handleToggle(
		itemId: string,
		event: Event & { currentTarget: EventTarget & HTMLDivElement }
	) {
		openStates[itemId] = !openStates[itemId];
		const item = items.find((i) => i.id === itemId);
		item?.onToggle?.(openStates[itemId]);
	}

	function handleClick(item: AccordionItemData) {
		item.onClick?.();
	}

	function handleInit(item: AccordionItemData) {
		item.onInit?.();
	}

	$effect(() => {
		items.forEach((item) => {
			if (item.onInit) handleInit(item);
		});
	});
</script>

<Accordion class={level === 0 ? 'w-full' : level === 1 ? 'ml-4' : 'ml-6'}>
	{#each items as item (item.id)}
		<AccordionItem
			open={openStates[item.id]}
			onclick={() => handleClick(item)}
			ontoggle={(event) => handleToggle(item.id, event)}
		>
			{#snippet header()}
				{#if item.headerComponent}
					<item.headerComponent {...item.customProps} />
				{:else}
					<span class="flex gap-2 text-base {item.headerClass || ''}">
						{#if item.headerIcon}
							<item.headerIcon class="mt-0.5 {item.iconClass || ''}" />
						{/if}
						<span>{item.headerText}</span>
					</span>
				{/if}
			{/snippet}

			<div class="transition-all duration-200 {item.contentClass || ''}">
				{#if item.contentComponent}
					<item.contentComponent {...item.customProps} />
				{:else if item.content}
					<p class="mb-2 text-gray-500 dark:text-gray-400">
						{item.content}
					</p>
				{/if}

				{#if item.children && item.children.length > 0}
					<CustomAccordionHeader items={item.children} level={level + 1} />
				{/if}
			</div>
		</AccordionItem>
	{/each}
</Accordion>
