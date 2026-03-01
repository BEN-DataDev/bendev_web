<script lang="ts">
	import { createEventDispatcher, onMount } from 'svelte';

	import Icon from '$components/icons/Icons.svelte';

	interface Props {
		email: string;
		password: string;
		required?: boolean;
		onValidationChange: (matches: boolean) => void;
	}

	let {
		email = '',
		password = '',
		required = false,
		onValidationChange = (valid: boolean) => {}
	}: Props = $props();

	let passwordStrength = $state('');
	let passwordStrengthClass = $state('');

	const dispatch = createEventDispatcher();

	let zxcvbnFn: ((password: string) => { score: number }) | null = null;

	onMount(async () => {
		const [{ zxcvbn, zxcvbnOptions }, common, en] = await Promise.all([
			import('@zxcvbn-ts/core'),
			import('@zxcvbn-ts/language-common'),
			import('@zxcvbn-ts/language-en')
		]);
		zxcvbnOptions.setOptions({
			translations: en.translations,
			graphs: common.adjacencyGraphs,
			dictionary: { ...common.dictionary, ...en.dictionary }
		});
		zxcvbnFn = zxcvbn;
	});

	let show = $state(false);
	let showAgain = $state(false);

	function validateEmail(email: string) {
		const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
		return emailRegex.test(email);
	}

	function updatePasswordStrength() {
		if (!zxcvbnFn) return;
		const result = zxcvbnFn(password);
		const strength = result.score;
		switch (strength) {
			case 0:
				passwordStrength = 'Weak';
				passwordStrengthClass = 'weak';
				break;
			case 1:
				passwordStrength = 'Fair';
				passwordStrengthClass = 'fair';
				break;
			case 2:
				passwordStrength = 'Good';
				passwordStrengthClass = 'good';
				break;
			case 3:
			case 4:
				passwordStrength = 'Strong';
				passwordStrengthClass = 'strong';
				break;
			default:
				passwordStrength = '';
				passwordStrengthClass = '';
		}
	}

	let passwordConfirmation = $state('');
	let passwordsMatch = $derived(password === passwordConfirmation && password !== '');
	let emailValid = $derived(validateEmail(email));

	// Map strength class to Skeleton theme color classes
	const strengthTextClass = $derived(
		passwordStrengthClass === 'weak'
			? 'text-error-500'
			: passwordStrengthClass === 'fair'
				? 'text-warning-500'
				: passwordStrengthClass === 'good'
					? 'text-secondary-500'
					: passwordStrengthClass === 'strong'
						? 'text-success-500'
						: 'text-surface-400'
	);

	const strengthBgClass = $derived(
		passwordStrengthClass === 'weak'
			? 'bg-error-500'
			: passwordStrengthClass === 'fair'
				? 'bg-warning-500'
				: passwordStrengthClass === 'good'
					? 'bg-secondary-500'
					: passwordStrengthClass === 'strong'
						? 'bg-success-500'
						: 'bg-surface-300'
	);

	const strengthBarWidth = $derived(
		passwordStrength === 'Weak'
			? '25%'
			: passwordStrength === 'Fair'
				? '50%'
				: passwordStrength === 'Good'
					? '75%'
					: passwordStrength === 'Strong'
						? '100%'
						: '0%'
	);

	$effect(() => {
		onValidationChange(passwordsMatch && emailValid);
		dispatch('passwordChange', password);
	});
</script>

<h6 class="h6 text-primary-600 dark:text-primary-400">Register with Email and Password:</h6>
<input
	type="email"
	class="input my-1.5 w-full rounded-md border border-surface-300 bg-surface-50 p-2 dark:border-surface-600 dark:bg-surface-900"
	name="email"
	placeholder="Email"
	autocomplete="email"
	{required}
	bind:value={email}
/>
<div class="relative my-1.5">
	<button
		type="button"
		onclick={() => {
			show = !show;
		}}
		class="absolute left-2 top-1/2 -translate-y-1/2 text-surface-600 hover:text-surface-900 dark:text-surface-400 dark:hover:text-surface-100"
	>
		{#if show}
			<Icon name="eye" class="h-6 w-6" />
		{:else}
			<Icon name="eye-off" class="h-6 w-6" />
		{/if}
	</button>
	<input
		id="show-password1"
		class="input w-full rounded-md border border-surface-300 bg-surface-50 py-2 pl-10 pr-2 dark:border-surface-600 dark:bg-surface-900"
		type={show ? 'text' : 'password'}
		placeholder="Password"
		autocomplete="current-password"
		{required}
		bind:value={password}
		oninput={updatePasswordStrength}
	/>
</div>
<div class="mb-4 mt-2">
	<div class="mb-1 flex justify-between">
		<span class="text-sm font-medium text-surface-700 dark:text-surface-300">Password strength</span>
		<span class="text-sm font-medium {strengthTextClass}">{passwordStrength}</span>
	</div>
	<div class="h-2.5 w-full rounded-full bg-surface-200 dark:bg-surface-700">
		<div
			class="h-2.5 rounded-full transition-all duration-300 ease-in-out {strengthBgClass}"
			style="width: {strengthBarWidth}"
		></div>
	</div>
</div>
<div class="relative my-1.5">
	<button
		type="button"
		onclick={() => {
			showAgain = !showAgain;
		}}
		class="absolute left-2 top-1/2 -translate-y-1/2 text-surface-600 hover:text-surface-900 dark:text-surface-400 dark:hover:text-surface-100"
	>
		{#if showAgain}
			<Icon name="eye" class="h-6 w-6" />
		{:else}
			<Icon name="eye-off" class="h-6 w-6" />
		{/if}
	</button>
	<input
		id="show-passwordAgain"
		class="input w-full rounded-md border border-surface-300 bg-surface-50 py-2 pl-10 pr-2 dark:border-surface-600 dark:bg-surface-900"
		type={showAgain ? 'text' : 'password'}
		placeholder="Password Again"
		autocomplete="current-password"
		{required}
		bind:value={passwordConfirmation}
	/>
</div>
{#if password && passwordConfirmation && !passwordsMatch}
	<p class="mt-1 text-sm text-error-500">Passwords do not match</p>
{/if}
