<script lang="ts">
	import type { Attachment } from './AttachmentList.svelte';

	interface Props {
		attachments: Attachment[];
	}

	let { attachments }: Props = $props();

	const images = $derived(attachments.filter((a) => a.category === 'image' && a.public_url));
</script>

{#if images.length > 0}
	<div class="space-y-2">
		<p class="text-xs font-medium uppercase text-surface-500">Images</p>
		<div class="grid grid-cols-2 gap-2">
			{#each images as img (img.id)}
				<a
					href={img.public_url}
					target="_blank"
					rel="noopener noreferrer"
					class="group block overflow-hidden rounded border border-surface-200 dark:border-surface-700"
					title={img.file_name}
				>
					<img
						src={img.public_url}
						alt={img.file_name}
						class="h-24 w-full object-cover transition-opacity group-hover:opacity-80"
						loading="lazy"
					/>
					{#if img.description}
						<p class="truncate px-1 py-0.5 text-xs text-surface-500">{img.description}</p>
					{/if}
				</a>
			{/each}
		</div>
	</div>
{/if}
