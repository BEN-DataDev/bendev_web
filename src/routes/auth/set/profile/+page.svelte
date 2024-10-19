<script lang="ts">
	import { enhance } from '$app/forms';
	import { goto, invalidate } from '$app/navigation';
	import { Button, Input, Heading } from 'svelte-5-ui-lib';
	import UploadAvatar from '$components/UploadAvatar.svelte';
	import type { ActionData } from './$types';
	import type { SubmitFunction } from '@sveltejs/kit';

	interface FormData {
		firstName: string;
		lastName: string;
		avatar: File | null;
	}

	interface FormErrors {
		firstName?: string;
		lastName?: string;
		avatar?: string;
		update?: string;
		general?: string;
	}

	let formData = $state<FormData>({
		firstName: '',
		lastName: '',
		avatar: null
	});

	let formErrors = $state<FormErrors>({});
	let loading = $state(false);

	function handleAvatarChange(newAvatar: File | null) {
		formData.avatar = newAvatar;
	}

	const handleEnhance: SubmitFunction = () => {
		return async ({ result }) => {
			loading = true;
			formErrors = {};
			if (result.type === 'success') {
				await invalidate('app:root');
				await goto('/authorised/profile');
				return;
			}
			if (result.type === 'failure') {
				const data = result.data as ActionData;
				if (!data?.success) {
					formErrors = data?.errors || { general: 'An error occurred' };
				}
			} else if (result.type === 'error') {
				formErrors = { general: 'A network error occurred. Please try again.' };
			}

			loading = false;
		};
	};

	const submissionValid = $derived(formData.firstName && formData.lastName);
</script>

<svelte:head>
	<title>Registration Form</title>
</svelte:head>

<div class="mx-auto my-2.5 w-[400px] rounded-lg bg-gray-300 p-5 shadow-md dark:bg-gray-400">
	<Heading tag="h3" class="text-center text-[#0509f7] dark:text-[#0509f7]">Register</Heading>

	{#if formErrors.general}
		<p class="mb-4 text-red-500">{formErrors.general}</p>
	{/if}
	{#if formErrors.update}
		<p class="text-sm text-red-500">{formErrors.update}</p>
	{/if}
	<form
		id="registrationForm"
		action="?/setprofile"
		method="post"
		enctype="multipart/form-data"
		use:enhance={handleEnhance}
	>
		<Input
			type="text"
			class="my-1.5 w-full rounded-md border border-gray-300 p-2"
			name="firstName"
			placeholder="First Name"
			autocomplete="given-name"
			required
			bind:value={formData.firstName}
		/>
		{#if formErrors.firstName}
			<p class="text-sm text-red-500">{formErrors.firstName}</p>
		{/if}

		<Input
			type="text"
			class="my-1.5 w-full rounded-md border border-gray-300 p-2"
			name="lastName"
			placeholder="Last Name"
			autocomplete="family-name"
			required
			bind:value={formData.lastName}
		/>
		{#if formErrors.lastName}
			<p class="text-sm text-red-500">{formErrors.lastName}</p>
		{/if}

		<UploadAvatar
			firstName={formData.firstName}
			lastName={formData.lastName}
			avatar={formData.avatar}
			on:change={(e) => handleAvatarChange(e.detail)}
		/>
		{#if formErrors.avatar}
			<p class="text-sm text-red-500">{formErrors.avatar}</p>
		{/if}

		<Button
			type="submit"
			class="mt-2.5 w-full cursor-pointer rounded bg-blue-500 py-2.5 text-white hover:bg-blue-600"
			disabled={!submissionValid || loading}
		>
			{loading ? 'Submitting...' : 'Submit'}
		</Button>
	</form>
</div>
