<script lang="ts">
	import LeafletBasicReactiveMap from '$components/maps/leaflet/LeafletBasicReactiveMap.svelte';
	import type { PageData } from './$types';

	interface Props {
		data: PageData;
	}

	let { data }: Props = $props();
	let selectedCommunity = $state<string | null>(null);
	let searchQuery = $state('');
	let currentPage = $state(1);
	const itemsPerPage = 10;

	let filteredCommunities = $derived(
		data.communities.filter((community: { name: string }) =>
			community.name.toLowerCase().includes(searchQuery.toLowerCase())
		)
	);

	let paginatedCommunities = $derived(
		filteredCommunities.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage)
	);

	let totalPages = $derived(Math.ceil(filteredCommunities.length / itemsPerPage));

	function nextPage() {
		if (currentPage < totalPages) currentPage++;
	}

	function previousPage() {
		if (currentPage > 1) currentPage--;
	}

	let currentCommunity = $derived(
		data.communities.find((c: { id: string | null }) => c.id === selectedCommunity)
	);

	let mapCentre = $derived(
		currentCommunity
			? currentCommunity.extent_center
			: (data.communities[0]?.extent_center ?? [-35.7338998511678, 148.249161457376])
	);

	let mapBounds = $derived(
		currentCommunity
			? currentCommunity.extent_bounds
			: (data.communities[0]?.extent_bounds ?? [
					[-35.14573998759259, 148.62854003906253],
					[-35.99356320483023, 147.62054443359378]
				])
	);
</script>

<div class="grid h-full grid-cols-1 md:grid-cols-[250px_1fr] lg:grid-cols-[250px_1fr_350px]">
	<!-- Left sidebar: community list -->
	<aside class="overflow-y-auto border-r border-surface-200 p-4 dark:border-surface-700">
		<div class="space-y-4">
			<div class="flex items-center justify-between">
				<h4 class="h4">Communities</h4>
				<a href="/communities/new" class="btn preset-filled-primary-500 btn-sm">+ New</a>
			</div>
			<input
				type="search"
				class="input"
				placeholder="Start typing to Search communities..."
				bind:value={searchQuery}
			/>
			<div class="space-y-2">
				{#each paginatedCommunities as community}
					<button
						class="btn preset-tonal-surface-200-800 w-full justify-start text-left {selectedCommunity ===
						community.id
							? 'border-primary-500 bg-primary-100 text-primary-700'
							: ''}"
						onclick={() => (selectedCommunity = community.id)}
					>
						{community.name}
					</button>
				{/each}
			</div>
			{#if totalPages > 1}
				<div class="mt-4 flex items-center justify-between">
					<button
						class="btn preset-filled-surface-200-800"
						disabled={currentPage === 1}
						onclick={previousPage}
					>
						Previous
					</button>
					<span class="text-sm">Page {currentPage} of {totalPages}</span>
					<button
						class="btn preset-filled-surface-200-800"
						disabled={currentPage === totalPages}
						onclick={nextPage}
					>
						Next
					</button>
				</div>
			{/if}
		</div>
	</aside>

	<!-- Main: map -->
	<main class="h-full overflow-hidden">
		<LeafletBasicReactiveMap centre={mapCentre} bounds={mapBounds} />
	</main>

	<!-- Right sidebar: community details (desktop only) -->
	<aside class="hidden overflow-y-auto border-l border-surface-200 p-4 dark:border-surface-700 lg:block">
		{#if currentCommunity}
			<div class="flex items-center justify-between gap-2">
				<h4 class="h4">{currentCommunity.name}</h4>
				<a href="/communities/{currentCommunity.id}" class="btn preset-tonal-surface btn-sm shrink-0">View →</a>
			</div>

			{#if currentCommunity.communityinfo}
				<div class="card preset-outlined-surface-200-800 mt-4">
					<h5 class="h5">Community Information</h5>
					<div class="space-y-4">
						<div>
							<h6 class="h6">About</h6>
							<p class="mt-1 text-surface-600 dark:text-surface-300">
								{currentCommunity.communityinfo.about}
							</p>
						</div>
						<div>
							<h6 class="h6">Objects</h6>
							<p class="mt-1 text-surface-600 dark:text-surface-300">
								{currentCommunity.communityinfo.objects}
							</p>
						</div>
						<div>
							<h6 class="h6">Primary Goal</h6>
							{#if Array.isArray(currentCommunity.communityinfo['primary goal'])}
								<ul class="list-disc space-y-1 pl-4">
									{#each currentCommunity.communityinfo['primary goal'] as goal}
										<li>{goal}</li>
									{/each}
								</ul>
							{:else}
								<p>{currentCommunity.communityinfo.primary_goal}</p>
							{/if}
						</div>
					</div>
				</div>
			{/if}

			{#if currentCommunity.contactinfo}
				<div class="card preset-outlined-surface-200-800 mt-4">
					<h5 class="h5">Contact Information</h5>
					<div class="space-y-2">
						{#each currentCommunity.contactinfo.contacts as contact}
							{#if contact.developer}
								<div class="card preset-outlined-surface-200-800">
									<h6 class="h6">Developer</h6>
									<p class="text-surface-600 dark:text-surface-300">{contact.developer.name}</p>
								</div>
							{/if}
						{/each}
					</div>
				</div>
			{/if}
		{:else}
			<div class="flex h-full items-center justify-center">
				<p class="text-surface-500">Select a community to view details</p>
			</div>
		{/if}
	</aside>
</div>
