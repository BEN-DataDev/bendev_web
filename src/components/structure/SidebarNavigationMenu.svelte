<script lang="ts">
	import { Listgroup, ListgroupItem, type ListGroupItemType } from 'svelte-5-ui-lib';

	import type { Component } from 'svelte';

	interface Props {
		linkItems?: ListGroupItemType[];
		title?: string;
		groupClass?: string;
	}

	let { linkItems = [], title, groupClass }: Props = $props();
</script>

<div class="flex justify-center">
	<Listgroup active class={groupClass}>
		<h3 class="p-1 text-center text-xl font-medium text-gray-900 dark:text-white">
			{title}
		</h3>

		{#each linkItems as linkItem}
			<ListgroupItem class={linkItem.class}>
				name: {linkItem.name}, Icon: {linkItem.Icon}, href: {linkItem.href}
			</ListgroupItem>
		{/each}
	</Listgroup>
</div>
