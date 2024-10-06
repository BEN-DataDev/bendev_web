<script lang="ts">
	import { createEventDispatcher } from 'svelte';
	import { Button, Heading } from 'svelte-5-ui-lib';
	import { GithubSolid, DiscordSolid, LinkedinSolid } from 'flowbite-svelte-icons';

	const socialProviders = $state([
		{ name: 'GitHub', icon: GithubSolid, color: 'fuchsia', provider: 'github' },
		{ name: 'Discord', icon: DiscordSolid, color: 'gray', provider: 'discord' },
		{ name: 'LinkedIn', icon: LinkedinSolid, color: 'blue', provider: 'linkedin' }
	]);

	function signInWithSocial(provider: 'github' | 'discord' | 'linkedin') {
		dispatch('socialSignIn', { provider });
	}

	const dispatch = createEventDispatcher();
</script>

<div class="social-media-registration">
	<Heading tag="h6" class="pt-0 text-[#0509f7] dark:text-[#0509f7]">Or sign up with:</Heading>
	<div class="flex flex-col justify-center space-y-3">
		{#each socialProviders as { name, icon: Icon, color, provider }}
			<Button
				size="small"
				{color}
				class="flex w-full items-center py-1.5 opacity-70"
				onclick={() => signInWithSocial(provider as 'github' | 'discord' | 'linkedin')}
			>
				<Icon class="mr-2 h-5 w-5" />
				{name}
			</Button>
		{/each}
	</div>
</div>

<style>
	.social-media-registration {
		margin-top: 10px;
	}
</style>
