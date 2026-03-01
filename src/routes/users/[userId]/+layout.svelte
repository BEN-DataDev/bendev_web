<script lang="ts">
	import { page } from '$app/stores';
	import { Navigation } from '@skeletonlabs/skeleton-svelte';
	import { browser } from '$app/environment';
	import Icon from '$components/icons/Icons.svelte';

	import type { LayoutData } from './$types';

	interface Props {
		data: LayoutData;
		children?: import('svelte').Snippet;
	}

	let { data, children }: Props = $props();
	let userId = $derived(data.user?.id);
	let pathName = $derived($page.url.pathname);

	// Responsive layout detection
	let innerWidth = $state(0);
	let navLayout = $derived<'bar' | 'rail' | 'sidebar'>(
		innerWidth < 768 ? 'bar' : innerWidth < 1024 ? 'rail' : 'sidebar'
	);

	$effect(() => {
		if (browser) {
			innerWidth = window.innerWidth;
			const handleResize = () => {
				innerWidth = window.innerWidth;
			};
			window.addEventListener('resize', handleResize);
			return () => window.removeEventListener('resize', handleResize);
		}
	});
</script>

<div class="grid h-full {navLayout === 'bar' ? 'grid-rows-[1fr_auto]' : 'md:grid-cols-[auto_1fr]'}">
	<!-- Main Content (on mobile, comes first; on desktop, comes second) -->
	<div class="overflow-auto p-4 {navLayout === 'bar' ? 'order-1' : 'order-2'}">
		{@render children?.()}
	</div>

	<!-- Navigation (bottom on mobile, left on desktop) -->
	<Navigation
		layout={navLayout}
		class="bg-surface-100 dark:bg-surface-800 {navLayout === 'bar'
			? 'order-2 border-t border-surface-200 dark:border-surface-700'
			: 'order-1 border-r border-surface-200 dark:border-surface-700'}"
	>
		<Navigation.Content>
			<Navigation.Menu>
				<Navigation.TriggerAnchor
					href="/users/{userId}/dashboard"
					class={pathName === `/users/${userId}/dashboard`
						? 'bg-primary-500/10 text-primary-600 dark:text-primary-400'
						: ''}
				>
					<Icon name="user" class="h-5 w-5" />
					<Navigation.TriggerText>Dashboard</Navigation.TriggerText>
				</Navigation.TriggerAnchor>

				<Navigation.TriggerAnchor
					href="/users/{userId}/profile"
					class={pathName === `/users/${userId}/profile`
						? 'bg-primary-500/10 text-primary-600 dark:text-primary-400'
						: ''}
				>
					<Icon name="user" class="h-5 w-5" />
					<Navigation.TriggerText>Profile</Navigation.TriggerText>
				</Navigation.TriggerAnchor>

				<Navigation.TriggerAnchor
					href="/users/{userId}/communities"
					class={pathName === `/users/${userId}/communities`
						? 'bg-primary-500/10 text-primary-600 dark:text-primary-400'
						: ''}
				>
					<Icon name="user" class="h-5 w-5" />
					<Navigation.TriggerText>Communities</Navigation.TriggerText>
				</Navigation.TriggerAnchor>
			</Navigation.Menu>
		</Navigation.Content>
	</Navigation>
</div>
