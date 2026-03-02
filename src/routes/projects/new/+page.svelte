<script lang="ts">
	import { enhance } from '$app/forms';
	import ProjectMapView from '$components/maps/ProjectMapView.svelte';
	import type { PageData, ActionData } from './$types';

	interface Props {
		data: PageData;
		form: ActionData;
	}

	let { data, form }: Props = $props();

	let drawnGeometry = $state('');

	function handleGeometryChange(geometry: GeoJSON.Geometry | null) {
		drawnGeometry = geometry ? JSON.stringify(geometry) : '';
	}
</script>

<div class="flex h-full flex-col">
	<header class="border-b border-surface-200 p-4 dark:border-surface-700">
		<div class="flex items-center gap-2">
			<a href="/projects" class="btn preset-tonal-surface btn-sm">← Projects</a>
			<h1 class="h3">New Project</h1>
		</div>
	</header>

	<div class="flex-1 overflow-y-auto">
		<form method="POST" use:enhance class="grid h-full grid-cols-1 gap-0 lg:grid-cols-2">
			<!-- Left: form fields -->
			<div class="space-y-4 overflow-y-auto border-r border-surface-200 p-6 dark:border-surface-700">
				{#if form?.error}
					<p class="text-sm text-error-500">{form.error}</p>
				{/if}

				<label class="block">
					<span class="mb-1 block text-sm font-medium">Project Name <span class="text-error-500">*</span></span>
					<input
						type="text"
						name="name"
						class="input w-full"
						required
						placeholder="Enter project name"
					/>
				</label>

				<label class="block">
					<span class="mb-1 block text-sm font-medium">Community <span class="text-error-500">*</span></span>
					<select name="community_id" class="select w-full" required>
						<option value="">Select a community…</option>
						{#each data.communities as c}
							<option value={c.id}>{c.name}</option>
						{/each}
					</select>
				</label>

				<label class="block">
					<span class="mb-1 block text-sm font-medium">Description</span>
					<textarea name="description" class="textarea w-full" rows="3" placeholder="Describe the project…"></textarea>
				</label>

				<label class="block">
					<span class="mb-1 block text-sm font-medium">Status</span>
					<select name="status" class="select w-full">
						<option value="draft">Draft</option>
						<option value="active">Active</option>
						<option value="completed">Completed</option>
						<option value="archived">Archived</option>
					</select>
				</label>

				<div class="grid grid-cols-2 gap-4">
					<label class="block">
						<span class="mb-1 block text-sm font-medium">Start Date</span>
						<input type="date" name="start_date" class="input w-full" />
					</label>
					<label class="block">
						<span class="mb-1 block text-sm font-medium">End Date</span>
						<input type="date" name="end_date" class="input w-full" />
					</label>
				</div>

				<label class="flex items-center gap-2">
					<input type="checkbox" name="public" class="checkbox" />
					<span class="text-sm">Make project public</span>
				</label>

				<input type="hidden" name="geometry_geojson" value={drawnGeometry} />

				<button type="submit" class="btn preset-filled-primary-500 w-full">Create Project</button>
			</div>

			<!-- Right: map -->
			<div class="h-[400px] lg:h-full">
				<ProjectMapView editable={true} onGeometryChange={handleGeometryChange} />
			</div>
		</form>
	</div>
</div>
