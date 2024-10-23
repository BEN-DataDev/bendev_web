<script lang="ts">
	import { enhance } from '$app/forms';
	import { Button, Heading } from 'svelte-5-ui-lib';
	import EmailRegistrationInput from '$components/auth/EmailRegistrationInput.svelte';
	import SocialMediaRegistrationInput from '$components/auth/SocialMediaRegistrationInput.svelte';

	import type { ActionData } from './$types';
	import type { SubmitFunction } from '@sveltejs/kit';

	interface FormData {
		email: string;
		password: string;
		provider?: 'email' | 'github' | 'discord';
		errors: {
			email?: string;
			password?: string;
			general?: string;
		};
	}

	interface FormErrors {
		email?: string;
		password?: string;
		general?: string;
		[key: string]: string | undefined;
	}

	interface Props {
		form?: ActionData;
	}

	let { form = null }: Props = $props();

	const formDefault: FormData = {
		email: '',
		password: '',
		provider: 'email',
		errors: {}
	};

	let formData = $state<FormData>(formDefault);
	let loading = $state(false);

	$effect(() => {
		if (form as FormData) {
			if (form?.errors) {
				formData = {
					...formDefault,
					errors: form.errors as FormData['errors']
				};
			} else if (form?.data) {
				formData = {
					...formDefault,
					...(form?.data as Partial<FormData>),
					errors: {}
				};
			}
		}
	});

	let emailPasswordValid = $state(false);

	function handleValidationChange(validated: boolean) {
		emailPasswordValid = validated;
	}

	function handlePasswordChange(event: CustomEvent<string>) {
		formData.password = event.detail;
	}

	function handleSocialSignIn(
		event: CustomEvent<{ provider: 'email' | 'github' | 'discord' | undefined }>
	) {
		const { provider } = event.detail;
		formData.provider = provider;
		if (provider !== 'email') {
			formData.email = '';
			formData.password = '';
		}
	}

	type FormErrorKey = keyof FormErrors;
	let formErrors = $state<Partial<Record<FormErrorKey, string>>>({});

	const handleEnhance: SubmitFunction = () => {
		return async ({ result }) => {
			loading = true;
			formErrors = {};
			try {
				if (result.type === 'error') {
					formErrors = { general: 'A network error occurred. Please try again.' };
				} else if (result.type === 'failure') {
					formErrors = (result.data as { errors?: FormErrors })?.errors || {};
				} else if (result.type === 'success') {
					// await goto('/auth/confirm');
					return;
				}
			} catch (error) {
				console.error('Error during form submission:', error);
				formErrors = { general: 'An unexpected error occurred. Please try again.' };
			} finally {
				loading = false;
			}
		};
	};
	const submissionValid = $derived(emailPasswordValid || formData.provider !== 'email');
</script>

<svelte:head>
	<title>Registration Form</title>
</svelte:head>

<div class="mx-auto my-2.5 w-[400px] rounded-lg bg-gray-300 p-5 shadow-md dark:bg-gray-400">
	<Heading tag="h3" class="text-center text-[#0509f7] dark:text-[#0509f7]">Register</Heading>
	{#if formErrors.general}
		<p class="mb-4 text-red-500">{formErrors.general}</p>
	{/if}
	<form
		id="registrationForm"
		action="?/signup"
		method="post"
		enctype="multipart/form-data"
		use:enhance={handleEnhance}
	>
		{#if formData.provider === 'email'}
			<EmailRegistrationInput
				email={formData.email}
				password={formData.password}
				onValidationChange={handleValidationChange}
				on:passwordChange={handlePasswordChange}
				required={true}
			/>
			<input type="hidden" name="password" bind:value={formData.password} />
			{#if formErrors.email}
				<p class="text-sm text-red-500">{formErrors.email}</p>
			{/if}
			{#if formErrors.password}
				<p class="text-sm text-red-500">{formErrors.password}</p>
			{/if}
		{:else}
			<input type="hidden" name="email" value="" />
			<input type="hidden" name="password" value="" />
		{/if}

		<SocialMediaRegistrationInput on:socialSignIn={handleSocialSignIn} />
		<input type="hidden" name="provider" bind:value={formData.provider} />
		<Button
			type="submit"
			class="mt-2.5 w-full cursor-pointer rounded bg-blue-500 py-2.5 text-white hover:bg-blue-600"
			disabled={!submissionValid || loading}
		>
			{loading ? 'Submitting...' : 'Submit'}
		</Button>
	</form>
</div>
