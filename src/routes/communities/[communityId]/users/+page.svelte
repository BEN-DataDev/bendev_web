<script lang="ts">
	import { enhance } from '$app/forms';
	import type { PageData, ActionData } from './$types';

	interface Props {
		data: PageData;
		form: ActionData;
	}

	let { data, form }: Props = $props();
	let { community, members, currentUserId } = $derived(data);

	const ROLE_OPTIONS = ['owner', 'admin', 'member'] as const;

	const ownerCount = $derived(members.filter((m: { role: string }) => m.role === 'owner').length);
</script>

<div class="flex h-full flex-col">
	<header class="border-b border-surface-200 p-4 dark:border-surface-700">
		<div class="flex items-center gap-2">
			<a href="/communities/{community.id}" class="btn preset-tonal-surface btn-sm">← Back</a>
			<h1 class="h3">Manage Members</h1>
		</div>
		<p class="mt-1 text-sm text-surface-500">{community.name}</p>
	</header>

	<div class="flex-1 overflow-y-auto p-6">
		{#if form?.error}
			<p class="mb-4 text-sm text-error-500">{form.error}</p>
		{/if}

		{#if members.length === 0}
			<p class="text-sm text-surface-500">No members found.</p>
		{:else}
			<div class="space-y-2">
				{#each members as member (member.user_id)}
					{@const isOnlyOwner = member.role === 'owner' && ownerCount === 1}
					{@const isCurrentUser = member.user_id === currentUserId}
					<div
						class="card preset-outlined-surface-200-800 flex items-center justify-between gap-4 p-3"
					>
						<div>
							<p class="text-sm font-medium">
								{member.firstname}
								{member.lastname}
								{#if isCurrentUser}<span class="text-xs text-surface-400">(you)</span>{/if}
							</p>
							<p class="text-xs text-surface-500">{member.user_id}</p>
						</div>

						<div class="flex shrink-0 items-center gap-2">
							<!-- Role selector -->
							<form method="POST" action="?/changeRole" use:enhance>
								<input type="hidden" name="user_id" value={member.user_id} />
								<select
									name="role"
									class="select text-sm"
									value={member.role}
									onchange={(e) => (e.currentTarget as HTMLSelectElement).form?.requestSubmit()}
								>
									{#each ROLE_OPTIONS as r (r)}
										<option value={r} selected={r === member.role}>{r}</option>
									{/each}
								</select>
							</form>

							<!-- Remove button -->
							<form method="POST" action="?/remove" use:enhance>
								<input type="hidden" name="user_id" value={member.user_id} />
								<button
									type="submit"
									class="btn preset-tonal-error btn-sm"
									disabled={isOnlyOwner}
									title={isOnlyOwner ? 'Cannot remove the only owner' : 'Remove member'}
								>
									Remove
								</button>
							</form>
						</div>
					</div>
				{/each}
			</div>
		{/if}

		<div class="mt-6 border-t border-surface-200 pt-4 dark:border-surface-700">
			<p class="text-xs text-surface-400">Member invitations available in a future release.</p>
		</div>
	</div>
</div>
