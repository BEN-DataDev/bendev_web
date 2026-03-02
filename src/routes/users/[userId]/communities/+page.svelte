<script lang="ts">
	import type { PageData } from './$types';

	interface Community {
		id: string;
		name: string;
		public: boolean;
	}

	interface Props {
		data: PageData;
	}

	let { data }: Props = $props();
	let communities = $derived(data.communities as Community[]);
</script>

<svelte:head>
	<title>Communities</title>
</svelte:head>

<div class="space-y-4">
	<h2 class="h3">Communities</h2>

	{#if communities.length === 0}
		<p class="text-sm text-surface-500">Not a member of any communities.</p>
	{:else}
		<div class="space-y-2">
			{#each communities as community (community.id)}
				<a
					href="/communities/{community.id}"
					class="card preset-outlined-surface-200-800 flex items-center justify-between gap-2 p-3 hover:bg-surface-100 dark:hover:bg-surface-800"
				>
					<span class="font-medium">{community.name}</span>
					{#if community.public}
						<span class="badge preset-tonal-success text-xs">Public</span>
					{:else}
						<span class="badge preset-tonal-surface text-xs">Private</span>
					{/if}
				</a>
			{/each}
		</div>
	{/if}
</div>
