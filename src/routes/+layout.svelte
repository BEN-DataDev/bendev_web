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
	import { ChevronDownOutline, MapLocationOutline } from 'flowbite-svelte-icons';

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

	let megaMenuLeft = $state('0px');
	let projectsNavLi: HTMLElement | null = null;

	$effect(() => {
		if (projectsNavLi && megaStatus) {
			const rect = projectsNavLi.getBoundingClientRect();
			megaMenuLeft = `${rect.left}px`;
		}
	});

	$effect(() => {
		dropdownUserStatus = dropdownUser.isOpen;
		navStatus = nav.isOpen;
	});

	let { data, children }: Props = $props();
	let { session, supabase, user, roles } = $derived(data);

	let avatarSrc = $state<string | null>(null);
	let mega = uiHelpers();
	let megaStatus = $state(false);
	const toggleProjects = mega.toggle;

	$effect(() => {
		avatarSrc = user?.user_metadata?.picture || null;
		megaStatus = mega.isOpen;
	});

	let projects = [
		{ name: 'About us', href: '/about', Icon: MapLocationOutline },
		{ name: 'Blog', href: '/blog', Icon: MapLocationOutline },
		{ name: 'Contact us', href: '/contact', Icon: MapLocationOutline },
		{ name: 'Library', href: '/library', Icon: MapLocationOutline },
		{ name: 'Newsletter', href: '/news', Icon: MapLocationOutline },
		{ name: 'Support Center', href: '/support', Icon: MapLocationOutline },
		{ name: 'Resources', href: '/resource', Icon: MapLocationOutline },
		{ name: 'Playground', href: '/play', Icon: MapLocationOutline },
		{ name: 'Terms', href: '/tersm', Icon: MapLocationOutline },
		{ name: 'Pro Version', href: '/pro', Icon: MapLocationOutline },
		{ name: 'License', href: '/license', Icon: MapLocationOutline }
	];

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
			<NavLi class="cursor-pointer" onclick={toggleProjects}>
				<span bind:this={projectsNavLi}>
					My Projects<ChevronDownOutline
						class="ms-2 inline h-6 w-6 text-primary-800 dark:text-white"
					/>
				</span>
			</NavLi>
		</NavUl>
	</Navbar>
	<div class="relative">
		<MegaMenu
			items={projects}
			dropdownStatus={megaStatus}
			class="absolute top-[60px] w-[450px] bg-slate-200"
			style="left: {megaMenuLeft};"
		>
			{#snippet children(prop)}
				<a
					href={prop.item.href}
					class="flex items-center hover:text-primary-600 dark:hover:text-primary-500"
				>
					<prop.item.Icon class="me-2 h-4 w-4" />
					{prop.item.name}
				</a>
			{/snippet}
		</MegaMenu>
	</div>
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
