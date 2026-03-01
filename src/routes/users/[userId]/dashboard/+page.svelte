<script lang="ts">
	
	import type { PageData } from './$types';

	interface Props {
		data: PageData;
	}

	let { data }: Props = $props();
</script>

// TODO Specific user's dashboard
// TODO Dashboard + activity display
<svelte:head>
	<title>Dashboard</title>
</svelte:head>

<div class="card preset-outlined-surface-200-800 mx-auto h-full p-5 shadow-md">
	<h3 class="h3">Dashboard</h3>
	<p>This is the main content of the dashboard / workspace page.</p>
	<pre>{JSON.stringify(data.roles)}</pre>
</div>
