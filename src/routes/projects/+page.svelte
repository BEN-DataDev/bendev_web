<script lang="ts">
	import type { PageData } from './$types';

	interface Project {
		id: string;
		projectname: string;
		description: string | null;
		status: string | null;
		start_date: string | null;
		end_date: string | null;
		public: boolean;
		created_at: string;
		community_id: string | null;
		community: { name: string }[] | null;
	}

	interface Props {
		data: PageData;
	}

	let { data }: Props = $props();
	let searchQuery = $state('');

	const STATUS_BADGE: Record<string, string> = {
		draft: 'preset-tonal-warning',
		active: 'preset-tonal-success',
		completed: 'preset-tonal-secondary',
		archived: 'preset-tonal-surface'
	};

	let filtered = $derived(
		(data.projects as Project[]).filter(
			(p) =>
				p.projectname.toLowerCase().includes(searchQuery.toLowerCase()) ||
				(p.description ?? '').toLowerCase().includes(searchQuery.toLowerCase())
		)
	);
</script>

<div class="flex h-full flex-col">
	<!-- Header -->
	<header
		class="flex items-center justify-between border-b border-surface-200 p-4 dark:border-surface-700"
	>
		<h1 class="h3">Projects</h1>
		<a href="/projects/new" class="btn preset-filled-primary-500">+ New Project</a>
	</header>

	<div class="flex-1 overflow-y-auto p-4">
		<!-- Search -->
		<input
			type="search"
			class="input mb-4 w-full max-w-sm"
			placeholder="Search projects…"
			bind:value={searchQuery}
		/>

		{#if filtered.length === 0}
			<p class="text-surface-500">
				{searchQuery
					? 'No projects match your search.'
					: 'No projects yet. Create your first project!'}
			</p>
		{:else}
			<div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
				{#each filtered as project (project.id)}
					<a
						href="/projects/{project.id}"
						class="card preset-outlined-surface-200-800 block space-y-2 p-4 transition-shadow hover:shadow-md"
					>
						<div class="flex items-start justify-between gap-2">
							<h2 class="h5 line-clamp-2">{project.projectname}</h2>
							{#if project.status}
								<span
									class="badge {STATUS_BADGE[project.status] ??
										'preset-tonal-surface'} shrink-0 text-xs"
								>
									{project.status}
								</span>
							{/if}
						</div>

						{#if project.description}
							<p class="line-clamp-2 text-sm text-surface-600 dark:text-surface-300">
								{project.description}
							</p>
						{/if}

						<div class="text-xs text-surface-500 dark:text-surface-400">
							{#if project.community?.[0]}
							<span>{project.community[0].name}</span>
								<span class="mx-1">·</span>
							{/if}
							{#if project.start_date}
								<span>From {project.start_date}</span>
							{/if}
							{#if !project.public}
								<span class="ml-1 italic">private</span>
							{/if}
						</div>
					</a>
				{/each}
			</div>
		{/if}
	</div>
</div>
