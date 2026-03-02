<script lang="ts">
	import type { PageData } from './$types';

	interface Profile {
		id: string;
		firstname: string;
		lastname: string;
		bio: string | null;
		avatar_path: string | null;
	}

	interface Props {
		data: PageData;
	}

	let { data }: Props = $props();
	let profile = $derived(data.profile as Profile);
	let isOwnProfile = $derived((data.user as { id: string } | null)?.id === profile.id);
</script>

<svelte:head>
	<title>{profile.firstname} {profile.lastname}</title>
</svelte:head>

<div class="mx-auto max-w-lg space-y-4">
	<div class="card preset-outlined-surface-200-800 p-6">
		<div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
			<div class="flex items-center gap-4">
				<!-- Avatar initials -->
				<div
					class="flex h-16 w-16 shrink-0 items-center justify-center rounded-full bg-surface-200 text-xl font-semibold dark:bg-surface-700"
				>
					{(profile.firstname[0] ?? '').toUpperCase()}{(profile.lastname[0] ?? '').toUpperCase()}
				</div>
				<div>
					<h2 class="h3">{profile.firstname} {profile.lastname}</h2>
					{#if profile.bio}
						<p class="mt-1 text-surface-600 dark:text-surface-300">{profile.bio}</p>
					{:else if isOwnProfile}
						<p class="mt-1 text-sm text-surface-400">No bio set.</p>
					{/if}
				</div>
			</div>
		</div>
	</div>

	{#if !isOwnProfile}
		<div class="flex justify-end">
			<a href="/users" class="btn preset-tonal-surface btn-sm">← All Users</a>
		</div>
	{/if}
</div>
