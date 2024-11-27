<script lang="ts">
	import type L from 'leaflet';
	import 'leaflet/dist/leaflet.css';

	type LatLng = [number, number];
	interface Props {
		centre?: LatLng;
		zoom?: number;
		width?: string;
		height?: string;
	}

	const {
		centre = [51.505, -0.09] as LatLng,
		zoom = 13,
		width = '100%',
		height = '400px'
	}: Props = $props();

	let mapContainer: HTMLDivElement;
	let leaflet = $state<typeof L>();
	let leafletMap = $state<L.Map>();
	let tileLayer;

	$effect(() => {
		if (typeof window !== 'undefined') {
			import('leaflet').then((leaflet) => {
				leafletMap = leaflet.map(mapContainer).setView(centre, zoom);
				tileLayer = leaflet
					.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
						attribution: '© OpenStreetMap contributors'
					})
					.addTo(leafletMap);
			});
		}
	});
</script>

<div bind:this={mapContainer} style:width style:height></div>

<style>
	div {
		border-radius: 4px;
		border: 1px solid #ccc;
	}
</style>
