<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import type { PageData } from './$types';

	interface Props {
		data: PageData;
	}

	let { data }: Props = $props();
	let { user } = $derived(data);

	let verified = $state(false);

	async function checkVerificationStatus() {
		if (user && user.email_confirmed_at) {
			verified = true;
		}
	}

	onMount(() => {
		const interval = setInterval(checkVerificationStatus, 5000); // Check every 5 seconds
		return () => clearInterval(interval);
	});
</script>

<div
	class="mx-auto h-full w-full rounded-lg bg-gray-300 p-5 py-2.5 shadow-md sm:w-[95%] md:w-[90%] lg:w-[80%] dark:bg-gray-400"
>
	{#if verified}
		<h1>Email Verified!</h1>
		<p>Your email has been successfully verified.</p>
		<button onclick={() => goto(`/users/[{user.id}]/dasboard`)}>Continue to Dashboard</button>
	{:else}
		<h1>Please verify your email</h1>
		<p>Check your inbox and click the verification link we sent you.</p>
		<p>Once verified, you'll be automatically redirected.</p>
	{/if}
</div>
