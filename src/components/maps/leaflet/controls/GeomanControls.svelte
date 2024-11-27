<script lang="ts">
	import { getContext, onMount } from 'svelte';

	import type L from 'leaflet';
	import type { FeatureGroup } from 'leaflet';
	import type { Writable } from 'svelte/store';

	import '$components/maps/leaflet/leaflet-geoman.css';
	import '$components/maps/leaflet/custom-geoman.css';

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

	interface LeafletContext {
		getLeaflet: () => typeof L;
		getLeafletMap: () => L.Map;
		getLeafletLayers: () => Writable<Record<string, LayerInfo>>;
	}

	const { getLeaflet, getLeafletMap, getLeafletLayers } =
		getContext<LeafletContext>('leafletContext');

	interface Props {
		position?: L.ControlPosition;
		drawMarker?: boolean;
		drawCircleMarker?: boolean;
		drawPolyline?: boolean;
		drawRectangle?: boolean;
		drawPolygon?: boolean;
		drawCircle?: boolean;
		editMode?: boolean;
		dragMode?: boolean;
		cutPolygon?: boolean;
		removalMode?: boolean;
	}

	const {
		position = 'topleft',
		drawMarker = true,
		drawCircleMarker = true,
		drawPolyline = true,
		drawRectangle = true,
		drawPolygon = true,
		drawCircle = true,
		editMode = true,
		dragMode = true,
		cutPolygon = true,
		removalMode = true
	}: Props = $props();

	let leaflet: typeof L;
	let leafletMap: L.Map;
	let layersStore: Writable<Record<string, LayerInfo>>;

	function createLayerControls(layerId: string, layerName: string) {
		const actions = ['Add', 'Edit', 'Delete'];

		const controls: Record<string, any> = {};

		actions.forEach((action) => {
			const controlName = `${layerId}-${action.toLowerCase()}`;
			controls[controlName] = {
				name: controlName,
				block: 'custom',
				title: `${action} ${layerName}`,
				onClick: () =>
					toggleLayerAction(layerId, action.toLowerCase() as 'add' | 'edit' | 'delete'),
				toggle: true,
				className: `custom-geoman-${action.toLowerCase()}-icon`
			};
		});

		return controls;
	}

	function addCustomControlsToGeomanToolbar() {
		layersStore.subscribe((layers) => {
			Object.entries(layers).forEach(([layerId, layerInfo]) => {
				if (layerInfo.editable) {
					const layerControls = createLayerControls(layerId, layerId);
					leafletMap.pm.addControls(layerControls);
				}
			});
		});
	}

	function toggleLayerAction(layerId: string, action: 'add' | 'edit' | 'delete') {
		layersStore.update((layers) => {
			const layer = layers[layerId].layer as FeatureGroup;

			// Disable all actions for all layers
			Object.values(layers).forEach((l) => {
				const featureGroup = l.layer as FeatureGroup;
				if (featureGroup.pm) featureGroup.pm.disable();
			});

			switch (action) {
				case 'add':
					layer.pm.enable();
					break;
				case 'edit':
					layer.pm.enable();
					break;
				case 'delete':
					layer.pm.enable();
					break;
			}

			return layers;
		});
	}

	function makeGeomanToolbarCollapsible() {
		const toolbar = document.querySelector('.leaflet-pm-toolbar');
		if (!toolbar) return;

		// Create collapse button
		const collapseBtn = document.createElement('div');
		collapseBtn.innerHTML = '◀'; // Left arrow character
		collapseBtn.className = 'leaflet-pm-toolbar-collapse-btn';
		toolbar.prepend(collapseBtn);

		// Toggle collapse on button click
		collapseBtn.addEventListener('click', () => {
			toolbar.classList.toggle('collapsed');
			collapseBtn.innerHTML = toolbar.classList.contains('collapsed') ? '▶' : '◀';
		});
	}

	onMount(() => {
		leaflet = getLeaflet();
		leafletMap = getLeafletMap();
		if (leafletMap && leaflet) {
			leafletMap.pm.addControls({
				position,
				drawMarker,
				drawCircleMarker,
				drawPolyline,
				drawRectangle,
				drawPolygon,
				drawCircle,
				editMode,
				dragMode,
				cutPolygon,
				removalMode
			});
			addCustomControlsToGeomanToolbar();
			leafletMap.on('pm:globaleditmodetoggled', makeGeomanToolbarCollapsible);
		}

		return () => {
			if (leafletMap) {
				leafletMap.pm.removeControls();
			}
		};
	});
</script>
