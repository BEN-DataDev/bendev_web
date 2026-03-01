<script lang="ts">
	import Icon from '$components/icons/Icons.svelte';
	import type { LayoutData } from './$types';

	interface Props {
		data: LayoutData;
		children?: import('svelte').Snippet;
	}

	let { data, children }: Props = $props();
	let userId = $derived(data.user?.id);
</script>

<div class="grid h-full grid-cols-1 md:grid-cols-[250px_1fr]">
	<!-- Left sidebar: user navigation -->
	<aside class="border-r border-surface-200 p-4 dark:border-surface-700">
		<div class="mt-4 space-y-4">
			<a
				href="/users/{userId}/profile"
				class="btn preset-tonal-surface-200-800 flex w-full items-center"
			>
				<Icon name="settings" class="me-2 h-4 w-4" />
				My Profile
			</a>
			<a
				href="/users/{userId}/dashboard"
				class="btn preset-tonal-surface-200-800 flex w-full items-center"
			>
				<Icon name="user-circle" class="me-2 h-4 w-4" />
				My Dashboard
			</a>
		</div>
	</aside>

	<!-- Main content -->
	<main class="overflow-auto p-4">
		{@render children?.()}
	</main>
</div>
