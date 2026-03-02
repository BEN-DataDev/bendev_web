<script lang="ts">
	import { untrack } from 'svelte';

	export interface LayerStyle {
		colour?: string;
		fillColour?: string;
		fillOpacity?: number;
		weight?: number;
	}

	interface Props {
		layerId: string;
		projectId: string;
		initialStyle: LayerStyle | null;
		onSaved: (style: LayerStyle) => void;
		onCancel: () => void;
	}

	let { layerId, projectId, initialStyle, onSaved, onCancel }: Props = $props();

	// untrack: intentionally capture initial style value for form pre-population
	let colour = $state(untrack(() => initialStyle?.colour ?? '#3b82f6'));
	let fillColour = $state(untrack(() => initialStyle?.fillColour ?? '#3b82f6'));
	let fillOpacity = $state(untrack(() => initialStyle?.fillOpacity ?? 0.3));
	let weight = $state(untrack(() => initialStyle?.weight ?? 2));

	let saving = $state(false);
	let error = $state<string | null>(null);

	async function handleSave(e: Event) {
		e.preventDefault();
		saving = true;
		error = null;

		const style: LayerStyle = { colour, fillColour, fillOpacity, weight };

		try {
			const res = await fetch(`/api/projects/${projectId}/layers/${layerId}`, {
				method: 'PUT',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ style })
			});

			if (!res.ok) throw new Error(`Server error ${res.status}`);

			onSaved(style);
		} catch (e) {
			error = e instanceof Error ? e.message : 'Failed to save style.';
		} finally {
			saving = false;
		}
	}
</script>

<div class="card preset-outlined-surface-200-800 space-y-3 p-3 text-sm">
	<p class="font-medium">Edit Style</p>

	{#if error}
		<p class="text-xs text-error-500">{error}</p>
	{/if}

	<form onsubmit={handleSave} class="space-y-2">
		<div class="grid grid-cols-2 gap-2">
			<!-- Stroke colour -->
			<label class="flex flex-col gap-1">
				<span class="text-xs text-surface-500">Stroke</span>
				<input type="color" bind:value={colour} class="h-8 w-full cursor-pointer rounded" />
			</label>

			<!-- Fill colour -->
			<label class="flex flex-col gap-1">
				<span class="text-xs text-surface-500">Fill</span>
				<input type="color" bind:value={fillColour} class="h-8 w-full cursor-pointer rounded" />
			</label>
		</div>

		<!-- Fill opacity -->
		<label class="flex flex-col gap-1">
			<span class="text-xs text-surface-500">Fill opacity: {Math.round(fillOpacity * 100)}%</span>
			<input
				type="range"
				min="0"
				max="1"
				step="0.05"
				bind:value={fillOpacity}
				class="w-full"
			/>
		</label>

		<!-- Stroke weight -->
		<label class="flex flex-col gap-1">
			<span class="text-xs text-surface-500">Stroke width: {weight}px</span>
			<input type="range" min="1" max="8" step="1" bind:value={weight} class="w-full" />
		</label>

		<div class="flex gap-2 pt-1">
			<button type="submit" class="btn preset-filled-primary-500 btn-sm" disabled={saving}>
				{saving ? 'Saving…' : 'Save'}
			</button>
			<button type="button" class="btn preset-tonal-surface btn-sm" onclick={onCancel}>
				Cancel
			</button>
		</div>
	</form>
</div>
