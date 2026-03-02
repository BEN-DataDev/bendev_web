<script lang="ts">
	import AttachmentUpload from './AttachmentUpload.svelte';

	export interface Attachment {
		id: string;
		file_name: string;
		file_path: string;
		file_type: string;
		file_size: number | null;
		category: 'document' | 'image' | 'report' | 'data' | 'other';
		description: string | null;
		created_at: string;
		public_url: string | null;
	}

	interface Props {
		attachments: Attachment[];
		projectId: string;
		canEdit: boolean;
		onAttachmentsChanged: () => void;
	}

	let { attachments, projectId, canEdit, onAttachmentsChanged }: Props = $props();

	let showUpload = $state(false);
	let pendingDeleteId = $state<string | null>(null);
	let actionError = $state<string | null>(null);

	function formatSize(bytes: number | null): string {
		if (!bytes) return '—';
		if (bytes < 1024) return `${bytes} B`;
		if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
		return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
	}

	async function downloadAttachment(a: Attachment) {
		if (a.public_url) {
			window.open(a.public_url, '_blank');
			return;
		}

		const res = await fetch(`/api/projects/${projectId}/attachments/${a.id}`);
		if (!res.ok) {
			actionError = 'Failed to get download link.';
			return;
		}
		const { url } = (await res.json()) as { url: string };
		window.open(url, '_blank');
	}

	async function deleteAttachment(attachmentId: string) {
		actionError = null;
		const res = await fetch(`/api/projects/${projectId}/attachments/${attachmentId}`, {
			method: 'DELETE'
		});
		if (!res.ok) {
			actionError = 'Failed to delete attachment.';
			pendingDeleteId = null;
			return;
		}
		pendingDeleteId = null;
		onAttachmentsChanged();
	}

	// Show all non-image categories in the list; images are handled by ImageGallery
	const listed = $derived(attachments.filter((a) => a.category !== 'image'));
</script>

<div class="space-y-3">
	{#if actionError}
		<p class="text-xs text-error-500">{actionError}</p>
	{/if}

	{#if listed.length === 0 && !showUpload}
		<p class="text-sm text-surface-500">No documents yet.</p>
	{/if}

	{#each listed as a (a.id)}
		<div class="card preset-outlined-surface-200-800 p-2">
			<div class="flex items-start gap-2">
				<!-- File info -->
				<div class="min-w-0 flex-1">
					<p class="truncate text-sm font-medium" title={a.file_name}>{a.file_name}</p>
					<p class="text-xs text-surface-400">
						{a.category} · {formatSize(a.file_size)}
					</p>
					{#if a.description}
						<p class="mt-0.5 text-xs text-surface-500">{a.description}</p>
					{/if}
				</div>

				<!-- Actions -->
				<div class="flex shrink-0 gap-1">
					<button
						class="btn preset-tonal-surface btn-sm px-1"
						onclick={() => downloadAttachment(a)}
						title="Download"
					>
						↓
					</button>

					{#if canEdit}
						{#if pendingDeleteId === a.id}
							<button
								class="btn preset-tonal-error btn-sm px-1"
								onclick={() => deleteAttachment(a.id)}
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
								onclick={() => (pendingDeleteId = a.id)}
								title="Delete"
							>
								🗑
							</button>
						{/if}
					{/if}
				</div>
			</div>
		</div>
	{/each}

	<!-- Upload form -->
	{#if showUpload}
		<AttachmentUpload
			{projectId}
			onUploaded={() => {
				showUpload = false;
				onAttachmentsChanged();
			}}
			onCancel={() => (showUpload = false)}
		/>
	{:else if canEdit}
		<button
			class="btn preset-tonal-surface btn-sm w-full"
			onclick={() => (showUpload = true)}
		>
			+ Add Attachment
		</button>
	{/if}
</div>
