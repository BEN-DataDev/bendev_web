<script lang="ts">
	import Icon from '$components/icons/Icons.svelte';

	type IconName = 'github' | 'moon' | 'sun' | 'user' | 'menu' | 'x' | 'eye' | 'eye-off' | 'circle-check' | 'circle-x' | 'chevrons-left' | 'chevrons-right' | 'chevrons-up' | 'chevrons-down' | 'settings' | 'user-circle' | 'users';

	const socialProviders = $state<Array<{ name: string; iconName: IconName; provider: string }>>([
		{ name: 'GitHub', iconName: 'github' as IconName, provider: 'github' }
		// TODO: Add Discord, Google, Microsoft icons when implementing social auth UI
	]);
</script>

<div class="mt-3">
	<h6 class="h6 pt-0 text-primary-600 dark:text-primary-400">Or sign up with:</h6>
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
