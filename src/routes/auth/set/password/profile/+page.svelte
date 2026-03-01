<script lang="ts">
	import { enhance } from '$app/forms';
	import { goto } from '$app/navigation';
	import PasswordSet from '$components/auth/PasswordSet.svelte';
	import UploadAvatar from '$components/UploadAvatar.svelte';
	import type { ActionData } from './$types';
	import type { SubmitFunction } from '@sveltejs/kit';

	interface FormData {
		firstName: string;
		lastName: string;
		password: string;
		avatar: File | null;
	}

	interface FormErrors {
		firstName?: string;
		lastName?: string;
		password?: string;
		avatar?: string;
		update?: string;
		general?: string;
	}

	let formData = $state<FormData>({
		firstName: '',
		lastName: '',
		password: '',
		avatar: null
	});

	let formErrors = $state<FormErrors>({});
	let loading = $state(false);
	let passwordValid = $state(false);

	function handleValidationChange(validated: boolean) {
		passwordValid = validated;
	}

	function handlePasswordChange(event: CustomEvent<string>) {
		formData.password = event.detail;
	}

	function handleAvatarChange(newAvatar: File | null) {
		formData.avatar = newAvatar;
	}

	const handleEnhance: SubmitFunction = () => {
		return async ({ result }) => {
			loading = true;
			formErrors = {};
			if (result.type === 'success') {
				const data = result.data as { success: boolean; redirectTo?: string; message?: string };
				if (data.success) {
					if (data.message) {
						formErrors = { general: data.message };
						loading = false;
						return;
					}
					await goto(data.redirectTo || '/users');
					return;
				}
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

	const submissionValid = $derived(passwordValid && formData.firstName && formData.lastName);
</script>

<svelte:head>
	<title>Registration Form</title>
</svelte:head>

<div class="card preset-outlined-surface-200-800 mx-auto my-2.5 w-[400px] p-5 shadow-md">
	<h3 class="h3 text-center text-primary-600 dark:text-primary-400">Register</h3>

	{#if formErrors.general}
		<p class="mb-4 text-error-500">{formErrors.general}</p>
	{/if}
	{#if formErrors.update}
		<p class="text-sm text-error-500">{formErrors.update}</p>
	{/if}
	<form
		id="registrationForm"
		action="?/setpasswordprofile"
		method="post"
		enctype="multipart/form-data"
		use:enhance={handleEnhance}
	>
		<input
			type="text"
			class="input my-1.5 w-full rounded-md border border-surface-300 dark:border-surface-600 bg-surface-50 dark:bg-surface-900 p-2"
			name="firstName"
			placeholder="First Name"
			autocomplete="given-name"
			required
			bind:value={formData.firstName}
		/>
		{#if formErrors.firstName}
			<p class="text-sm text-error-500">{formErrors.firstName}</p>
		{/if}

		<input
			type="text"
			class="input my-1.5 w-full rounded-md border border-surface-300 dark:border-surface-600 bg-surface-50 dark:bg-surface-900 p-2"
			name="lastName"
			placeholder="Last Name"
			autocomplete="family-name"
			required
			bind:value={formData.lastName}
		/>
		{#if formErrors.lastName}
			<p class="text-sm text-error-500">{formErrors.lastName}</p>
		{/if}

		<PasswordSet
			password={formData.password}
			onValidationChange={handleValidationChange}
			on:passwordChange={handlePasswordChange}
			required={true}
		/>
		<input type="hidden" name="password" bind:value={formData.password} />
		{#if formErrors.password}
			<p class="text-sm text-error-500">{formErrors.password}</p>
		{/if}

		<UploadAvatar
			firstName={formData.firstName}
			lastName={formData.lastName}
			avatar={formData.avatar}
			on:change={(e) => handleAvatarChange(e.detail)}
		/>
		{#if formErrors.avatar}
			<p class="text-sm text-error-500">{formErrors.avatar}</p>
		{/if}

		<button
			type="submit"
			class="btn preset-filled-primary-500 mt-2.5 w-full cursor-pointer"
			disabled={!submissionValid || loading}
		>
			{loading ? 'Submitting...' : 'Submit'}
		</button>
	</form>
</div>
