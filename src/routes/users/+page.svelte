<script lang="ts">
	import { page } from '$app/stores';
	import Icon from '$components/icons/Icons.svelte';
	import type { PageData } from './$types';

	interface User {
		id: string;
		firstname: string;
		lastname: string;
		bio: string | null;
	}

	interface Props {
		data: PageData;
	}

	let { data }: Props = $props();
	let pathName = $derived($page.url.pathname);
	let userId = $derived(data.user?.id);

	let searchQuery = $state('');

	let filteredUsers = $derived(
		searchQuery
			? (data.users as User[]).filter((u) =>
					`${u.firstname} ${u.lastname}`.toLowerCase().includes(searchQuery.toLowerCase())
				)
			: (data.users as User[])
	);
</script>

<div class="grid h-full grid-cols-1 md:grid-cols-[250px_1fr]">
	<!-- Left sidebar: current user navigation -->
	<aside class="border-r border-surface-200 p-4 dark:border-surface-700">
		<div class="mt-4 space-y-4">
			{#if pathName !== `/users/${userId}/communities`}
				<a
					href="/users/{userId}/communities"
					class="btn preset-tonal-surface-200-800 flex w-full items-center"
				>
					<Icon name="users" class="me-2 h-4 w-4" />
					My Communities
				</a>
			{/if}

			{#if pathName !== `/users/${userId}/profile`}
				<a
					href="/users/{userId}/profile"
					class="btn preset-tonal-surface-200-800 flex w-full items-center"
				>
					<Icon name="settings" class="me-2 h-4 w-4" />
					My Profile
				</a>
			{/if}

			{#if pathName !== `/users/${userId}/dashboard`}
				<a
					href="/users/{userId}/dashboard"
					class="btn preset-tonal-surface-200-800 flex w-full items-center"
				>
					<Icon name="user-circle" class="me-2 h-4 w-4" />
					My Dashboard
				</a>
			{/if}
		</div>
	</aside>

	<!-- Main content: user directory -->
	<main class="overflow-auto p-6">
		<div class="space-y-4">
			<h2 class="h3">User Directory</h2>

			<input
				type="search"
				class="input"
				placeholder="Search by name..."
				bind:value={searchQuery}
			/>

			<div class="space-y-2">
				{#each filteredUsers as user (user.id)}
					<a
						href="/users/{user.id}/profile"
						class="card preset-outlined-surface-200-800 flex items-center gap-3 p-3 hover:bg-surface-100 dark:hover:bg-surface-800"
					>
						<div
							class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-surface-200 text-sm font-semibold dark:bg-surface-700"
						>
							{(user.firstname[0] ?? '').toUpperCase()}{(user.lastname[0] ?? '').toUpperCase()}
						</div>
						<div class="min-w-0">
							<p class="font-medium">{user.firstname} {user.lastname}</p>
							{#if user.bio}
								<p class="line-clamp-1 text-sm text-surface-500 dark:text-surface-400">{user.bio}</p>
							{/if}
						</div>
					</a>
				{/each}

				{#if filteredUsers.length === 0}
					<p class="text-sm text-surface-500">
						{searchQuery ? 'No users match your search.' : 'No users found.'}
					</p>
				{/if}
			</div>
		</div>
	</main>
</div>
