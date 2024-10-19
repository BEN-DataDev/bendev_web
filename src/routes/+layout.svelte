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
		FooterCopyright
	} from 'svelte-5-ui-lib';

	import type { PageData } from './$types';

	import '../app.css';

	interface Props {
		data: PageData;
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
		navClass="bg-gray-200 dark:bg-gray-900 border-b border-gray-300 dark:border-gray-700"
	>
		{#snippet brand()}
			<NavBrand siteName="Batlow Environment Network">
				<img width="60" src="/images/logo.jfif" alt="ben logo" class="rounded-full object-cover" />
			</NavBrand>
		{/snippet}
		{#snippet navSlotBlock()}
			<div class="flex items-center space-x-1 md:order-2">
				<Darkmode />
				{#if !user}
					<Button href="/auth/login" size="sm">Sign In</Button>
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
							class="dropdown-content absolute right-0 top-[14px]"
						>
							<DropdownHeader class="px-4 py-2">
								<span class="block text-sm text-gray-900 dark:text-white"
									>{user.user_metadata?.full_name || 'User'}</span
								>
								<span class="block truncate text-sm font-medium">{user.email}</span>
							</DropdownHeader>
							<DropdownUl>
								<DropdownLi href="/myprofile">My Profile</DropdownLi>
								<DropdownLi href="/mydashboard">My Dashboard</DropdownLi>
								<DropdownDivider />
								<DropdownLi href="/auth/signout">Sign Out</DropdownLi>
							</DropdownUl>
							<DropdownFooter class="px-4 py-2 text-sm hover:bg-gray-100 dark:hover:bg-gray-600"
								><span class="font-medium">Role: </span>{' '}{user.role}
							</DropdownFooter>
						</Dropdown>
					</div>
				{/if}
			</div>
		{/snippet}
		<NavUl class="text-2xl">
			<NavLi href="/">Home</NavLi>
			<NavLi href="/components/navbar">Navbar</NavLi>
			<NavLi href="/components/footer">Footer</NavLi>
		</NavUl>
	</Navbar>
	<main class="flex-1 overflow-y-auto">
		{@render children?.()}
	</main>
	<Footer class="border-b border-gray-300 bg-gray-200 shadow-none" footerType="logo">
		<div class="sm:flex sm:items-center sm:justify-between">
			<FooterCopyright href="/" by="Batlow Environment Network" year={2024} />
			<FooterUl
				class="mt-3 flex flex-wrap items-center text-sm text-gray-500 sm:mt-0 dark:text-gray-400"
			>
				<FooterLi href="/">About</FooterLi>
				<FooterLi href="/">Privacy Policy</FooterLi>
				<FooterLi href="/">Licensing</FooterLi>
				<FooterLi href="/">Contact</FooterLi>
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
