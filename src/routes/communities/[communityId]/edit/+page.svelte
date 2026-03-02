<script lang="ts">
	import { enhance } from '$app/forms';
	import { untrack } from 'svelte';
	import ProjectMapView from '$components/maps/ProjectMapView.svelte';
	import type { PageData, ActionData } from './$types';

	interface Props {
		data: PageData;
		form: ActionData;
	}

	let { data, form }: Props = $props();
	let { community } = $derived(data);

	let drawnGeometry = $state(
		untrack(() => (community.boundary ? JSON.stringify(community.boundary) : ''))
	);

	const existingGeometry = $derived(
		community.boundary ? (community.boundary as GeoJSON.Geometry) : null
	);

	function handleGeometryChange(geometry: GeoJSON.Geometry | null) {
		drawnGeometry = geometry ? JSON.stringify(geometry) : '';
	}
</script>

<div class="flex h-full flex-col">
	<header class="border-b border-surface-200 p-4 dark:border-surface-700">
		<div class="flex items-center gap-2">
			<a href="/communities/{community.id}" class="btn preset-tonal-surface btn-sm">← Back</a>
			<h1 class="h3">Edit Community</h1>
		</div>
	</header>

	<div class="flex-1 overflow-y-auto">
		<form method="POST" use:enhance class="grid h-full grid-cols-1 gap-0 lg:grid-cols-2">
			<!-- Left: form fields -->
			<div
				class="space-y-4 overflow-y-auto border-r border-surface-200 p-6 dark:border-surface-700"
			>
				{#if form?.error}
					<p class="text-sm text-error-500">{form.error}</p>
				{/if}

				<label class="block">
					<span class="mb-1 block text-sm font-medium"
						>Community Name <span class="text-error-500">*</span></span
					>
					<input
						type="text"
						name="name"
						class="input w-full"
						required
						value={community.name}
					/>
				</label>

				<label class="flex items-center gap-2">
					<input type="checkbox" name="public" class="checkbox" checked={community.public} />
					<span class="text-sm">Make community public</span>
				</label>

				<p class="text-xs text-surface-500">
					Redraw the boundary on the map to update it, or leave as-is to keep the current boundary.
				</p>

				<input type="hidden" name="extent_geojson" value={drawnGeometry} />

				<button type="submit" class="btn preset-filled-primary-500 w-full">Save Changes</button>
			</div>

			<!-- Right: map (shows existing boundary, editable) -->
			<div class="h-[400px] lg:h-full">
				<ProjectMapView
					geometry={existingGeometry}
					editable={true}
					onGeometryChange={handleGeometryChange}
				/>
			</div>
		</form>
	</div>
</div>
