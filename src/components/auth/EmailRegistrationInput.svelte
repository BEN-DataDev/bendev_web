<script lang="ts">
	import { zxcvbn, zxcvbnOptions } from '@zxcvbn-ts/core';
	import * as zxcvbnCommonPackage from '@zxcvbn-ts/language-common';
	import * as zxcvbnEnPackage from '@zxcvbn-ts/language-en';
	import { createEventDispatcher } from 'svelte';

	import { themeStore, type Theme } from '$stores/app';

	import { EyeOutline, EyeSlashOutline } from 'flowbite-svelte-icons';
	import { Heading, Input } from 'svelte-5-ui-lib';

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

	const { translations } = zxcvbnEnPackage;
	const { adjacencyGraphs: graphs, dictionary: commonDictionary } = zxcvbnCommonPackage;
	const { dictionary: englishDictionary } = zxcvbnEnPackage;

	const options = {
		translations,
		graphs,
		dictionary: { ...commonDictionary, ...englishDictionary }
	};

	zxcvbnOptions.setOptions(options);

	let show = $state(false);
	let showAgain = $state(false);

	function validateEmail(email: string) {
		const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
		return emailRegex.test(email);
	}

	function updatePasswordStrength() {
		const result = zxcvbn(password);
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

	let currentTheme = $derived<Theme>($themeStore);

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
	let passwordConfirmationStyle = $derived(() => getInputStyles(passwordConfirmation));

	$effect(() => {
		onValidationChange(passwordsMatch && emailValid);
		dispatch('passwordChange', password);
	});
</script>

<Heading tag="h6" class="text-[#0509f7] dark:text-[#0509f7]"
	>Register with Email and Password:</Heading
>
<Input
	type="email"
	class="my-1.5 w-full rounded-md border border-gray-300 p-2"
	name="email"
	placeholder="Email"
	autocomplete="email"
	{required}
	bind:value={email}
/>
<Input
	id="show-password1"
	class="my-1.5 w-full rounded-md border border-gray-300 py-2 pl-10"
	style="background-color: {passwordStyle().backgroundColor}; color: {passwordStyle().color};"
	type={show ? 'text' : 'password'}
	placeholder="Password"
	autocomplete="current-password"
	{required}
	bind:value={password}
	oninput={updatePasswordStrength}
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
<div class="mb-4 mt-2">
	<div class="mb-1 flex justify-between">
		<span class="text-sm font-medium text-gray-700">Password strength</span>
		<span
			class="text-sm font-medium"
			style="color: {passwordStrengthClass === 'weak'
				? '#d9534f'
				: passwordStrengthClass === 'fair'
					? '#f0ad4e'
					: passwordStrengthClass === 'good'
						? '#5bc0de'
						: passwordStrengthClass === 'strong'
							? '#5cb85c'
							: '#d9534f'}">{passwordStrength}</span
		>
	</div>
	<div class="h-2.5 w-full rounded-full bg-gray-200">
		<div
			class="h-2.5 rounded-full transition-all duration-300 ease-in-out"
			style="width: {passwordStrength === 'Weak'
				? 25
				: passwordStrength === 'Fair'
					? 50
					: passwordStrength === 'Good'
						? 75
						: passwordStrength === 'Strong'
							? 100
							: 0}%; background-color: {passwordStrengthClass === 'weak'
				? '#d9534f'
				: passwordStrengthClass === 'fair'
					? '#f0ad4e'
					: passwordStrengthClass === 'good'
						? '#5bc0de'
						: passwordStrengthClass === 'strong'
							? '#5cb85c'
							: '#d9534f'}"
		></div>
	</div>
</div>
<Input
	id="show-passwordAgain"
	class="my-1.5 w-full rounded-md border border-gray-300 py-2 pl-10"
	style="background-color: {passwordConfirmationStyle()
		.backgroundColor}; color: {passwordConfirmationStyle().color};"
	type={showAgain ? 'text' : 'password'}
	placeholder="Password Again"
	autocomplete="current-password"
	{required}
	bind:value={passwordConfirmation}
>
	{#snippet left()}
		<button
			onclick={(event) => {
				event.preventDefault();
				showAgain = !showAgain;
			}}
			class="pointer-events-auto"
		>
			{#if showAgain}
				<EyeOutline class="h-6 w-6" />
			{:else}
				<EyeSlashOutline class="h-6 w-6" />
			{/if}
		</button>
	{/snippet}</Input
>
{#if password && passwordConfirmation && !passwordsMatch}
	<p class="mt-1 text-sm text-red-500">Passwords do not match</p>
{/if}
