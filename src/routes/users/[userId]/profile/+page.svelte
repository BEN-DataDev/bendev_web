<script lang="ts">
	import { Heading } from 'svelte-5-ui-lib';
	import type { PageData } from './$types';

	interface Props {
		data: PageData;
		children?: import('svelte').Snippet;
	}

	let { data }: Props = $props();
</script>

// TODO Specific user's profile
<svelte:head>
	<title>Profile</title>
</svelte:head>

<div class="mx-auto h-full rounded-lg bg-gray-300 p-5 py-2.5 shadow-md dark:bg-gray-400">
	<Heading tag="h3">Profile</Heading>
	<p>This is the main content of the profile page.</p>
	<pre>{JSON.stringify(data.roles)}</pre>
</div>
