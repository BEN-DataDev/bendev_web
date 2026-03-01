<script lang="ts">
	import Icon from '$components/icons/Icons.svelte';

	type IconName = 'github' | 'moon' | 'sun' | 'user' | 'menu' | 'x' | 'eye' | 'eye-off' | 'circle-check' | 'circle-x' | 'chevrons-left' | 'chevrons-right' | 'chevrons-up' | 'chevrons-down' | 'settings' | 'user-circle' | 'users';

	let email = $state('');
	let password = $state('');

	let emailValid = $derived(validateEmail(email));
	let show = $state(false);

	let submissionValid = $derived(emailValid && password.length >= 8);

	const socialProviders = $state<Array<{ name: string; iconName: IconName; provider: string }>>([
		{ name: 'GitHub', iconName: 'github' as IconName, provider: 'github' }
		// TODO: Add Discord, Google, Microsoft icons when implementing social auth UI
	]);

	function validateEmail(email: string) {
		const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
		return emailRegex.test(email);
	}
</script>

<div class="card preset-outlined-surface-200-800 mx-auto my-2.5 w-[400px] p-5 shadow-md">
	<h3 class="h3 text-center text-primary-600 dark:text-primary-400">Sign In</h3>
	<form id="signinForm" action="?/signin" method="post" class="space-y-4">
		<input
			type="email"
			class="input my-1.5 w-full rounded-md border border-surface-300 dark:border-surface-600 bg-surface-50 dark:bg-surface-900 p-2"
			name="email"
			placeholder="Email"
			autocomplete="email"
			required
			bind:value={email}
		/>
		<div class="relative my-1.5">
			<button
				type="button"
				onclick={() => {
					show = !show;
				}}
				class="absolute left-2 top-1/2 -translate-y-1/2 text-surface-600 dark:text-surface-400 hover:text-surface-900 dark:hover:text-surface-100"
			>
				{#if show}
					<Icon name="eye" class="h-6 w-6" />
				{:else}
					<Icon name="eye-off" class="h-6 w-6" />
				{/if}
			</button>
			<input
				id="password1"
				class="input w-full rounded-md border border-surface-300 bg-surface-50 py-2 pl-10 pr-2 dark:border-surface-600 dark:bg-surface-900"
				type={show ? 'text' : 'password'}
				name="password"
				placeholder="Password"
				autocomplete="current-password"
				required
				bind:value={password}
			/>
		</div>
		<p class="text-center">
			Forgot Password? <a href="/auth/reset/password" class="text-primary-500 hover:underline"
				>Reset Password</a
			>
		</p>
		<button type="submit" disabled={!submissionValid} class="btn preset-filled-primary-500 w-full">
			Log In
		</button>
	</form>

	<div class="mt-3">
		<h6 class="h6 pt-0 text-primary-600 dark:text-primary-400">Or connect with:</h6>
		<div class="flex flex-col justify-center space-y-3">
			{#each socialProviders as { name, iconName, provider }}
				<a
					class="btn preset-filled-secondary-500 flex w-full items-center justify-center py-1.5 text-sm opacity-70 hover:opacity-100"
					href={`/auth/signin/${provider}`}
				>
					<Icon name={iconName} class="mr-2 h-5 w-5" />
					{name}
				</a>
			{/each}
		</div>
	</div>

	<p class="text-center">
		Don't have an account? <a href="/auth/signup" class="text-primary-500 hover:underline">Sign up</a>
	</p>
</div>
