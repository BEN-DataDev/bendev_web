<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import maplibregl from 'maplibre-gl';
	import 'maplibre-gl/dist/maplibre-gl.css';

	let mapContainer = $state<HTMLDivElement | null>(null);
	let map: maplibregl.Map;

	class LayerControl {
		private map: maplibregl.Map;
		private container: HTMLElement;

		constructor(map: maplibregl.Map) {
			this.map = map;
			this.container = document.createElement('div');
			this.container.className = 'maplibregl-ctrl maplibregl-ctrl-group layer-control';
		}

		onAdd() {
			const layers = [
				{ id: 'osm', name: 'OpenStreetMap' },
				{ id: 'nsw-basemap', name: 'NSW Base Map' }
			];

			layers.forEach((layer) => {
				const button = document.createElement('button');
				button.className = 'layer-toggle active';
				button.textContent = layer.name;

				button.onclick = () => {
					const visibility = this.map.getLayoutProperty(layer.id, 'visibility');
					if (visibility === 'none') {
						this.map.setLayoutProperty(layer.id, 'visibility', 'visible');
						button.className = 'layer-toggle active';
					} else {
						this.map.setLayoutProperty(layer.id, 'visibility', 'none');
						button.className = 'layer-toggle';
					}
				};

				this.container.appendChild(button);
			});

			return this.container;
		}

		onRemove() {
			this.container.parentNode?.removeChild(this.container);
		}
	}

	interface Props {
		initialView?: {
			lng: number;
			lat: number;
			zoom: number;
		};
		style?: maplibregl.StyleSpecification;
	}

	let {
		initialView = {
			lng: 148.2,
			lat: -35.9,
			zoom: 8
		},
		style = {
			version: 8,
			sources: {
				osm: {
					type: 'raster',
					tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
					tileSize: 256,
					attribution: '© OpenStreetMap Contributors'
				},
				'nsw-basemap': {
					type: 'raster',
					tiles: [
						'https://maps.six.nsw.gov.au/arcgis/rest/services/public/NSW_Base_Map/MapServer/WMTS/tile/1.0.0/NSW_Base_Map/default/GoogleMapsCompatible/{z}/{y}/{x}.png'
					],
					tileSize: 256,
					attribution: '© NSW Government'
				}
			},
			layers: [
				{
					id: 'osm',
					type: 'raster',
					source: 'osm',
					minzoom: 0,
					maxzoom: 19
				},
				{
					id: 'nsw-basemap',
					type: 'raster',
					source: 'nsw-basemap',
					minzoom: 0,
					maxzoom: 19
				}
			]
		} as const
	}: Props = $props();

	onMount(() => {
		if (!mapContainer) return;

		map = new maplibregl.Map({
			container: mapContainer,
			style: {
				version: 8,
				sources: {
					'nsw-basemap': {
						type: 'raster',
						tiles: [
							'https://maps.six.nsw.gov.au/arcgis/rest/services/public/NSW_Base_Map/MapServer/WMTS/tile/1.0.0/NSW_Base_Map/default/GoogleMapsCompatible/{z}/{y}/{x}.png'
						],
						tileSize: 256,
						attribution: '© NSW Government'
					}
				},
				layers: [
					{
						id: 'nsw-basemap',
						type: 'raster',
						source: 'nsw-basemap',
						minzoom: 0,
						maxzoom: 19
					}
				]
			},
			center: [initialView.lng, initialView.lat],
			zoom: initialView.zoom
		});
		map.once('load', () => {
			// This code runs once the base style has finished loading.

			map.addSource('lots', {
				type: 'geojson',
				data: 'https://portal.spatial.nsw.gov.au/server/rest/services/NSW_Land_Parcel_Property_Theme/FeatureServer/0/query?where=1%3D1&outFields=*&f=geojson'
			});
			map.addLayer({
				id: 'lots-fill',
				type: 'fill',
				source: 'lots',

				paint: {
					'fill-color': 'hsla(0,0%,0%,0.75)',
					'fill-outline-color': 'white',
					'fill-opacity': 0.5
				}
			});
		});
		console.log(map);
		map.addControl(new maplibregl.NavigationControl());
	});

	onDestroy(() => {
		if (map) {
			map.remove();
		}
	});
</script>

<div bind:this={mapContainer} class="map-container"></div>

<style>
	.map-container {
		width: 100%;
		height: 100%;
		min-height: 400px;
	}

	:global(.layer-control) {
		padding: 4px;
		min-width: 150px;
	}

	:global(.layer-toggle) {
		display: block;
		width: 100%;
		padding: 8px;
		margin: 2px 0;
		background: #fff;
		border: 1px solid #ccc;
		border-radius: 4px;
		cursor: pointer;
		white-space: normal;
		word-wrap: break-word;
		text-align: left;
		line-height: 1.2;
		font-size: 12px;
	}

	:global(.layer-toggle.active) {
		background: #0074d9;
		color: white;
	}
</style>
