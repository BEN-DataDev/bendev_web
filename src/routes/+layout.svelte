<script lang="ts">
	import { invalidate } from '$app/navigation';
	import { onMount } from 'svelte';
	import { sineIn } from 'svelte/easing';

	import {
		Darkmode,
		Navbar,
		NavBrand,
		NavUl,
		NavLi,
		uiHelpers,
		Dropdown,
		DropdownHeader,
		DropdownUl,
		DropdownLi,
		DropdownDivider,
		Button,
		Avatar,
		DropdownFooter,
		Footer,
		FooterLi,
		FooterUl,
		MegaMenu,
		FooterCopyright
	} from 'svelte-5-ui-lib';

	import type { LayoutData } from './$types';

	import '../app.css';
	import { ChevronDownOutline, MapPinOutline } from 'flowbite-svelte-icons';

	interface Props {
		data: LayoutData;
		children?: import('svelte').Snippet;
	}

	let nav = uiHelpers();
	let navStatus = $state(false);
	let dropdownUser = uiHelpers();
	let dropdownUserStatus = $state(false);
	let closeDropdownUser = dropdownUser.close;
	let toggleNav = nav.toggle;
	let closeNav = nav.close;

	$effect(() => {
		dropdownUserStatus = dropdownUser.isOpen;
		navStatus = nav.isOpen;
	});

	let { data, children }: Props = $props();
	let { session, supabase, user } = $derived(data);

	let avatarSrc = $state<string | null>(null);

	$effect(() => {
		avatarSrc = user?.user_metadata?.picture || null;
	});

	onMount(() => {
		const { data } = supabase.auth.onAuthStateChange((_, newSession) => {
			if (newSession?.expires_at !== session?.expires_at) {
				invalidate('supabase:auth');
			}
		});

		return () => data.subscription.unsubscribe();
	});
</script>

<div class="flex h-screen flex-col">
	<Navbar
		{toggleNav}
		{closeNav}
		{navStatus}
		breakPoint="md"
		navClass="bg-fill-300 dark:bg-fill-800 border-b border-surface-200 dark:border-surface-700"
	>
		{#snippet brand()}
			<NavBrand
				siteName="Batlow Environment Network"
				spanClass="text-tertiary-800 dark:text-tertiary-200"
			>
				<img width="60" src="/images/logo.jfif" alt="ben logo" class="rounded-full object-cover" />
			</NavBrand>
		{/snippet}
		{#snippet navSlotBlock()}
			<div class="flex items-center space-x-1 md:order-2">
				<Darkmode />
				{#if !user}
					<Button href="/auth/signin" size="sm">Sign In</Button>
				{:else}
					{#if avatarSrc}
						<Avatar
							class="cursor-pointer"
							onclick={dropdownUser.toggle}
							src={user?.user_metadata?.picture}
							dot={{ color: 'green' }}
						/>
					{:else}
						<Avatar border dot={{ color: 'green' }} class="cursor-pointer" />
					{/if}
					<div class="relative">
						<Dropdown
							dropdownStatus={dropdownUserStatus}
							closeDropdown={closeDropdownUser}
							params={{ y: 0, duration: 200, easing: sineIn }}
							class="dropdown-content absolute right-0 top-[14px] border border-surface-200 bg-fill-50 dark:border-surface-700 dark:bg-fill-800"
						>
							<DropdownHeader class="bg-fill-100 px-4 py-2 dark:bg-fill-700">
								<span class="block text-sm text-text-900 dark:text-text-50"
									>{user.user_metadata?.full_name || 'User'}</span
								>
								<span class="block truncate text-sm font-medium text-text-600 dark:text-text-300"
									>{user.email}</span
								>
							</DropdownHeader>
							<DropdownUl>
								<DropdownLi
									href="/users/[{user.id}]/profile"
									class="cursor-pointer hover:text-primary-600 dark:hover:text-primary-400"
									>My Profile</DropdownLi
								>
								<DropdownLi
									href="/users/[{user.id}]/dashboard"
									class="cursor-pointer hover:text-primary-600 dark:hover:text-primary-400"
									>My Dashboard</DropdownLi
								>
								<DropdownDivider />
								<DropdownLi
									href="/auth/signout"
									class="cursor-pointer hover:text-primary-600 dark:hover:text-primary-400"
									>Sign Out</DropdownLi
								>
							</DropdownUl>
							<DropdownFooter
								class="bg-fill-100 px-4 py-2 text-sm hover:bg-gray-100 dark:bg-fill-700 dark:hover:bg-gray-600"
								><span class="font-medium text-text-600 dark:text-text-300"
									>Role:
								</span>{' '}{user.role}
							</DropdownFooter>
						</Dropdown>
					</div>
				{/if}
			</div>
		{/snippet}
		<NavUl class="flex h-10 items-center justify-center text-secondary-800 dark:text-secondary-100">
			<NavLi href="/" class="pl-4 hover:text-primary-600 dark:hover:text-primary-400">Home</NavLi>
			{#if user}
				<NavLi
					href="/users/[{user.id}]/dashboard"
					class="hover:text-primary-600 dark:hover:text-primary-400">My Account</NavLi
				>
				<NavLi href="/communities" class="pr-4 hover:text-primary-600 dark:hover:text-primary-400"
					>Communities</NavLi
				>
				<NavLi href="/projects" class="pr-4 hover:text-primary-600 dark:hover:text-primary-400"
					>Projects</NavLi
				>
				<NavLi href="/users" class="pr-4 hover:text-primary-600 dark:hover:text-primary-400"
					>Users</NavLi
				>
			{/if}
			<!-- <NavLi
				class="cursor-pointer hover:text-primary-600 dark:hover:text-primary-400"
				onclick={toggleProjects}
			>
				<span bind:this={projectsNavLi}>
					My Projects<ChevronDownOutline
						class="ms-2 inline h-6 w-6  text-primary-600 dark:text-primary-400"
					/>
				</span>
			</NavLi> -->
		</NavUl>
	</Navbar>
	<!-- <div class="relative">
		<MegaMenu
			items={projects}
			dropdownStatus={megaStatus}
			class="absolute top-[60px] w-[450px] bg-fill-100 dark:bg-fill-800"
			style="left: {megaMenuLeft};"
		>
			{#snippet children(prop)}
				<a
					href={prop.item.href}
					class="flex items-center text-text-700 hover:text-primary-600 dark:text-text-200 dark:hover:text-primary-400"
				>
					<prop.item.Icon class="me-2 h-4 w-4" />
					{prop.item.name}
				</a>
			{/snippet}
		</MegaMenu>
	</div> -->
	<main class="flex flex-1 overflow-hidden">
		{@render children?.()}
	</main>
	<Footer
		class="border-t border-surface-200 bg-fill-100 py-3 shadow-none md:py-3 dark:border-surface-700 dark:bg-fill-800"
		footerType="logo"
	>
		<div class="sm:flex sm:items-center sm:justify-between">
			<FooterCopyright
				href="/"
				class="text-text-700 dark:text-text-300"
				by="Batlow Environment Network"
				year={2024}
			/>
			<FooterUl
				class="mt-3 flex flex-wrap items-center text-sm text-text-800 sm:mt-0 dark:text-text-300"
			>
				<FooterLi href="/" class="hover:text-primary-600 dark:hover:text-primary-400"
					>About</FooterLi
				>
				<FooterLi href="/" class="hover:text-primary-600 dark:hover:text-primary-400"
					>Privacy Policy</FooterLi
				>
				<FooterLi href="/" class="hover:text-primary-600 dark:hover:text-primary-400"
					>Licensing</FooterLi
				>
				<FooterLi href="/" class="hover:text-primary-600 dark:hover:text-primary-400"
					>Contact</FooterLi
				>
			</FooterUl>
		</div>
	</Footer>
</div>

<style>
	:global(.dropdown-content) {
		min-width: max-content;
		white-space: nowrap;
	}

	:global(.dropdown-content ul) {
		width: 100%;
	}

	:global(.dropdown-content li) {
		width: 100%;
		box-sizing: border-box;
	}
</style>
