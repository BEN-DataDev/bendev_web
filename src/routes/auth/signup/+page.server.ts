import { redirect } from '@sveltejs/kit';
import { generateAvatar } from '$lib/server';
import type { Actions } from './$types';

export const actions: Actions = {
	signup: async ({ url, request, locals: { supabase } }) => {
		const formData = await request.formData();
		const firstName = formData.get('firstName') as string;
		const lastName = formData.get('lastName') as string;
		const email = formData.get('email') as string;
		const password = formData.get('password') as string;
		const provider = formData.get('provider') as string;
		const avatar = formData.get('avatar') as File | null;
		const initials = formData.get('initials') as string;
		const avatarColor = formData.get('avatarColor') as string;

		let avatarFile = avatar;

		if (!avatarFile || avatarFile.size === 0) {
			avatarFile = generateAvatar(initials, avatarColor);
		}
		console.log('url.origin:', url.origin);

		switch (provider) {
			case 'email':
				const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
					email,
					password,
					options: {
						data: {
							firstName,
							lastName
						}
					}
				});
				if (signUpError) {
					return {
						errors: {
							email: 'Invalid email'
							// ... other error fields
						}
					};
				}
				break;
			case 'github':
				const { data: githubData, error: githubError } = await supabase.auth.signInWithOAuth({
					provider: 'github',
					options: {
						redirectTo: `${url.origin}/authorised/profile`
					}
				});
				console.log('GitHub data:', githubData.url);
				if (githubError) {
					console.error('GitHub error:', githubError);
					return {
						errors: {
							email: 'Invalid email'
							// ... other error fields
						}
					};
				}
				if (githubData.url) {
					console.log('Redirecting to GitHub URL:', githubData.url);
					redirect(303, githubData.url);
				}
				break;
			case 'discord':
				const { data: discordData, error: discordError } = await supabase.auth.signInWithOAuth({
					provider: 'discord',
					options: {
						redirectTo: `${url.origin}/auth/callback`
					}
				});
				if (discordError) {
					return {
						errors: {
							email: 'Failed to sign in with Discord'
							// ... other error fields
						}
					};
				}
				break;
			case 'linkedin':
				const { data: linkedinData, error: linkedinError } = await supabase.auth.signInWithOAuth({
					provider: 'linkedin',
					options: {
						redirectTo: `${url.origin}/auth/callback`
					}
				});
				if (linkedinError) {
					return {
						errors: {
							email: 'Failed to sign in with LinkedIn'
							// ... other error fields
						}
					};
				}
				break;
			default:
				return {
					errors: {
						provider: 'Invalid provider'
					}
				};
		}

		if (!formData) {
			return {
				errors: {
					email: 'Invalid email'
					// ... other error fields
				}
			};
		}
		// Your existing validation logic here

		// If successful
		return {
			data: {
				// ... submitted and processed data
			}
		};
	}
};
