<script lang="ts">
	import { enhance } from '$app/forms';
	import { goto } from '$app/navigation';
	import { Button, Heading } from 'svelte-5-ui-lib';
	import PasswordSet from '$components/auth/PasswordSet.svelte';

	import type { ActionData } from './$types';
	import type { SubmitFunction } from '@sveltejs/kit';

	interface FormData {
		password: string;
	}

	interface FormErrors {
		password?: string;
		general?: string;
	}

	let formData = $state<FormData>({ password: '' });
	let formErrors = $state<FormErrors>({});
	let loading = $state(false);
	let passwordValid = $state(false);

	function handleValidationChange(validated: boolean) {
		passwordValid = validated;
	}

	function handlePasswordChange(event: CustomEvent<string>) {
		formData.password = event.detail;
	}

	const handleEnhance: SubmitFunction = () => {
		return async ({ result }) => {
			loading = true;
			formErrors = {};

			if (result.type === 'success') {
				await goto('/dashboard');
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

	const submissionValid = $derived(passwordValid && formData.password.length > 0);
</script>

<svelte:head>
	<title>Set Password</title>
</svelte:head>

<div class="mx-auto my-2.5 w-[400px] rounded-lg bg-gray-300 p-5 shadow-md dark:bg-gray-400">
	<Heading tag="h3" class="text-center text-[#0509f7] dark:text-[#0509f7]">Set Password</Heading>

	{#if formErrors.general}
		<p class="mb-4 text-red-500">{formErrors.general}</p>
	{/if}

	<form id="setPasswordForm" action="?/setpassword" method="post" use:enhance={handleEnhance}>
		<PasswordSet
			password={formData.password}
			onValidationChange={handleValidationChange}
			on:passwordChange={handlePasswordChange}
			required={true}
		/>

		{#if formErrors.password}
			<p class="text-sm text-red-500">{formErrors.password}</p>
		{/if}

		<Button
			type="submit"
			class="mt-2.5 w-full cursor-pointer rounded bg-blue-500 py-2.5 text-white hover:bg-blue-600"
			disabled={!submissionValid || loading}
		>
			{loading ? 'Setting Password...' : 'Set Password'}
		</Button>
	</form>
</div>
