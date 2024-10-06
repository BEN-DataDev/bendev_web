<script lang="ts">
	import { createEventDispatcher } from 'svelte';
	import { Label } from 'svelte-5-ui-lib';

	interface Props {
		firstName: string;
		lastName: string;
		avatar: File | null;
	}

	let { firstName, lastName, avatar = $bindable() }: Props = $props();

	const dispatch = createEventDispatcher();

	function getInitials(firstName: string, lastName: string): string {
		return (firstName.charAt(0) + lastName.charAt(0)).toUpperCase();
	}

	function getAvatarColor(initials: string): string {
		let hash = 0;
		for (let i = 0; i < initials.length; i++) {
			hash = initials.charCodeAt(i) + ((hash << 5) - hash);
		}
		const hue = hash % 360;
		return `hsl(${hue}, 70%, 60%)`;
	}

	let initials = $derived(getInitials(firstName, lastName));
	let avatarColor = $derived(getAvatarColor(initials));

	let avatarPreview = $state('');

	$effect(() => {
		if (avatar) {
			avatarPreview = URL.createObjectURL(avatar);
			return () => {
				if (avatarPreview) {
					URL.revokeObjectURL(avatarPreview);
				}
			};
		} else {
			avatarPreview = '';
		}
	});

	function handleAvatarChange(event: Event) {
		const file = (event.target as HTMLInputElement).files?.[0];
		if (file) {
			avatar = file;
		} else {
			avatar = null;
		}
		dispatch('change', avatar);
	}
</script>

<div class="avatar-upload">
	<label for="avatar-input" class="avatar-label">
		{#if avatarPreview}
			<img src={avatarPreview} alt="Avatar preview" class="avatar-preview" />
		{:else}
			<div id="avatar-default" class="avatar-placeholder" style="background-color: {avatarColor};">
				{#if initials}
					<span class="initials">{initials}</span>
				{:else}
					<span class="text-sm text-red-300">Avatar</span>
				{/if}
			</div>
			<Label for="avatar-input" color="gray">Upload an Avatar Image</Label>
		{/if}
	</label>
	<input
		type="file"
		id="avatar-input"
		name="avatar"
		accept="image/*"
		onchange={handleAvatarChange}
		style="display: none;"
	/>
</div>

<style>
	.avatar-upload {
		margin: 10px 0;
		text-align: center;
	}
	.avatar-label {
		cursor: pointer;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
	}
	.avatar-preview {
		width: 100px;
		height: 100px;
		border-radius: 50%;
		object-fit: cover;
	}
	.avatar-placeholder {
		width: 100px;
		height: 100px;
		border-radius: 50%;
		display: flex;
		justify-content: center;
		align-items: center;
		color: white;
		font-size: 36px;
		font-weight: bold;
	}

	.initials {
		text-transform: uppercase;
	}
</style>
