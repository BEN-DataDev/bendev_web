<script lang="ts">
	import { Heading } from 'svelte-5-ui-lib';
	import type { PageData } from './$types';

	interface Props {
		data: PageData;
		children?: import('svelte').Snippet;
	}

	let { data }: Props = $props();
</script>

// TODO Specific user's dashboard
// TODO Dashboard + activity display
<svelte:head>
	<title>Dashboard</title>
</svelte:head>

<div class="mx-auto h-full rounded-lg bg-gray-300 p-5 py-2.5 shadow-md dark:bg-gray-400">
	<Heading tag="h3">Dashboard</Heading>
	<p>This is the main content of the dashboard / workspace page.</p>
	<pre>{JSON.stringify(data.roles)}</pre>
</div>
