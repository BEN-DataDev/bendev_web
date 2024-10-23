<script lang="ts">
	import { enhance } from '$app/forms';
	import type { SubmitFunction } from '@sveltejs/kit';
	import { Button, Input, Label } from 'svelte-5-ui-lib';
	import Heading from 'svelte-5-ui-lib/Heading.svelte';

	let email = $state('');
	let message = $state('');
	let error = $state('');

	const handleEnhance: SubmitFunction = () => {
		return ({ result, update }) => {
			message = '';
			error = '';

			if (result.type === 'success') {
				const data = result.data as { success?: boolean; message?: string };
				if (data.success) {
					message = data.message || 'Password reset email sent successfully.';
				}
			} else if (result.type === 'failure') {
				const data = result.data as { error?: string; message?: string };
				error = data.error || data.message || 'An error occurred';
			}

			update();
		};
	};
</script>

<svelte:head>
	<title>Password Reset Form</title>
</svelte:head>

<div class="mx-auto my-2.5 w-[400px] rounded-lg bg-gray-300 p-5 shadow-md dark:bg-gray-400">
	<Heading tag="h3" class="text-center text-[#0509f7] dark:text-[#0509f7]">Password Reset</Heading>
	{#if message}
		<p class="success">{message}</p>
	{/if}
	{#if error}
		<p class="error">{error}</p>
	{/if}
	<form
		id="requestResetPasswordForm"
		action="?/resetPassword"
		method="post"
		enctype="multipart/form-data"
		use:enhance={handleEnhance}
	>
		<Input
			type="email"
			class="my-1.5 w-full rounded-md border border-gray-300 p-2"
			name="email"
			placeholder="Email"
			autocomplete="email"
			required={true}
			bind:value={email}
		/>
		<Button
			type="submit"
			class="mt-2.5 w-full cursor-pointer rounded bg-blue-500 py-2.5 text-white hover:bg-blue-600"
			disabled={email === ''}
		>
			{'Request Password Reset'}
		</Button>
	</form>
</div>
