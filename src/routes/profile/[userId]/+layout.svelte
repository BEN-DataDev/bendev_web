<script lang="ts">
	import type { LayoutData } from './$types';

	interface Props {
		data: LayoutData;
		children?: import('svelte').Snippet;
	}

	let { data, children }: Props = $props();
	let { session, supabase, user, roles } = $derived(data);
</script>

<!-- <main class="flex-1 overflow-y-auto p-4"> -->
{@render children?.()}
<!-- </main> -->
