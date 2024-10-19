<script lang="ts">
	import { Button, Heading } from 'svelte-5-ui-lib';
	import { GithubSolid, DiscordSolid } from 'flowbite-svelte-icons';

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

	const socialProviders = $state([
		{ name: 'GitHub', icon: GithubSolid, color: 'fuchsia', provider: 'github' },
		{ name: 'Discord', icon: DiscordSolid, color: 'gray', provider: 'discord' }
	]);
</script>

<div class="mt-3">
	<Heading tag="h6" class="pt-0 text-[#0509f7] dark:text-[#0509f7]">Or sign up with:</Heading>
	<div class="flex flex-col justify-center space-y-3">
		{#each socialProviders as { name, icon: Icon, color, provider }}
			<Button
				size="sm"
				color={color as ButtonColorType}
				class="flex w-full items-center py-1.5 opacity-70"
				href={`/auth/login/${provider}`}
			>
				<Icon class="mr-2 h-5 w-5" />
				{name}
			</Button>
		{/each}
	</div>
</div>
