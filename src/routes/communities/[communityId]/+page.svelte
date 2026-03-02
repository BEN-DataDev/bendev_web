<script lang="ts">
	import ProjectMapView from '$components/maps/ProjectMapView.svelte';
	import type { PageData } from './$types';

	interface Member {
		user_id: string;
		firstname: string;
		lastname: string;
		role: string;
	}

	interface Props {
		data: PageData;
	}

	let { data }: Props = $props();
	let { community, members, canAdmin } = $derived(data);

	const boundary = $derived(community.boundary ? (community.boundary as GeoJSON.Geometry) : null);
</script>

<div class="grid h-full grid-cols-1 lg:grid-cols-[280px_1fr_280px]">
	<!-- Left: community details -->
	<aside
		class="flex flex-col gap-4 overflow-y-auto border-r border-surface-200 p-4 dark:border-surface-700"
	>
		<div class="flex items-start justify-between gap-2">
			<div>
				<a href="/communities" class="text-xs text-surface-500 hover:underline">← Communities</a>
				<h1 class="h3 mt-1">{community.name}</h1>
			</div>
			{#if community.public}
				<span class="badge preset-tonal-success shrink-0 text-xs">Public</span>
			{:else}
				<span class="badge preset-tonal-surface shrink-0 text-xs">Private</span>
			{/if}
		</div>

		{#if community.communityinfo?.about}
			<div>
				<p class="text-xs font-medium uppercase text-surface-500">About</p>
				<p class="mt-1 text-sm">{community.communityinfo.about}</p>
			</div>
		{/if}

		{#if community.communityinfo?.objects}
			<div>
				<p class="text-xs font-medium uppercase text-surface-500">Objects</p>
				<p class="mt-1 text-sm">{community.communityinfo.objects}</p>
			</div>
		{/if}

		{#if community.communityinfo?.['primary goal']}
			<div>
				<p class="text-xs font-medium uppercase text-surface-500">Primary Goal</p>
				{#if Array.isArray(community.communityinfo['primary goal'])}
					<ul class="mt-1 list-disc space-y-1 pl-4 text-sm">
						{#each community.communityinfo['primary goal'] as goal}
							<li>{goal}</li>
						{/each}
					</ul>
				{:else}
					<p class="mt-1 text-sm">{community.communityinfo['primary goal']}</p>
				{/if}
			</div>
		{/if}

		{#if community.contactinfo?.contacts?.length}
			<div>
				<p class="text-xs font-medium uppercase text-surface-500">Contact</p>
				<div class="mt-1 space-y-1">
					{#each community.contactinfo.contacts as contact}
						{#if contact.developer}
							<p class="text-sm">{contact.developer.name}</p>
						{/if}
					{/each}
				</div>
			</div>
		{/if}

		<div class="mt-auto space-y-2 border-t border-surface-200 pt-4 dark:border-surface-700">
			{#if canAdmin}
				<a
					href="/communities/{community.id}/edit"
					class="btn preset-tonal-surface btn-sm w-full"
				>
					Edit Community
				</a>
				<a
					href="/communities/{community.id}/users"
					class="btn preset-tonal-surface btn-sm w-full"
				>
					Manage Members
				</a>
			{/if}
		</div>
	</aside>

	<!-- Centre: extent map -->
	<main class="h-full overflow-hidden">
		<ProjectMapView geometry={boundary} />
	</main>

	<!-- Right: member list -->
	<aside
		class="flex flex-col gap-3 overflow-y-auto border-l border-surface-200 p-4 dark:border-surface-700"
	>
		<h2 class="h5">Members</h2>

		{#if (members as Member[]).length === 0}
			<p class="text-sm text-surface-500">No members yet.</p>
		{:else}
			<ul class="space-y-2">
				{#each members as member (member.user_id)}
					<li class="card preset-outlined-surface-200-800 p-2 text-sm">
						<p class="font-medium">{member.firstname} {member.lastname}</p>
						<p class="text-xs text-surface-500">{member.role}</p>
					</li>
				{/each}
			</ul>
		{/if}
	</aside>
</div>
