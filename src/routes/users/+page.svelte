<script lang="ts">
	import { page } from '$app/stores';
	import ResponsiveLayout from '$components/structure/ThreePanelLayout.svelte';
	import { UsersGroupSolid, UserSettingsSolid, UserCircleSolid } from 'flowbite-svelte-icons';
	import { Button } from 'svelte-5-ui-lib';
	import type { PageData } from './$types';

	interface Props {
		data: PageData;
		children?: import('svelte').Snippet;
	}

	let leftSidebarOpen = $state(true);
	let rightSidebarOpen = $state(true);

	let { data }: Props = $props();
	let pathName = $derived($page.url.pathname);
	const userId = data.user?.id;
	$effect(() => {
		console.log('users/[{userId}]/layout.svelte', pathName);
	});
</script>

<ResponsiveLayout
	bind:leftSidebarOpen
	bind:rightSidebarOpen
	leftSidebarWidth="250px"
	rightSidebarWidth="200px"
>
	{#snippet leftSidebarContent()}
		<div class="mt-4 space-y-4">
			{#if pathName !== `/users/${userId}/communities`}
				<Button href="/users/{userId}/communities" color="alternative" class="w-full">
					<UsersGroupSolid class="me-2 h-4 w-4" />
					My Communities
				</Button>
			{/if}

			{#if pathName !== `/users/${userId}/profile`}
				<Button href="/users/{userId}/profile" color="alternative" class="w-full">
					<UserSettingsSolid class="me-2 h-4 w-4" />
					My Profile
				</Button>
			{/if}

			{#if pathName !== `/users/${userId}/dashboard`}
				<Button href="/users/{userId}/dashboard" color="alternative" class="w-full">
					<UserCircleSolid class="me-2 h-4 w-4" />
					My Dashboard
				</Button>
			{/if}
		</div>
	{/snippet}

	// TODO User list & search
	{#snippet righttSidebarContent()}
		<div class="space-y-4">
			<h2 class="text-xl font-semibold text-gray-800">Right Sidebar</h2>
			<div class="rounded-lg bg-white p-4 shadow">
				<p class="text-gray-600">Additional information or widgets can go here.</p>
			</div>
		</div>
	{/snippet}
</ResponsiveLayout>
