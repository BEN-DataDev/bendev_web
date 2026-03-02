<script lang="ts">
	import type L from 'leaflet';
	import LeafletMap from '$components/maps/leaflet/LeafletMap.svelte';
	import LeafletGeoJSONPolygonLayer from '$components/maps/leaflet/layers/geojson/LeafletGeoJSONPolygonLayer.svelte';
	import GeomanControls from '$components/maps/leaflet/controls/GeomanControls.svelte';
	import GeomanBoundaryCapture from '$components/maps/leaflet/controls/GeomanBoundaryCapture.svelte';
	import type { ProjectLayer } from '$components/projects/LayerPanel.svelte';
	import type { LayerStyle } from '$components/projects/LayerStyleEditor.svelte';

	interface Props {
		/** Project boundary to display; auto-fits the map when present. */
		geometry?: GeoJSON.Geometry | null;
		/** Overlay layers to render on top of the boundary. */
		layers?: ProjectLayer[];
		/** Show Geoman drawing controls for boundary editing. */
		editable?: boolean;
		/** Fallback centre when no geometry is present (new project form). */
		defaultCentre?: L.LatLngExpression;
		/** Fallback zoom when no geometry is present. */
		defaultZoom?: number;
		/** Extra classes applied to the outer div (caller sets height, e.g. h-[500px] or h-full). */
		class?: string;
		/** Called whenever the drawn boundary changes (editable mode). */
		onGeometryChange?: (geometry: GeoJSON.Geometry | null) => void;
	}

	const OSM_BASE_LAYERS = [
		{
			name: 'OpenStreetMap',
			url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
			attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
		}
	];

	// Default centre: Snowy Mountains region (matches communities data)
	const DEFAULT_CENTRE: L.LatLngExpression = [-35.7338998511678, 148.249161457376];
	const DEFAULT_ZOOM = 10;

	let {
		geometry = null,
		layers = [],
		editable = false,
		defaultCentre = DEFAULT_CENTRE,
		defaultZoom = DEFAULT_ZOOM,
		class: klass = '',
		onGeometryChange
	}: Props = $props();

	function styleFromLayer(layer: ProjectLayer): Record<string, unknown> {
		const s = layer.style as LayerStyle | null;
		return {
			colour: s?.colour ?? '#6366f1',
			fillColour: s?.fillColour ?? '#6366f1',
			fillOpacity: s?.fillOpacity ?? 0.3,
			weight: s?.weight ?? 2
		};
	}

	/** Compute Leaflet-compatible bounds [[lat_min, lon_min], [lat_max, lon_max]] from GeoJSON. */
	function boundsFromGeometry(
		geom: GeoJSON.Geometry
	): [[number, number], [number, number]] | undefined {
		const pts: [number, number][] = [];

		function walk(g: GeoJSON.Geometry) {
			switch (g.type) {
				case 'Point':
					pts.push([g.coordinates[1], g.coordinates[0]]);
					break;
				case 'MultiPoint':
				case 'LineString':
					g.coordinates.forEach((c) => pts.push([c[1], c[0]]));
					break;
				case 'MultiLineString':
				case 'Polygon':
					g.coordinates.forEach((ring) => ring.forEach((c) => pts.push([c[1], c[0]])));
					break;
				case 'MultiPolygon':
					g.coordinates.forEach((poly) =>
						poly.forEach((ring) => ring.forEach((c) => pts.push([c[1], c[0]])))
					);
					break;
				case 'GeometryCollection':
					g.geometries.forEach(walk);
					break;
			}
		}

		walk(geom);
		if (pts.length === 0) return undefined;

		const lats = pts.map((p) => p[0]);
		const lons = pts.map((p) => p[1]);
		return [
			[Math.min(...lats), Math.min(...lons)],
			[Math.max(...lats), Math.max(...lons)]
		];
	}

	const mapBounds = $derived(geometry ? boundsFromGeometry(geometry) : undefined);

	const boundaryFeatureCollection = $derived(
		geometry
			? ({
					type: 'FeatureCollection',
					features: [{ type: 'Feature', geometry, properties: {} }]
				} as GeoJSON.FeatureCollection)
			: null
	);

	const boundaryStyle = {
		colour: '#3b82f6',
		fillColour: '#3b82f6',
		fillOpacity: 0.15,
		weight: 2
	};
</script>

<div class="h-full {klass}">
	<LeafletMap
		baseLayers={OSM_BASE_LAYERS}
		bounds={mapBounds}
		centre={mapBounds ? undefined : defaultCentre}
		zoom={mapBounds ? undefined : defaultZoom}
		height="100%"
	>
		{#if boundaryFeatureCollection}
			<LeafletGeoJSONPolygonLayer
				geojsonData={boundaryFeatureCollection}
				layerName="Project Boundary"
				visible={true}
				editable={editable}
				staticLayer={true}
				showInLegend={false}
				polygonOptions={boundaryStyle}
			/>
		{/if}
		{#each layers as layer (layer.id)}
			{#if layer.visible && layer.geojson}
				<LeafletGeoJSONPolygonLayer
					geojsonData={layer.geojson}
					layerName={layer.name}
					visible={true}
					editable={false}
					staticLayer={false}
					showInLegend={true}
					polygonOptions={styleFromLayer(layer)}
				/>
			{/if}
		{/each}

		{#if editable}
			<GeomanControls
				drawMarker={false}
				drawCircleMarker={false}
				drawPolyline={false}
				drawCircle={false}
				drawPolygon={true}
				drawRectangle={true}
				editMode={true}
				dragMode={true}
				cutPolygon={true}
				removalMode={true}
			/>
			<GeomanBoundaryCapture onCapture={onGeometryChange} />
		{/if}
	</LeafletMap>
</div>
