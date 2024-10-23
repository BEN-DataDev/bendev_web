<script lang="ts">
	import type { LayoutData } from './$types';

	interface Props {
		data: LayoutData;
		children?: import('svelte').Snippet;
	}

	let { data, children }: Props = $props();
	let { session, supabase, user, roles } = $derived(data);
</script>

<div class="app-shell">
	<div class="app-shell-main">
		<div class="app-shell-sidebar-left w-1/6">
			<div class="flex w-full flex-col p-1">
				<div class="flex flex-row justify-around pt-2 text-xl">Profile Menu</div>
				<div class="flex flex-col rounded-lg bg-orange-600">
					<p>siderbarMenuItems</p>
				</div>
				<p class="ml-2">
					Please make sure you click every heading in the menu on the left <br />
					<b>and</b>
					check your answers to all the questions.
				</p>
				<p class="ml-2">
					Remember this is <b>your</b>
					data. To help keep
					<b>you</b>
					prepared.
				</p>
			</div>
		</div>
		<main class="flex-1 overflow-y-auto p-4">
			{@render children?.()}
		</main>
		<div class="app-shell-sidebar-right w-1/6">
			<p>messagesData</p>
		</div>
	</div>
</div>

<style lang="postcss">
	.app-shell {
		display: flex;
		flex-direction: column;
		height: 100%;
	}

	.app-shell-main {
		display: flex;
		flex: 1;
		overflow: hidden;
	}

	.app-shell-sidebar-left,
	.app-shell-sidebar-right {
		overflow-y: auto;
	}
</style>
