<script lang="ts">
	import { enhance } from '$app/forms';
	import type { SubmitFunction } from '@sveltejs/kit';
	
	// Migrated to native heading elements

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

<div class="card preset-outlined-surface-200-800 mx-auto my-2.5 w-[400px] p-5 shadow-md">
	<h3 class="h3 text-center text-primary-600 dark:text-primary-400">Password Reset</h3>
	{#if message}
		<p class="text-success-500">{message}</p>
	{/if}
	{#if error}
		<p class="text-error-500">{error}</p>
	{/if}
	<form
		id="requestResetPasswordForm"
		action="?/resetPassword"
		method="post"
		enctype="multipart/form-data"
		use:enhance={handleEnhance}
	>
		<input
			type="email"
			class="input my-1.5 w-full rounded-md border border-surface-300 dark:border-surface-600 bg-surface-50 dark:bg-surface-900 p-2"
			name="email"
			placeholder="Email"
			autocomplete="email"
			required
			bind:value={email}
		/>
		<button
			type="submit"
			class="btn preset-filled-primary-500 mt-2.5 w-full cursor-pointer"
			disabled={email === ''}
		>
			Request Password Reset
		</button>
	</form>
</div>
