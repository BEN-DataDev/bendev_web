<script lang="ts">
	import { setContext } from 'svelte';
	import 'leaflet/dist/leaflet.css';
	import '$components/maps/leaflet/custom-leaflet.css';
	import type L from 'leaflet';
	import { writable, type Writable } from 'svelte/store';

	interface ControlInfo {
		present: boolean;
		position?: L.ControlPosition;
	}

	interface LegendItem {
		symbol: string;
		description: string;
	}

	interface GroupedLegendItem {
		groupName: string;
		items: LegendItem[];
	}

	interface LegendInfo {
		items: (LegendItem | GroupedLegendItem)[];
	}

	interface LayerInfo {
		layer: L.Layer;
		visible: boolean;
		editable: boolean;
		showInLegend: boolean;
		legendInfo: LegendInfo;
	}

	interface Props {
		centre?: L.LatLngExpression | [number, number] | undefined;
		bounds?: L.LatLngBoundsExpression | [[number, number], [number, number]] | undefined;
		zoom?: number | undefined;
		minZoom?: number | undefined;
		maxZoom?: number | undefined;
		zoomable?: boolean;
		zoomSnap?: number;
		attributionControl?: ControlInfo;
		layersControl?: ControlInfo;
		editControl?: ControlInfo;
		width?: string;
		height?: string;
		baseLayers: Array<{ name: string; url: string; attribution: string }>;
		children?: import('svelte').Snippet;
	}

	const {
		centre = undefined,
		zoom = undefined,
		bounds = undefined,
		minZoom = undefined,
		maxZoom = undefined,
		zoomable = true,
		zoomSnap = 0.25,
		attributionControl = { present: true },
		layersControl = { present: false, position: 'topright' },
		editControl = { present: false },
		width = '100%',
		height = '98%',
		baseLayers,
		children
	}: Props = $props();

	const boxZoom = zoomable;
	const doubleClickZoom = zoomable;
	const touchZoom = zoomable;
	const dragging = zoomable;
	const zoomDelta = zoomSnap;
	const scrollWheelZoom = zoomable;
	const keyboard = zoomable;
	const zoomControl = zoomable;

	let style = $derived(`width:${width};height:${height};`);

	let mapDiv: HTMLDivElement;
	let leaflet = $state<typeof L>();
	let leafletMap = $state<L.Map>();
	let layersControlInstance: L.Control.Layers;

	const leafletStore: Writable<typeof L | null> = writable(null);
	const mapStore: Writable<L.Map | null> = writable(null);
	const layersControlStore: Writable<L.Control.Layers | null> = writable(null);
	const layersStore: Writable<Record<string, LayerInfo>> = writable({});

	setContext('leafletContext', {
		getLeaflet: () => leaflet,
		getLeafletMap: () => leafletMap,
		getLeafletLayers: () => layersStore,
		getLayersControl: () => layersControlStore
	});

	$effect(() => {
		if (typeof window !== 'undefined') {
			import('leaflet').then((leaflet) => {
				if (mapDiv && leaflet) {
					leafletMap = leaflet.map(mapDiv, {
						minZoom,
						maxZoom,
						zoomSnap,
						zoomDelta,
						boxZoom,
						doubleClickZoom,
						touchZoom,
						scrollWheelZoom,
						dragging,
						keyboard,
						zoomControl,
						attributionControl: attributionControl.present
					});

					// Add the first base layer immediately
					const defaultBaseLayer = leaflet
						.tileLayer(baseLayers[0].url, {
							attribution: baseLayers[0].attribution
						})
						.addTo(leafletMap);

					// Initialize layers control with the first base layer
					if (layersControl.present) {
						const baseLayersObj: Record<string, L.Layer> = {};
						baseLayersObj[baseLayers[0].name] = defaultBaseLayer;

						layersControlInstance = leaflet.control
							.layers(baseLayersObj, {}, { position: layersControl.position })
							.addTo(leafletMap);

						// Add remaining base layers to the control
						baseLayers.slice(1).forEach((layer) => {
							const tileLayer = leaflet.tileLayer(layer.url, {
								attribution: layer.attribution
							});
							layersControlInstance.addBaseLayer(tileLayer, layer.name);
						});
					}

					if (bounds) {
						leafletMap.fitBounds(bounds);
					} else if (centre) {
						leafletMap.setView(centre, zoom);
					}

					if (leafletMap && editControl.present) {
						import('@geoman-io/leaflet-geoman-free').then(() => {
							leafletMap?.pm.addControls();
						});
					}

					leafletStore.set(leaflet);
					mapStore.set(leafletMap);
					layersControlStore.set(layersControlInstance);
				}
			});
		}
	});

	$effect(() => {
		if (leafletMap) {
			if (bounds) {
				leafletMap.fitBounds(bounds);
			} else if (centre) {
				leafletMap.setView(centre, zoom);
			}
		}
	});
</script>

<div bind:this={mapDiv} {style}>
	{#if leaflet && leafletMap}
		{@render children?.()}
	{/if}
</div>

<style>
	div {
		border-radius: 4px;
		border: 1px solid #ccc;
	}
</style>
