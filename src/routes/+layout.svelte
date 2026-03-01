<script lang="ts">
	import { invalidate } from '$app/navigation';
	import { onMount } from 'svelte';
	import Icon from '$components/icons/Icons.svelte';
	import { browser } from '$app/environment';

	import type { LayoutData } from './$types';

	import './layout.css';

	interface Props {
		data: LayoutData;
		children?: import('svelte').Snippet;
	}

	let { data, children }: Props = $props();
	let { session, supabase, user } = $derived(data);

	let avatarSrc = $state<string | null>(null);
	let mobileMenuOpen = $state(false);
	let userDropdownOpen = $state(false);
	let darkMode = $state(true);

	$effect(() => {
		avatarSrc = user?.user_metadata?.picture || null;
	});

	$effect(() => {
		if (browser) {
			const html = document.documentElement;
			html.setAttribute('data-mode', darkMode ? 'dark' : 'light');
		}
	});

	function toggleDarkMode() {
		darkMode = !darkMode;
	}

	function toggleMobileMenu() {
		mobileMenuOpen = !mobileMenuOpen;
		if (mobileMenuOpen) {
			userDropdownOpen = false;
		}
	}

	function toggleUserDropdown() {
		userDropdownOpen = !userDropdownOpen;
	}

	function closeDropdowns() {
		userDropdownOpen = false;
		mobileMenuOpen = false;
	}

	onMount(() => {
		const { data: authData } = supabase.auth.onAuthStateChange((_, newSession) => {
			if (newSession?.expires_at !== session?.expires_at) {
				invalidate('supabase:auth');
			}
		});

		return () => authData.subscription.unsubscribe();
	});
</script>

<!-- svelte-ignore a11y_click_events_have_key_events -->
<!-- svelte-ignore a11y_no_static_element_interactions -->
<div class="flex h-screen flex-col" onclick={closeDropdowns}>
	<!-- Header / Navbar -->
	<header
		class="sticky top-0 z-10 border-b border-surface-200 bg-surface-100 dark:border-surface-700 dark:bg-surface-800"
	>
		<nav class="mx-auto flex max-w-7xl items-center justify-between p-4">
			<!-- Brand / Logo -->
			<div class="flex items-center gap-3">
				<a href="/" class="flex items-center gap-2">
					<img
						width="40"
						src="/images/logo.jfif"
						alt="ben logo"
						class="rounded-full object-cover"
					/>
					<span class="text-lg font-semibold text-tertiary-800 dark:text-tertiary-200">
						Batlow Environment Network
					</span>
				</a>
			</div>

			<!-- Desktop Navigation -->
			<div class="hidden items-center gap-6 md:flex">
				<a
					href="/"
					class="text-secondary-800 hover:text-primary-600 dark:text-secondary-100 dark:hover:text-primary-400"
				>
					Home
				</a>
				{#if user}
					<a
						href={`/users/${user.id}/dashboard`}
						class="hover:text-primary-600 dark:hover:text-primary-400"
					>
						My Account
					</a>
					<a
						href="/communities"
						class="hover:text-primary-600 dark:hover:text-primary-400"
					>
						Communities
					</a>
					<a href="/projects" class="hover:text-primary-600 dark:hover:text-primary-400">
						Projects
					</a>
					<a href="/users" class="hover:text-primary-600 dark:hover:text-primary-400">
						Users
					</a>
				{/if}
			</div>

			<!-- Actions -->
			<div class="flex items-center gap-2">
				<!-- Dark Mode Toggle -->
				<button
					onclick={(e) => {
						e.stopPropagation();
						toggleDarkMode();
					}}
					class="btn preset-tonal-surface-200-800 p-2"
					aria-label="Toggle dark mode"
				>
					{#if darkMode}
						<Icon name="sun" class="h-5 w-5" />
					{:else}
						<Icon name="moon" class="h-5 w-5" />
					{/if}
				</button>

				{#if !user}
					<a href="/auth/signin" class="btn preset-filled-primary-500">Sign In</a>
				{:else}
					<!-- User Avatar & Dropdown -->
					<div class="relative">
						<button
							onclick={(e) => {
								e.stopPropagation();
								toggleUserDropdown();
							}}
							class="flex items-center gap-2"
							aria-label="User menu"
						>
							{#if avatarSrc}
								<img
									src={avatarSrc}
									alt="User avatar"
									class="h-8 w-8 rounded-full border-2 border-success-500 object-cover"
								/>
							{:else}
								<div
									class="flex h-8 w-8 items-center justify-center rounded-full border-2 border-success-500 bg-primary-500"
								>
									<Icon name="user" class="h-5 w-5 text-white" />
								</div>
							{/if}
						</button>

						{#if userDropdownOpen}
							<div
								class="card preset-outlined-surface-200-800 absolute right-0 top-12 min-w-[240px] overflow-hidden bg-surface-50 shadow-xl dark:bg-surface-900"
								onclick={(e) => e.stopPropagation()}
							>
								<!-- Header -->
								<div class="bg-surface-100 px-4 py-3 dark:bg-surface-800">
									<p class="text-sm font-medium text-surface-900 dark:text-surface-50">
										{user.user_metadata?.full_name || 'User'}
									</p>
									<p class="truncate text-xs text-surface-600 dark:text-surface-300">
										{user.email}
									</p>
								</div>

								<!-- Menu Items -->
								<div class="py-2">
									<a
										href={`/users/${user.id}/profile`}
										class="block px-4 py-2 text-sm hover:bg-surface-100 hover:text-primary-600 dark:hover:bg-surface-800 dark:hover:text-primary-400"
									>
										My Profile
									</a>
									<a
										href={`/users/${user.id}/dashboard`}
										class="block px-4 py-2 text-sm hover:bg-surface-100 hover:text-primary-600 dark:hover:bg-surface-800 dark:hover:text-primary-400"
									>
										My Dashboard
									</a>
								</div>

								<div class="border-t border-surface-200 dark:border-surface-700"></div>

								<!-- Footer -->
								<div class="px-4 py-2">
									<p class="text-xs text-surface-600 dark:text-surface-300">
										<span class="font-medium">Role:</span>
										{user.role || 'member'}
									</p>
								</div>

								<div class="border-t border-surface-200 dark:border-surface-700"></div>

								<div class="py-2">
									<a
										href="/auth/signout"
										class="block px-4 py-2 text-sm hover:bg-surface-100 hover:text-primary-600 dark:hover:bg-surface-800 dark:hover:text-primary-400"
									>
										Sign Out
									</a>
								</div>
							</div>
						{/if}
					</div>
				{/if}

				<!-- Mobile Menu Toggle -->
				<button
					onclick={(e) => {
						e.stopPropagation();
						toggleMobileMenu();
					}}
					class="btn preset-tonal-surface-200-800 p-2 md:hidden"
					aria-label="Toggle mobile menu"
				>
					{#if mobileMenuOpen}
						<Icon name="x" class="h-5 w-5" />
					{:else}
						<Icon name="menu" class="h-5 w-5" />
					{/if}
				</button>
			</div>
		</nav>

		<!-- Mobile Navigation -->
		{#if mobileMenuOpen}
			<div class="border-t border-surface-200 bg-surface-100 dark:border-surface-700 dark:bg-surface-800 md:hidden">
				<div class="flex flex-col gap-1 p-4">
					<a
						href="/"
						class="rounded px-3 py-2 hover:bg-surface-200 hover:text-primary-600 dark:hover:bg-surface-700 dark:hover:text-primary-400"
					>
						Home
					</a>
					{#if user}
						<a
							href={`/users/${user.id}/dashboard`}
							class="rounded px-3 py-2 hover:bg-surface-200 hover:text-primary-600 dark:hover:bg-surface-700 dark:hover:text-primary-400"
						>
							My Account
						</a>
						<a
							href="/communities"
							class="rounded px-3 py-2 hover:bg-surface-200 hover:text-primary-600 dark:hover:bg-surface-700 dark:hover:text-primary-400"
						>
							Communities
						</a>
						<a
							href="/projects"
							class="rounded px-3 py-2 hover:bg-surface-200 hover:text-primary-600 dark:hover:bg-surface-700 dark:hover:text-primary-400"
						>
							Projects
						</a>
						<a
							href="/users"
							class="rounded px-3 py-2 hover:bg-surface-200 hover:text-primary-600 dark:hover:bg-surface-700 dark:hover:text-primary-400"
						>
							Users
						</a>
					{/if}
				</div>
			</div>
		{/if}
	</header>

	<!-- Main Content -->
	<main class="flex flex-1 overflow-hidden">
		{@render children?.()}
	</main>

	<!-- Footer -->
	<footer
		class="border-t border-surface-200 bg-surface-100 py-3 dark:border-surface-700 dark:bg-surface-800"
	>
		<div class="mx-auto max-w-7xl px-4 sm:flex sm:items-center sm:justify-between">
			<p class="text-sm text-surface-700 dark:text-surface-300">
				© 2024 Batlow Environment Network
			</p>
			<div class="mt-3 flex flex-wrap items-center gap-4 text-sm sm:mt-0">
				<a href="/" class="hover:text-primary-600 dark:hover:text-primary-400">About</a>
				<a href="/" class="hover:text-primary-600 dark:hover:text-primary-400">Privacy Policy</a>
				<a href="/" class="hover:text-primary-600 dark:hover:text-primary-400">Licensing</a>
				<a href="/" class="hover:text-primary-600 dark:hover:text-primary-400">Contact</a>
			</div>
		</div>
	</footer>
</div>
