<script lang="ts">
	import { enhance } from '$app/forms';
	import { zxcvbn, zxcvbnOptions } from '@zxcvbn-ts/core';
	import * as zxcvbnCommonPackage from '@zxcvbn-ts/language-common';
	import * as zxcvbnEnPackage from '@zxcvbn-ts/language-en';

	import type { ActionData } from './$types';

	import { EyeOutline, EyeSlashOutline } from 'flowbite-svelte-icons';
	import { Button, Input, Label, InputAddon, ButtonGroup } from 'svelte-5-ui-lib';

	interface FormData {
		firstName: string;
		lastName: string;
		email: string;
		password: string;
		avatar: File | null;
		errors: {
			firstName: string;
			lastName: string;
			email: string;
			password: string;
			avatar: string;
		};
	}

	interface Props {
		form?: ActionData;
	}

	let { form = null }: Props = $props();

	const formDefault: FormData = {
		firstName: '',
		lastName: '',
		email: '',
		password: '',
		avatar: null,
		errors: { firstName: '', lastName: '', email: '', password: '', avatar: '' }
	};
	let formData = $state<FormData>(formDefault);

	$effect(() => {
		formData = (form as FormData) ?? formDefault;
	});

	let passwordStrength = $state('');
	let passwordStrengthClass = $state('');
	let avatarPreview = $state('');

	const { translations } = zxcvbnEnPackage;
	const { adjacencyGraphs: graphs, dictionary: commonDictionary } = zxcvbnCommonPackage;
	const { dictionary: englishDictionary } = zxcvbnEnPackage;

	const options = {
		translations,
		graphs,
		dictionary: { ...commonDictionary, ...englishDictionary }
	};
	zxcvbnOptions.setOptions(options);

	function updatePasswordStrength() {
		const result = zxcvbn(formData.password);
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

	function getInitials(firstName: string, lastName: string): string {
		return (firstName.charAt(0) + lastName.charAt(0)).toUpperCase();
	}

	function getAvatarColor(initials: string): string {
		let hash = 0;
		for (let i = 0; i < initials.length; i++) {
			hash = initials.charCodeAt(i) + ((hash << 5) - hash);
		}
		const hue = hash % 360;
		return `hsl(${hue}, 70%, 60%)`;
	}

	let initials = $derived(getInitials(formData.firstName, formData.lastName));
	let avatarColor = $derived(getAvatarColor(initials));

	function handleAvatarChange(event: Event) {
		const target = event.target as HTMLInputElement;
		const file = target.files?.[0];
		if (file) {
			formData.avatar = file;
			const reader = new FileReader();
			reader.onload = (e) => {
				avatarPreview = e.target?.result as string;
			};
			reader.readAsDataURL(file);
		} else {
			formData.avatar = null;
			avatarPreview = '';
		}
	}
</script>

<svelte:head>
	<title>Registration Form</title>
</svelte:head>

<div class="container pt-10">
	<h2>Register</h2>
	<form id="registrationForm" action="?/signup" method="POST" use:enhance>
		<input
			type="text"
			name="firstName"
			placeholder="First Name"
			required
			bind:value={formData.firstName}
		/>
		<input
			type="text"
			name="lastName"
			placeholder="Last Name"
			required
			bind:value={formData.lastName}
		/>
		<input type="email" name="email" placeholder="Email" required bind:value={formData.email} />
		<input
			type="password"
			name="password"
			id="password"
			placeholder="Password"
			required
			bind:value={formData.password}
			oninput={updatePasswordStrength}
		/>
		<span id="password-strength" class="strength {passwordStrengthClass}">{passwordStrength}</span>

		<div class="avatar-upload">
			<label for="avatar-input" class="avatar-label">
				{#if avatarPreview}
					<img src={avatarPreview} alt="Avatar preview" class="avatar-preview" />
				{:else}
					<div class="avatar-placeholder" style="background-color: {avatarColor};">
						<span class="initials">{initials}</span>
					</div>
					<div>Upload an Avatar Image</div>
				{/if}
			</label>
			<input
				type="file"
				id="avatar-input"
				name="avatar"
				accept="image/*"
				onchange={handleAvatarChange}
				style="display: none;"
			/>
		</div>

		<button type="submit">Submit</button>
	</form>
</div>

<style>
	.container {
		background-color: #ffffff;
		border-radius: 8px;
		box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
		padding: 20px;
		width: 300px;
		margin: 0 auto;
	}
	h2 {
		text-align: center;
		color: #4a90e2;
	}
	input[type='text'],
	input[type='email'],
	input[type='password'] {
		width: 100%;
		padding: 10px;
		margin: 5px 0;
		border: 1px solid #ddd;
		border-radius: 4px;
	}
	.strength {
		color: #d9534f; /* Default color */
	}
	.strength.weak {
		color: #d9534f; /* Red */
	}
	.strength.fair {
		color: #f0ad4e; /* Yellow */
	}
	.strength.good {
		color: #5bc0de; /* Light Blue */
	}
	.strength.strong {
		color: #5cb85c; /* Green */
	}
	button {
		background-color: #4a90e2;
		color: white;
		padding: 10px;
		border: none;
		border-radius: 4px;
		cursor: pointer;
		width: 100%;
		margin-top: 10px;
	}
	button:hover {
		background-color: #357ab8;
	}
	.avatar-upload {
		margin: 20px 0;
		text-align: center;
	}
	.avatar-label {
		cursor: pointer;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
	}
	.avatar-preview {
		width: 100px;
		height: 100px;
		border-radius: 50%;
		object-fit: cover;
	}
	.avatar-placeholder {
		width: 100px;
		height: 100px;
		border-radius: 50%;
		display: flex;
		justify-content: center;
		align-items: center;
		color: white;
		font-size: 36px;
		font-weight: bold;
	}

	.initials {
		text-transform: uppercase;
	}
</style>
