<script lang="ts">
	const CATEGORIES = ['document', 'image', 'report', 'data', 'other'] as const;
	type Category = (typeof CATEGORIES)[number];

	interface Props {
		projectId: string;
		onUploaded: () => void;
		onCancel: () => void;
	}

	let { projectId, onUploaded, onCancel }: Props = $props();

	let file = $state<File | null>(null);
	let category = $state<Category>('document');
	let description = $state('');
	let uploading = $state(false);
	let error = $state<string | null>(null);

	function handleFileChange(e: Event) {
		const input = e.currentTarget as HTMLInputElement;
		file = input.files?.[0] ?? null;
		error = null;
		// Auto-select image category when an image file is chosen
		if (file && file.type.startsWith('image/')) {
			category = 'image';
		}
	}

	async function handleSubmit(e: Event) {
		e.preventDefault();
		if (!file) return;

		uploading = true;
		error = null;

		const formData = new FormData();
		formData.append('file', file);
		formData.append('category', category);
		if (description.trim()) {
			formData.append('description', description.trim());
		}

		try {
			const res = await fetch(`/api/projects/${projectId}/attachments`, {
				method: 'POST',
				body: formData
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

	const canSubmit = $derived(!!file && !uploading);
</script>

<div class="card preset-outlined-surface-200-800 space-y-4 p-4">
	<h3 class="h5 font-semibold">Add Attachment</h3>

	{#if error}
		<p class="text-sm text-error-500">{error}</p>
	{/if}

	<form onsubmit={handleSubmit} class="space-y-3">
		<!-- File input -->
		<div>
			<label class="label mb-1 block text-sm font-medium" for="attach-file">File</label>
			<input
				id="attach-file"
				type="file"
				class="input w-full text-sm"
				onchange={handleFileChange}
				disabled={uploading}
			/>
		</div>

		<!-- Category -->
		<div>
			<label class="label mb-1 block text-sm font-medium" for="attach-category">Category</label>
			<select
				id="attach-category"
				class="select w-full"
				bind:value={category}
				disabled={uploading}
			>
				{#each CATEGORIES as cat}
					<option value={cat}>{cat.charAt(0).toUpperCase() + cat.slice(1)}</option>
				{/each}
			</select>
		</div>

		<!-- Description (optional) -->
		<div>
			<label class="label mb-1 block text-sm font-medium" for="attach-desc">
				Description <span class="text-xs text-surface-400">(optional)</span>
			</label>
			<input
				id="attach-desc"
				type="text"
				class="input w-full"
				placeholder="Brief description of this file"
				bind:value={description}
				disabled={uploading}
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
