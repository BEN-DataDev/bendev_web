<script lang="ts">
	import type L from 'leaflet';
	import 'leaflet/dist/leaflet.css';

	interface Props {
		centre?: [number, number];
		bounds?: [[number, number], [number, number]];
		zoom?: number;
		width?: string;
		height?: string;
	}

	const {
		centre = [-35.7338998511678, 148.249161457376],
		bounds,
		zoom = 10,
		width = '100%',
		height = '400px'
	}: Props = $props();

	let mapContainer: HTMLDivElement;
	let leafletModule = $state<typeof L>();
	let leafletMap = $state<L.Map>();
	let tileLayer;

	$effect(() => {
		if (typeof window !== 'undefined') {
			import('leaflet').then((leaflet) => {
				leafletModule = leaflet;

				// Initialize map with default view
				leafletMap = leafletModule.map(mapContainer);

				// Add tile layer first
				tileLayer = leafletModule
					.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
						attribution: '© OpenStreetMap contributors'
					})
					.addTo(leafletMap);

				// Wait for next tick to ensure map is ready
				setTimeout(() => {
					if (bounds && bounds[0] && bounds[1]) {
						console.log('Setting bounds:', bounds);
						leafletMap?.invalidateSize();
						leafletMap?.fitBounds(bounds);
						console.log('Set bounds:', leafletMap?.getBounds());
					}
				}, 100);
			});
		}
	});

	$effect(() => {
		if (leafletMap) {
			if (bounds) {
				leafletMap.fitBounds(bounds);
				console.log('Bounds:', bounds);
				console.log('Bounds Changed:', leafletMap.getBounds());
			}
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
