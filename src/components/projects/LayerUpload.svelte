<script lang="ts">
	import type shpjs from 'shpjs';
	import type { kml } from '@tmcw/togeojson';

	interface Props {
		projectId: string;
		onUploaded: () => void;
		onCancel: () => void;
	}

	let { projectId, onUploaded, onCancel }: Props = $props();

	let name = $state('');
	let file = $state<File | null>(null);
	let converting = $state(false);
	let uploading = $state(false);
	let error = $state<string | null>(null);
	let featureCount = $state<number | null>(null);
	let convertedGeojson = $state<GeoJSON.FeatureCollection | null>(null);

	const ACCEPT = '.geojson,.json,.zip,.kml,.gpx';

	async function convertFile(f: File): Promise<GeoJSON.FeatureCollection> {
		const lower = f.name.toLowerCase();

		if (lower.endsWith('.geojson') || lower.endsWith('.json')) {
			const text = await f.text();
			const parsed = JSON.parse(text) as GeoJSON.GeoJSON;
			if (parsed.type === 'FeatureCollection') return parsed;
			if (parsed.type === 'Feature') {
				return { type: 'FeatureCollection', features: [parsed as GeoJSON.Feature] };
			}
			// Plain geometry
			return {
				type: 'FeatureCollection',
				features: [{ type: 'Feature', geometry: parsed as GeoJSON.Geometry, properties: {} }]
			};
		}

		if (lower.endsWith('.zip')) {
			const { default: shp } = await import('shpjs');
			const buffer = await f.arrayBuffer();
			const result = await (shp as typeof shpjs)(buffer);
			if (Array.isArray(result)) {
				const allFeatures = result.flatMap((fc) => fc.features);
				return { type: 'FeatureCollection', features: allFeatures };
			}
			return result as GeoJSON.FeatureCollection;
		}

		if (lower.endsWith('.kml') || lower.endsWith('.gpx')) {
			const { kml: convertKml, gpx: convertGpx } = await import('@tmcw/togeojson');
			const text = await f.text();
			const doc = new DOMParser().parseFromString(text, 'text/xml');
			const convert = lower.endsWith('.kml') ? (convertKml as typeof kml) : convertGpx;
			return convert(doc) as GeoJSON.FeatureCollection;
		}

		throw new Error(`Unsupported file type: ${f.name}`);
	}

	async function handleFileChange(e: Event) {
		const input = e.currentTarget as HTMLInputElement;
		const selected = input.files?.[0] ?? null;
		file = selected;
		convertedGeojson = null;
		featureCount = null;
		error = null;

		if (!selected) return;

		// Auto-fill name from filename (strip extension)
		if (!name) {
			name = selected.name.replace(/\.[^/.]+$/, '');
		}

		converting = true;
		try {
			const fc = await convertFile(selected);
			convertedGeojson = fc;
			featureCount = fc.features.length;
		} catch (e) {
			error = e instanceof Error ? e.message : 'Failed to read file.';
			convertedGeojson = null;
		} finally {
			converting = false;
		}
	}

	async function handleSubmit(e: Event) {
		e.preventDefault();
		if (!name.trim() || !convertedGeojson) return;

		uploading = true;
		error = null;
		try {
			const res = await fetch(`/api/projects/${projectId}/layers`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({
					name: name.trim(),
					layer_type: 'geojson',
					geojson: convertedGeojson
				})
			});

			if (!res.ok) {
				const msg = await res.text();
				throw new Error(msg || `Server error ${res.status}`);
			}

			onUploaded();
		} catch (e) {
			error = e instanceof Error ? e.message : 'Upload failed.';
		} finally {
			uploading = false;
		}
	}

	const canSubmit = $derived(!!name.trim() && !!convertedGeojson && !converting && !uploading);
</script>

<div class="card preset-outlined-surface-200-800 space-y-4 p-4">
	<h3 class="h5 font-semibold">Add Layer</h3>

	{#if error}
		<p class="text-sm text-error-500">{error}</p>
	{/if}

	<form onsubmit={handleSubmit} class="space-y-3">
		<!-- File input -->
		<div>
			<label class="label mb-1 block text-sm font-medium" for="layer-file">
				File <span class="text-xs text-surface-400">(.geojson, .json, .zip shapefile, .kml, .gpx)</span>
			</label>
			<input
				id="layer-file"
				type="file"
				accept={ACCEPT}
				class="input w-full text-sm"
				onchange={handleFileChange}
				disabled={converting || uploading}
			/>
			{#if converting}
				<p class="mt-1 text-xs text-surface-500">Converting…</p>
			{:else if featureCount !== null}
				<p class="mt-1 text-xs text-success-600 dark:text-success-400">
					{featureCount} feature{featureCount === 1 ? '' : 's'} ready
				</p>
			{/if}
		</div>

		<!-- Layer name -->
		<div>
			<label class="label mb-1 block text-sm font-medium" for="layer-name">Layer name</label>
			<input
				id="layer-name"
				type="text"
				class="input w-full"
				placeholder="e.g. Vegetation Survey 2024"
				bind:value={name}
				disabled={uploading}
				required
			/>
		</div>

		<!-- Actions -->
		<div class="flex gap-2">
			<button
				type="submit"
				class="btn preset-filled-primary-500 btn-sm"
				disabled={!canSubmit}
			>
				{uploading ? 'Uploading…' : 'Upload'}
			</button>
			<button
				type="button"
				class="btn preset-tonal-surface btn-sm"
				onclick={onCancel}
				disabled={uploading}
			>
				Cancel
			</button>
		</div>
	</form>
</div>
