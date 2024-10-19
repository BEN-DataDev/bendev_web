<script lang="ts">
	import { page } from '$app/stores';
	import { Heading, Toast } from 'svelte-5-ui-lib';
	import { CheckCircleSolid, XCircleSolid } from 'flowbite-svelte-icons';
	import { linear } from 'svelte/easing';
	import { fade } from 'svelte/transition';

	interface ToastProps {
		message?: string;
		status?: 'success' | 'error';
		color?: 'green' | 'red';
		position?: 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left';
	}

	let toastProps: ToastProps = $state({});
	let showToast = $state(false);

	$effect(() => {
		const signoutStatus = $page.url.searchParams.get('signout');
		if (signoutStatus === 'success') {
			toastProps = {
				message: 'Successfully signed out',
				status: 'success',
				color: 'green',
				position: 'bottom-right'
			};
			showToastWithTimer();
		} else if (signoutStatus === 'error') {
			const errorMessage =
				$page.url.searchParams.get('message') || 'An error occurred during sign out';
			toastProps = {
				message: decodeURIComponent(errorMessage),
				status: 'error',
				color: 'red',
				position: 'bottom-right'
			};
			showToastWithTimer();
		}
	});

	function hideToast() {
		showToast = false;
	}

	function showToastWithTimer() {
		showToast = true;
		setTimeout(hideToast, 5000); // 5000 milliseconds = 5 seconds
	}

	function clearToast() {
		toastProps = {};
		showToastWithTimer();
	}

	function getToastClasses(status: 'success' | 'error' | undefined) {
		const baseClasses = 'text-white';
		if (status === 'success') {
			return `${baseClasses}  opacity-80 bg-green-300 dark:bg-green-400`;
		} else if (status === 'error') {
			return `${baseClasses}  opacity-80 bg-red-300 dark:bg-red-400`;
		}
		return baseClasses;
	}
</script>

{#if showToast && toastProps}
	<div transition:fade={{ duration: 300 }}>
		{#snippet icon()}
			{#if toastProps.status === 'success'}
				<CheckCircleSolid />
			{:else}
				<XCircleSolid />
			{/if}
		{/snippet}
		<Toast
			position={toastProps.position}
			color={toastProps.color}
			baseClass={getToastClasses(toastProps.status)}
			iconClass="w-10 h-10 rounded-full"
			transition={fade}
			params={{ duration: 500, easing: linear }}
			{icon}
			onclose={clearToast}
		>
			<div class="mt-3 flex items-center">
				<div class="ms-3">
					<h4 class="text-sm font-semibold text-gray-900 dark:text-white">{toastProps.message}</h4>
				</div>
			</div></Toast
		>
	</div>
{/if}

<div
	class="mx-auto h-full w-full rounded-lg bg-gray-300 p-5 py-2.5 shadow-md sm:w-[95%] md:w-[90%] lg:w-[80%] dark:bg-gray-400"
>
	<Heading tag="h1" class="text-center text-[#0509f7] dark:text-[#0509f7]"
		>Welcome to the Batlow Environment Network</Heading
	>
	<Heading tag="h2" class="text-center text-blue-600">Community Information Infrastructure</Heading>
	<p class="text-center text-xl text-gray-800">
		Empowering neighborhoods with data-driven resilience
	</p>

	<div class="container mx-auto rounded-lg bg-white p-8 px-4 py-8 shadow-lg">
		<div class="prose lg:prose-xl mx-auto">
			<p class="mb-4">
				Imagine empowering communities with their own digital nervous system - a Community
				Information Infrastructure built on open-source code and free cloud services. This platform
				allows neighborhoods to collect, own, and leverage their local data, fostering stronger
				connections and resilience.
			</p>
			<p class="mb-4">
				By harnessing freely available technologies, we're democratizing data management, giving
				communities the tools to understand their needs, coordinate resources, and respond to
				challenges. It's not just about information; it's about transformation - turning fragmented
				neighborhoods into cohesive, responsive communities equipped for the future.
			</p>
			<p class="text-center font-bold text-blue-600">
				Join us in building stronger, smarter, and more resilient communities from the ground up.
			</p>
		</div>
	</div>
</div>
