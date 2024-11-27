<script lang="ts">
	import type { ContentProps } from '$lib/custom.component.types';

	interface Props {
		content: ContentProps['content'];
		customClass?: ContentProps['customClass'];
		loading?: ContentProps['loading'];
		error?: ContentProps['error'];
		metadata?: ContentProps['metadata'];
		actions?: ContentProps['actions'];
	}

	let {
		content,
		customClass = '',
		loading = false,
		error = undefined,
		metadata = undefined,
		actions = []
	}: Props = $props();
</script>

<div class="content-wrapper {customClass}">
	{#if loading}
		<div class="loading-spinner"></div>
	{:else if error}
		<div class="error-message">{error}</div>
	{:else}
		{#if typeof content === 'string'}
			<p>{content}</p>
		{:else}
			{@const SvelteComponent = content}
			<SvelteComponent />
		{/if}

		{#if metadata}
			<div class="metadata">
				{#if metadata.author}
					<span>By {metadata.author}</span>
				{/if}
				{#if metadata.date}
					<span>{metadata.date.toLocaleDateString()}</span>
				{/if}
				{#if metadata.tags?.length}
					<div class="tags">
						{#each metadata.tags as tag}
							<span class="tag">{tag}</span>
						{/each}
					</div>
				{/if}
			</div>
		{/if}

		{#if actions?.length}
			<div class="actions">
				{#each actions as action}
					<button class="btn btn-{action.variant || 'primary'}" onclick={action.handler}>
						{action.label}
					</button>
				{/each}
			</div>
		{/if}
	{/if}
</div>
