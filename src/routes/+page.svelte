<script lang="ts">
	import { page } from '$app/stores';
	// Migrated to native toast implementation
	import Icon from '$components/icons/Icons.svelte';
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
	<div
		class="fixed {toastProps.position === 'bottom-right' ? 'bottom-4 right-4' : toastProps.position === 'top-right' ? 'top-4 right-4' : toastProps.position === 'bottom-left' ? 'bottom-4 left-4' : 'top-4 left-4'} z-50 flex items-center gap-3 rounded-lg p-4 shadow-lg {getToastClasses(toastProps.status)}"
		transition:fade={{ duration: 300 }}
		role="alert"
	>
		<div class="flex-shrink-0">
			{#if toastProps.status === 'success'}
				<Icon name="circle-check" class="h-6 w-6" />
			{:else}
				<Icon name="circle-x" class="h-6 w-6" />
			{/if}
		</div>
		<div class="flex-1">
			<h4 class="text-sm font-semibold">
				{toastProps.message}
			</h4>
		</div>
		<button
			class="flex-shrink-0 text-white hover:text-white/70"
			onclick={clearToast}
			aria-label="Close"
		>
			<Icon name="circle-x" class="h-5 w-5" />
		</button>
	</div>
{/if}

<div
	class="mx-auto h-full w-full rounded-lg bg-surface-100 p-5 py-2.5 shadow-md sm:w-[95%] md:w-[90%] lg:w-[80%] dark:bg-surface-800"
>
	<h1 class="h1 text-center text-tertiary-600 dark:text-tertiary-400"
		>Welcome to the Batlow Environment Network</h1
	>
	<h2 class="h2 text-center text-tertiary-600 dark:text-tertiary-400"
		>Community Information Infrastructure</h2
	>
	<p class="text-center text-xl text-surface-800 dark:text-surface-200">
		Empowering neighborhoods with data-driven resilience
	</p>

	<div class="container mx-auto rounded-lg bg-fill-100 p-8 px-4 py-8 shadow-lg">
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
			<p class="text-center font-bold text-tertiary-900 dark:text-tertiary-700">
				Join us in building stronger, smarter, and more resilient communities from the ground up.
			</p>
		</div>
	</div>
</div>
