<script lang="ts">
	import { invalidate } from '$app/navigation';
	import { onMount } from 'svelte';
	import { sineIn } from 'svelte/easing';

	import { Darkmode } from 'svelte-5-ui-lib';
	import {
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
		DropdownFooter
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
	let isUserSignedIn = $state(false);

	$effect(() => {
		dropdownUserStatus = dropdownUser.isOpen;
		navStatus = nav.isOpen;
	});

	let { data, children } = $props();
	let { session, supabase } = $derived(data);

	onMount(() => {
		const { data } = supabase.auth.onAuthStateChange((_, newSession) => {
			if (newSession?.expires_at !== session?.expires_at) {
				invalidate('supabase:auth');
			}
		});

		return () => data.subscription.unsubscribe();
	});
</script>

<div class="app-container">
	<div class="navbar-container">
		<Navbar
			{toggleNav}
			{closeNav}
			{navStatus}
			breakPoint="md"
			navClass="absolute w-full z-20 top-0 start-0 bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-700"
		>
			{#snippet brand()}
				<NavBrand siteName="Batlow Environment Network">
					<img
						width="60"
						src="/images/logo.jfif"
						alt="ben logo"
						class="rounded-full object-cover"
					/>
				</NavBrand>
			{/snippet}
			{#snippet navSlotBlock()}
				<div class="flex items-center space-x-1 md:order-2">
					<Darkmode />
					{#if !isUserSignedIn}
						<Button href="/signup" size="sm">Sign In</Button>
					{:else}
						<Avatar
							onclick={dropdownUser.toggle}
							src="/images/profile-picture-3.webp"
							dot={{ color: 'green' }}
						/>
						<div class="relative">
							<Dropdown
								dropdownStatus={dropdownUserStatus}
								closeDropdown={closeDropdownUser}
								params={{ y: 0, duration: 200, easing: sineIn }}
								class="absolute -left-[110px] top-[14px] md:-left-[160px] "
							>
								<DropdownHeader class="px-4 py-2">
									<span class="block text-sm text-gray-900 dark:text-white">Bonnie Green</span>
									<span class="block truncate text-sm font-medium">name@flowbite.com</span>
								</DropdownHeader>
								<DropdownUl>
									<DropdownLi href="/">Dashboard</DropdownLi>
									<DropdownLi href="/components/drawer">Drawer</DropdownLi>
									<DropdownLi href="/components/footer">Footer</DropdownLi>
									<DropdownLi href="/components">Alert</DropdownLi>
								</DropdownUl>
								<DropdownFooter class="px-4 py-2 text-sm hover:bg-gray-100 dark:hover:bg-gray-600"
									>Sign out</DropdownFooter
								>
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
	</div>
	<div class="content-container">
		{@render children?.()}
	</div>
</div>

<style>
	.app-container {
		display: flex;
		flex-direction: column;
		min-height: 100vh;
	}

	.navbar-container {
		position: sticky;
		top: 0;
		z-index: 20;
	}

	.content-container {
		flex: 1;
		padding-top: 90px; /* Adjust this value based on your Navbar height */
	}
</style>
