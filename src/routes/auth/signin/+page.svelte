<script lang="ts">
	import { Button, Input, Heading } from 'svelte-5-ui-lib';
	import { EyeOutline, EyeSlashOutline, GithubSolid, DiscordSolid } from 'flowbite-svelte-icons';

	import { themeStore, type Theme } from '$stores/app';

	type ButtonColorType =
		| 'primary'
		| 'dark'
		| 'alternative'
		| 'light'
		| 'secondary'
		| 'gray'
		| 'red'
		| 'orange'
		| 'amber'
		| 'yellow'
		| 'lime'
		| 'green'
		| 'emerald'
		| 'teal'
		| 'cyan'
		| 'sky'
		| 'blue'
		| 'indigo'
		| 'violet'
		| 'purple'
		| 'fuchsia'
		| 'pink'
		| 'rose';

	let email = $state('');
	let password = $state('');

	let emailValid = $derived(validateEmail(email));
	let show = $state(false);

	let currentTheme = $derived<Theme>($themeStore);

	let submissionValid = $derived(() => emailValid && password.length >= 8);

	const socialProviders = $state([
		{ name: 'GitHub', icon: GithubSolid, color: 'fuchsia', provider: 'github' },
		{ name: 'Discord', icon: DiscordSolid, color: 'gray', provider: 'discord' }
	]);

	function validateEmail(email: string) {
		const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
		return emailRegex.test(email);
	}

	function getInputStyles(value: string): { backgroundColor: string; color: string } {
		if (currentTheme === 'dark') {
			return {
				backgroundColor: value ? '#E8F0FE' : '#374151',
				color: value ? '#374151' : '#F3F4F6'
			};
		} else {
			return {
				backgroundColor: value ? '#E8F0FE' : '#F9FAFB',
				color: value ? '#374151' : '#D1D5DB'
			};
		}
	}

	let passwordStyle = $derived(() => getInputStyles(password));
</script>

<div class="mx-auto my-2.5 w-[400px] rounded-lg bg-gray-300 p-5 shadow-md dark:bg-gray-400">
	<Heading tag="h3" class="text-center text-[#0509f7] dark:text-[#0509f7]">Sign In</Heading>
	<form id="signinForm" action="?/signin" method="post" class="space-y-4">
		<Input
			type="email"
			class="my-1.5 w-full rounded-md border border-gray-300 p-2"
			name="email"
			placeholder="Email"
			autocomplete="email"
			required={true}
			bind:value={email}
		/>
		<Input
			id="password1"
			class="my-1.5 w-full rounded-md border border-gray-300 py-2 pl-10"
			style="background-color: {passwordStyle().backgroundColor}; color: {passwordStyle().color};"
			type={show ? 'text' : 'password'}
			placeholder="Password"
			autocomplete="current-password"
			required={true}
			bind:value={password}
		>
			{#snippet left()}
				<button
					onclick={(event) => {
						event.preventDefault();
						show = !show;
					}}
					class="pointer-events-auto"
				>
					{#if show}
						<EyeOutline class="h-6 w-6" />
					{:else}
						<EyeSlashOutline class="h-6 w-6" />
					{/if}
				</button>
			{/snippet}</Input
		>
		<p class="text-center">
			Forgot Password? <a href="/auth/reset/password" class="text-blue-500 hover:underline"
				>Reset Password</a
			>
		</p>
		<Button type="submit" disabled={!submissionValid} class="w-full">Log In</Button>
	</form>

	<div class="mt-3">
		<Heading tag="h6" class="pt-0 text-[#0509f7] dark:text-[#0509f7]">Or connect with:</Heading>
		<div class="flex flex-col justify-center space-y-3">
			{#each socialProviders as { name, icon: Icon, color, provider }}
				<Button
					size="sm"
					color={color as ButtonColorType}
					class="flex w-full items-center py-1.5 opacity-70"
					href={`/auth/signin/${provider}`}
				>
					<Icon class="mr-2 h-5 w-5" />
					{name}
				</Button>
			{/each}
		</div>
	</div>

	<p class="text-center">
		Don't have an account? <a href="/auth/signup" class="text-blue-500 hover:underline">Sign up</a>
	</p>
</div>
