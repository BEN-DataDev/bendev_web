<script lang="ts">
	import LayerStyleEditor, { type LayerStyle } from './LayerStyleEditor.svelte';
	import LayerUpload from './LayerUpload.svelte';

	export interface ProjectLayer {
		id: string;
		name: string;
		layer_type: string;
		visible: boolean;
		display_order: number;
		style: LayerStyle | null;
		source_url: string | null;
		geojson: GeoJSON.FeatureCollection | null;
	}

	interface Props {
		layers: ProjectLayer[];
		projectId: string;
		canEdit: boolean;
		onLayersChanged: () => void;
	}

	let { layers, projectId, canEdit, onLayersChanged }: Props = $props();

	let showUpload = $state(false);
	let editingStyleId = $state<string | null>(null);
	let pendingDeleteId = $state<string | null>(null);
	let actionError = $state<string | null>(null);

	async function toggleVisible(layer: ProjectLayer) {
		actionError = null;
		const res = await fetch(`/api/projects/${projectId}/layers/${layer.id}`, {
			method: 'PUT',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ visible: !layer.visible })
		});
		if (!res.ok) {
			actionError = 'Failed to update visibility.';
			return;
		}
		onLayersChanged();
	}

	async function moveLayer(layer: ProjectLayer, direction: 'up' | 'down') {
		actionError = null;
		const sorted = [...layers].sort((a, b) => a.display_order - b.display_order);
		const idx = sorted.findIndex((l) => l.id === layer.id);
		const swapIdx = direction === 'up' ? idx - 1 : idx + 1;
		if (swapIdx < 0 || swapIdx >= sorted.length) return;

		const targetOrder = sorted[swapIdx].display_order;
		const currentOrder = layer.display_order;

		// Swap display_order values
		await Promise.all([
			fetch(`/api/projects/${projectId}/layers/${layer.id}`, {
				method: 'PUT',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ display_order: targetOrder })
			}),
			fetch(`/api/projects/${projectId}/layers/${sorted[swapIdx].id}`, {
				method: 'PUT',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ display_order: currentOrder })
			})
		]);

		onLayersChanged();
	}

	async function deleteLayer(layerId: string) {
		actionError = null;
		const res = await fetch(`/api/projects/${projectId}/layers/${layerId}`, {
			method: 'DELETE'
		});
		if (!res.ok) {
			actionError = 'Failed to delete layer.';
			pendingDeleteId = null;
			return;
		}
		pendingDeleteId = null;
		onLayersChanged();
	}

	function handleStyleSaved(layerId: string, style: LayerStyle) {
		editingStyleId = null;
		onLayersChanged();
	}

	const sortedLayers = $derived([...layers].sort((a, b) => a.display_order - b.display_order));
</script>

<div class="space-y-3">
	{#if actionError}
		<p class="text-xs text-error-500">{actionError}</p>
	{/if}

	{#if sortedLayers.length === 0 && !showUpload}
		<p class="text-sm text-surface-500">No layers yet.</p>
	{/if}

	{#each sortedLayers as layer, i (layer.id)}
		<div class="card preset-outlined-surface-200-800 space-y-2 p-2">
			<!-- Layer row -->
			<div class="flex items-center gap-2">
				<!-- Visibility toggle -->
				<input
					type="checkbox"
					class="checkbox"
					checked={layer.visible}
					onchange={() => toggleVisible(layer)}
					title={layer.visible ? 'Hide layer' : 'Show layer'}
					disabled={!canEdit}
				/>

				<!-- Layer name + type -->
				<span class="min-w-0 flex-1 truncate text-sm font-medium" title={layer.name}>
					{layer.name}
				</span>
				<span class="shrink-0 text-xs text-surface-400">{layer.layer_type}</span>

				<!-- Per-layer GeoJSON export -->
				<a
					href="/api/projects/{projectId}/export?layer={layer.id}"
					class="btn preset-tonal-surface btn-sm px-1"
					title="Export layer as GeoJSON"
				>
					↓
				</a>

				{#if canEdit}
					<!-- Reorder -->
					<button
						class="btn preset-tonal-surface btn-sm px-1"
						onclick={() => moveLayer(layer, 'up')}
						disabled={i === 0}
						title="Move up"
					>
						↑
					</button>
					<button
						class="btn preset-tonal-surface btn-sm px-1"
						onclick={() => moveLayer(layer, 'down')}
						disabled={i === sortedLayers.length - 1}
						title="Move down"
					>
						↓
					</button>

					<!-- Style edit -->
					<button
						class="btn preset-tonal-surface btn-sm px-1"
						onclick={() => (editingStyleId = editingStyleId === layer.id ? null : layer.id)}
						title="Edit style"
					>
						🎨
					</button>

					<!-- Delete -->
					{#if pendingDeleteId === layer.id}
						<button
							class="btn preset-tonal-error btn-sm px-1"
							onclick={() => deleteLayer(layer.id)}
							title="Confirm delete"
						>
							✓
						</button>
						<button
							class="btn preset-tonal-surface btn-sm px-1"
							onclick={() => (pendingDeleteId = null)}
							title="Cancel"
						>
							✕
						</button>
					{:else}
						<button
							class="btn preset-tonal-error btn-sm px-1"
							onclick={() => (pendingDeleteId = layer.id)}
							title="Delete layer"
						>
							🗑
						</button>
					{/if}
				{/if}
			</div>

			<!-- Inline style editor -->
			{#if editingStyleId === layer.id}
				<LayerStyleEditor
					layerId={layer.id}
					{projectId}
					initialStyle={layer.style}
					onSaved={(style) => handleStyleSaved(layer.id, style)}
					onCancel={() => (editingStyleId = null)}
				/>
			{/if}
		</div>
	{/each}

	<!-- Upload form -->
	{#if showUpload}
		<LayerUpload
			{projectId}
			onUploaded={() => {
				showUpload = false;
				onLayersChanged();
			}}
			onCancel={() => (showUpload = false)}
		/>
	{:else if canEdit}
		<button
			class="btn preset-tonal-surface btn-sm w-full"
			onclick={() => (showUpload = true)}
		>
			+ Add Layer
		</button>
	{/if}
</div>
