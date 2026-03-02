<script lang="ts">
	import { untrack } from 'svelte';
	import ProjectMapView from '$components/maps/ProjectMapView.svelte';
	import LayerPanel, { type ProjectLayer } from '$components/projects/LayerPanel.svelte';
	import AttachmentList, { type Attachment } from '$components/projects/AttachmentList.svelte';
	import ImageGallery from '$components/projects/ImageGallery.svelte';
	import type { PageData } from './$types';

	interface Props {
		data: PageData;
	}

	let { data }: Props = $props();
	let { project, members, canEdit, canAdmin } = $derived(data);

	// Layer state — initialised from server data, refreshed via API after mutations
	let layers = $state<ProjectLayer[]>(untrack(() => (data.layers as ProjectLayer[]) ?? []));

	$effect(() => {
		layers = data.layers as ProjectLayer[];
	});

	// Attachment state — initialised from server data, refreshed via API after mutations
	let attachments = $state<Attachment[]>(untrack(() => (data.attachments as Attachment[]) ?? []));

	$effect(() => {
		attachments = data.attachments as Attachment[];
	});

	let activeTab = $state<'layers' | 'documents' | 'members'>('layers');

	const STATUS_BADGE: Record<string, string> = {
		draft: 'preset-tonal-warning',
		active: 'preset-tonal-success',
		completed: 'preset-tonal-secondary',
		archived: 'preset-tonal-surface'
	};

	const boundary = $derived(
		project.boundary ? (project.boundary as GeoJSON.Geometry) : null
	);

	async function refreshLayers() {
		const res = await fetch(`/api/projects/${project.id}/layers`);
		if (res.ok) {
			layers = (await res.json()) as ProjectLayer[];
		}
	}

	async function refreshAttachments() {
		const res = await fetch(`/api/projects/${project.id}/attachments`);
		if (res.ok) {
			attachments = (await res.json()) as Attachment[];
		}
	}
</script>

<div class="grid h-full grid-cols-1 lg:grid-cols-[280px_1fr_320px]">
	<!-- Left: project metadata -->
	<aside class="flex flex-col gap-4 overflow-y-auto border-r border-surface-200 p-4 dark:border-surface-700">
		<div class="flex items-start justify-between gap-2">
			<div>
				<a href="/projects" class="text-xs text-surface-500 hover:underline">← Projects</a>
				<h1 class="h4 mt-1">{project.projectname}</h1>
			</div>
			{#if canEdit}
				<a href="/projects/{project.id}/edit" class="btn preset-tonal-surface btn-sm shrink-0">Edit</a>
			{/if}
		</div>

		{#if project.status}
			<span class="badge {STATUS_BADGE[project.status] ?? 'preset-tonal-surface'} w-fit">
				{project.status}
			</span>
		{/if}

		{#if project.community_name}
			<div>
				<p class="text-xs font-medium uppercase text-surface-500">Community</p>
				<p class="text-sm">{project.community_name}</p>
			</div>
		{/if}

		{#if project.description}
			<div>
				<p class="text-xs font-medium uppercase text-surface-500">Description</p>
				<p class="text-sm text-surface-700 dark:text-surface-300">{project.description}</p>
			</div>
		{/if}

		{#if project.start_date || project.end_date}
			<div>
				<p class="text-xs font-medium uppercase text-surface-500">Dates</p>
				<p class="text-sm">
					{project.start_date ?? '—'}
					{#if project.end_date}&nbsp;→&nbsp;{project.end_date}{/if}
				</p>
			</div>
		{/if}

		<div>
			<p class="text-xs font-medium uppercase text-surface-500">Visibility</p>
			<p class="text-sm">{project.public ? 'Public' : 'Private'}</p>
		</div>

		<div class="mt-auto space-y-2 border-t border-surface-200 pt-4 dark:border-surface-700">
			<a
				href="/api/projects/{project.id}/export"
				class="btn preset-tonal-surface btn-sm w-full"
			>
				↓ Export GeoJSON
			</a>
			{#if canAdmin}
				<a href="/projects/{project.id}/users" class="btn preset-tonal-surface btn-sm w-full">
					Manage Members
				</a>
			{/if}
		</div>
	</aside>

	<!-- Centre: map -->
	<main class="h-full overflow-hidden">
		<ProjectMapView geometry={boundary} {layers} />
	</main>

	<!-- Right: tabbed panel -->
	<aside class="hidden flex-col border-l border-surface-200 dark:border-surface-700 lg:flex">
		<!-- Tab bar -->
		<div class="flex border-b border-surface-200 dark:border-surface-700">
			{#each [['layers', 'Layers'], ['documents', 'Documents'], ['members', 'Members']] as [tab, label] (tab)}
				<button
					class="flex-1 py-2 text-sm font-medium transition-colors {activeTab === tab
						? 'border-b-2 border-primary-500 text-primary-600 dark:text-primary-400'
						: 'text-surface-500 hover:text-surface-700 dark:hover:text-surface-300'}"
					onclick={() => (activeTab = tab as typeof activeTab)}
				>
					{label}
				</button>
			{/each}
		</div>

		<!-- Tab content -->
		<div class="flex-1 overflow-y-auto p-4">
			{#if activeTab === 'layers'}
				<LayerPanel {layers} projectId={project.id} {canEdit} onLayersChanged={refreshLayers} />

			{:else if activeTab === 'documents'}
				<div class="space-y-4">
					<ImageGallery {attachments} />
					<AttachmentList
						{attachments}
						projectId={project.id}
						{canEdit}
						onAttachmentsChanged={refreshAttachments}
					/>
				</div>

			{:else if activeTab === 'members'}
				{#if members.length === 0}
					<p class="text-sm text-surface-500">No members.</p>
				{:else}
					<ul class="space-y-2">
						{#each members as m (m.user_id)}
							<li class="text-sm">
								{#if m.userprofile}
									{((m.userprofile as { firstname: string; lastname: string }[] | null)?.[0])?.firstname ?? ''}
									{((m.userprofile as { firstname: string; lastname: string }[] | null)?.[0])?.lastname ?? ''}
								{:else}
									{m.user_id}
								{/if}
							</li>
						{/each}
					</ul>
				{/if}
			{/if}
		</div>
	</aside>
</div>
