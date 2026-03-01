<script lang="ts">
	
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

<div class="card preset-outlined-surface-200-800 mx-auto h-full p-5 py-2.5 shadow-md">
	<h3 class="h3">Profile</h3>
	<p>This is the main content of the profile page.</p>
	<pre>{JSON.stringify(data.roles)}</pre>
</div>
