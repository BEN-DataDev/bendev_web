<script lang="ts">
	import { getContext, onMount } from 'svelte';
	import type L from 'leaflet';
	import type { Writable } from 'svelte/store';

	interface LayerInfo {
		layer: L.Layer;
		visible: boolean;
		editable: boolean;
		showInLegend: boolean;
		legendInfo: { items: unknown[] };
	}

	interface LeafletContext {
		getLeaflet: () => typeof L;
		getLeafletMap: () => L.Map;
		getLeafletLayers: () => Writable<Record<string, LayerInfo>>;
	}

	interface Props {
		onCapture?: (geometry: GeoJSON.Geometry | null) => void;
	}

	let { onCapture }: Props = $props();

	const { getLeafletMap } = getContext<LeafletContext>('leafletContext');

	onMount(() => {
		const map = getLeafletMap();
		if (!map) return;

		function getGeometry(): GeoJSON.Geometry | null {
			const layers = map.pm.getGeomanLayers();
			if (layers.length === 0) return null;
			// For a project boundary, take the first layer.
			const feature = (layers[0] as unknown as { toGeoJSON: () => GeoJSON.Feature }).toGeoJSON();
			return feature.geometry ?? null;
		}

		function update() {
			onCapture?.(getGeometry());
		}

		map.on('pm:create', (e: unknown) => {
			const ev = e as { layer: L.Layer };
			// Listen for vertex edits on the newly drawn layer
			(ev.layer as unknown as { on: (event: string, fn: () => void) => void }).on(
				'pm:update',
				update
			);
			update();
		});

		map.on('pm:remove', update);
		// Fires on the map when any pm layer is edited (vertex drag, shape drag)
		map.on('pm:update', update);
		map.on('pm:dragend', update);

		return () => {
			map.off('pm:create', update);
			map.off('pm:remove', update);
			map.off('pm:update', update);
			map.off('pm:dragend', update);
		};
	});
</script>
