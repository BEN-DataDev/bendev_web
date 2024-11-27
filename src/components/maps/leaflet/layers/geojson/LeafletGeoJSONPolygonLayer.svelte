<script lang="ts">
	import { onMount, onDestroy, getContext, mount } from 'svelte';
	import type { Writable } from 'svelte/store';
	import type L from 'leaflet';
	import LeafletCustomPolygon from '$components/maps/leaflet/symbology/LeafletCustomPolygon.svelte';

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

	interface PolygonOptions extends L.PathOptions {
		fillColour?: string;
		fillOpacity?: number;
		colour?: string;
		weight?: number;
	}

	type PolygonStyleFunction = (feature: GeoJSON.Feature) => PolygonOptions;

	interface Props {
		geojsonData: GeoJSON.FeatureCollection;
		layerName: string;
		visible: boolean;
		editable: boolean;
		staticLayer: boolean;
		showInLegend: boolean;
		polygonOptions?: PolygonOptions | PolygonStyleFunction;
		propertyForStyle?: string;
		styleMap?: Record<string, PolygonOptions>;
	}

	let {
		geojsonData,
		layerName,
		visible = true,
		editable = false,
		staticLayer = false,
		showInLegend = true,
		polygonOptions = {},
		propertyForStyle,
		styleMap = {}
	}: Props = $props();

	const { getLeaflet, getLeafletMap, getLeafletLayers, getLayersControl } = getContext<{
		getLeaflet: () => typeof L;
		getLeafletMap: () => L.Map;
		getLeafletLayers: () => Writable<Record<string, LayerInfo>>;
		getLayersControl: () => Writable<L.Control.Layers | null>;
	}>('leafletContext');

	let leaflet: typeof L;
	let map: L.Map;
	let layersStore: Writable<Record<string, LayerInfo>>;
	let layersControl: Writable<L.Control.Layers | null>;

	let geoJSONLayer: L.GeoJSON;

	onMount(() => {
		leaflet = getLeaflet();
		map = getLeafletMap();
		layersStore = getLeafletLayers();
		layersControl = getLayersControl();
		if (leaflet && map) {
			createGeoJSONLayer();
			// setupGeomanControls();
		}
	});

	function getPolygonOptions(feature: GeoJSON.Feature): PolygonOptions {
		if (typeof polygonOptions === 'function') {
			return polygonOptions(feature);
		}
		if (propertyForStyle && feature.properties && feature.properties[propertyForStyle]) {
			const styleKey = feature.properties[propertyForStyle];
			return { ...polygonOptions, ...styleMap[styleKey] };
		}
		return polygonOptions;
	}

	function createGeoJSONLayer() {
		geoJSONLayer = leaflet.geoJSON(geojsonData, {
			style: (feature) => getPolygonOptions(feature as GeoJSON.Feature<GeoJSON.Geometry, any>)
		});
		geoJSONLayer.addTo(map);

		let legendItems: LegendItem[];
		if (typeof polygonOptions === 'function') {
			legendItems = geojsonData.features.map((feature) => {
				const options = polygonOptions(feature as GeoJSON.Feature<GeoJSON.Geometry, any>);
				return {
					symbol: createLegendSymbol(options),
					description:
						feature.properties && propertyForStyle
							? feature.properties[propertyForStyle]
							: 'Feature'
				};
			});
		} else if (propertyForStyle && Object.keys(styleMap).length > 0) {
			legendItems = Object.entries(styleMap).map(([key, value]) => ({
				symbol: createLegendSymbol({ ...polygonOptions, ...value }),
				description: key
			}));
		} else {
			legendItems = [
				{
					symbol: createLegendSymbol(polygonOptions),
					description: layerName
				}
			];
		}

		const legendInfo: LegendInfo = {
			items: legendItems
		};

		layersStore.update((layers) => ({
			...layers,
			[layerName]: {
				layer: geoJSONLayer,
				visible: visible,
				editable: editable,
				showInLegend: showInLegend,
				legendInfo: legendInfo
			}
		}));
		if (!staticLayer) {
			layersControl.subscribe((control) => {
				if (control) {
					control.addOverlay(geoJSONLayer, layerName);
				}
			});
		}
		if (editable) {
			enableEditing();
		}
	}

	function createLegendSymbol(options: PolygonOptions): string {
		const container = document.createElement('div');
		mount(LeafletCustomPolygon, {
			target: container,
			props: options as { [key: string]: any }
		});
		console.log('container', container.innerHTML);
		return container.innerHTML.trim();
	}

	function enableEditing() {
		geoJSONLayer.pm.enable({
			allowSelfIntersection: false
		});
	}

	function disableEditing() {
		geoJSONLayer.pm.disable();
	}

	function setupGeomanControls() {
		const actions = ['add', 'edit', 'delete'] as const;
		actions.forEach((action) => {
			map.pm.Toolbar.createCustomControl({
				name: `${layerName}-${action}`,
				block: 'custom',
				title: `${action.charAt(0).toUpperCase() + action.slice(1)} ${layerName}`,
				onClick: () => handleGeomanAction(action),
				toggle: true,
				className: `custom-geoman-${action}-icon`
			});
		});
	}

	function handleGeomanAction(action: 'add' | 'edit' | 'delete') {
		switch (action) {
			case 'add':
				geoJSONLayer.pm.enable();
				break;
			case 'edit':
				enableEditing();
				break;
			case 'delete':
				geoJSONLayer.pm.enable();
				break;
		}
	}

	$effect(() => {
		if (geoJSONLayer) {
			if (editable) {
				enableEditing();
			} else {
				disableEditing();
			}
		}
	});

	$effect(() => {
		if (geoJSONLayer && geojsonData) {
			geoJSONLayer.clearLayers();
			geoJSONLayer.addData(geojsonData);
		}
	});

	onDestroy(() => {
		if (geoJSONLayer) {
			geoJSONLayer.remove();
			layersStore.update((layers) => {
				const { [layerName]: _, ...rest } = layers;
				return rest;
			});
			if (!staticLayer) {
				layersControl.subscribe((control) => {
					if (control) {
						control.removeLayer(geoJSONLayer);
					}
				});
			}
			disableEditing();
		}
	});
</script>
