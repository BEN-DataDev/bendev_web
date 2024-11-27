<script lang="ts">
	import ResponsiveLayout from '$components/structure/ThreePanelLayout.svelte';
	import LeafletMap from '$components/maps/leaflet/LeafletMap.svelte';
	import LeafletGeoJSONPolygonLayer from '$components/maps/leaflet/layers/geojson/LeafletGeoJSONPolygonLayer.svelte';
	import { Button, Heading, Card, Search } from 'svelte-5-ui-lib';
	import type { PageData } from './$types';
	import LeafletBasicReactiveMap from '$components/maps/leaflet/LeafletBasicReactiveMap.svelte';

	interface Props {
		data: PageData;
	}

	let { data }: Props = $props();
	let selectedCommunity = $state<string | null>(null);
	let leftSidebarOpen = $state(true);
	let rightSidebarOpen = $state(true);
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

	const baseLayers = [
		{
			name: 'NSW Streets',
			url: `https://maps.six.nsw.gov.au/arcgis/rest/services/public/NSW_Base_Map/MapServer/tile/{z}/{y}/{x}`,
			attribution: `\u003ca href='https://www.spatial.nsw.gov.au' target='_blank'\u003e\u0026copy; Spatial Services NSW \u003c/a\u003e`
		},
		{
			name: 'NSW Aerial',
			url: `https://maps.six.nsw.gov.au/arcgis/rest/services/public/NSW_Imagery/MapServer/tile/{z}/{y}/{x}`,
			attribution: `\u003ca href='https://www.spatial.nsw.gov.au' target='_blank'\u003e\u0026copy; Spatial Services NSW \u003c/a\u003e`
		},
		{
			name: 'OpenStreetMap',
			url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
			attribution: '© OpenStreetMap contributors'
		},
		{
			name: 'Satellite',
			url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
			attribution:
				'Esri, DigitalGlobe, GeoEye, Earthstar Geographics, CNES/Airbus DS, USDA, USGS, AeroGRID, IGN, and the GIS User Community'
		}
	];

	interface PolygonOptions extends L.PathOptions {
		fillColour?: string;
		fillOpacity?: number;
		colour?: string;
		weight?: number;
	}

	const communitiesOptions: PolygonOptions = {
		fillColor: '#3388ff',
		fillOpacity: 0.7,
		stroke: true,
		color: '#000',
		weight: 1,
		opacity: 1
	};

	const mapConfig = {
		centre: data.communities[0].centre as [number, number],
		bounds: data.communities[0].bounds as [[number, number], [number, number]],
		minZoom: undefined,
		maxZoom: undefined,
		zoomable: true,
		zoomSnap: 0.25,
		scaleControl: { present: true, position: 'bottomleft' as L.ControlPosition },
		attributionControl: { present: true },
		layersControl: { present: true, position: 'topright' as L.ControlPosition },
		legend: { present: false, position: 'bottomright' as L.ControlPosition },
		width: '100%',
		height: '99%',
		baseLayers: baseLayers
	};
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

<ResponsiveLayout
	bind:leftSidebarOpen
	bind:rightSidebarOpen
	leftSidebarWidth="20%"
	rightSidebarWidth="40%"
>
	{#snippet leftSidebarContent()}
		<div class="space-y-4">
			<Heading tag="h4">Communities</Heading>
			<Search placeholder="Start typing to Search communities..." bind:value={searchQuery} />
			<div class="space-y-2">
				{#each paginatedCommunities as community}
					<Button
						color="alternative"
						class="w-full justify-start text-left {selectedCommunity === community.id
							? 'border-primary-500 bg-primary-100 text-primary-700'
							: ''}"
						onclick={() => (selectedCommunity = community.id)}
					>
						{community.name}
					</Button>
				{/each}
			</div>
			{#if totalPages > 1}
				<div class="mt-4 flex items-center justify-between">
					<Button color="alternative" disabled={currentPage === 1} onclick={previousPage}>
						Previous
					</Button>
					<span class="text-sm">
						Page {currentPage} of {totalPages}
					</span>
					<Button color="alternative" disabled={currentPage === totalPages} onclick={nextPage}>
						Next
					</Button>
				</div>
			{/if}
		</div>
	{/snippet}
	<div class="h-[100vh] w-[100%]">
		<!-- {#if currentCommunity}
			{#await import('$components/maps/leaflet/LeafletMap.svelte') then { default: LeafletMap }} -->
		<!-- <LeafletMap {...mapConfig}> -->
		<!-- {#await import('$components/maps/leaflet/layers/geojson/LeafletGeoJSONPolygonLayer.svelte') then { default: LeafletGeoJSONPolygonLayer }} -->
		<!-- <LeafletGeoJSONPolygonLayer
				geojsonData={currentCommunity.extent}
				layerName={`${currentCommunity.name} Layer`}
				visible={true}
				editable={false}
				staticLayer={false}
				showInLegend={true}
				polygonOptions={communitiesOptions}
			/> -->
		<!-- {/await} -->
		<!-- </LeafletMap> -->
		<LeafletBasicReactiveMap centre={mapCentre} bounds={mapBounds} />
		{#snippet righttSidebarContent()}
			{#if currentCommunity}
				<!-- <div class="space-y-4 p-6"> -->
				<Heading tag="h4">{currentCommunity.name}</Heading>
				{#if currentCommunity.communityinfo}
					<Card horizontal={true} class="max-w-[100%]">
						<Heading tag="h5">Community Information</Heading>
						<div class="space-y-4">
							<div>
								<Heading tag="h6">About</Heading>
								<p class="mt-1 text-gray-600">{currentCommunity.communityinfo.about}</p>
							</div>
							<div>
								<Heading tag="h6">Objects</Heading>
								<p class="mt-1 text-gray-600">{currentCommunity.communityinfo.objects}</p>
							</div>
							<div>
								<Heading tag="h6">Primary Goal</Heading>
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
					</Card>
				{/if}

				{#if currentCommunity.contactinfo}
					<Card horizontal={true} class="max-w-[100%]">
						<Heading tag="h5">Contact Information</Heading>
						<div class="space-y-2">
							{#each currentCommunity.contactinfo.contacts as contact}
								{#if contact.developer}
									<Card>
										<Heading tag="h6">Developer</Heading>
										<p class="text-gray-600">{contact.developer.name}</p>
									</Card>
								{/if}
							{/each}
						</div>
					</Card>
				{/if}

				<!-- <div class="rounded-lg bg-white p-4 shadow">
				<h2 class="mb-4 text-xl font-semibold">Additional Details</h2>
				<div class="space-y-2">
					<p class="text-gray-600">
						Created: {new Date(currentCommunity.created_at).toLocaleDateString()}
					</p>
					<p class="text-gray-600">
						Last Updated: {new Date(currentCommunity.last_updated).toLocaleDateString()}
					</p>
					<p class="text-gray-600">Public: {currentCommunity.public ? 'Yes' : 'No'}</p>
				</div>
			</div> -->
				<!-- </div> -->
			{:else}
				<div class="flex h-full items-center justify-center">
					<p class="text-gray-500">Select a community from the sidebar to view details</p>
				</div>
			{/if}
		{/snippet}
	</div></ResponsiveLayout
>
