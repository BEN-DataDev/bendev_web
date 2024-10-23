import { redirect, fail } from '@sveltejs/kit';

import { generateAvatar } from '$lib/server';
import type { Actions } from './$types';

function getInitials(firstName: string, lastName: string): string {
	return (firstName.charAt(0) + lastName.charAt(0)).toUpperCase();
}

function getAvatarColor(initials: string): string {
	let hash = 0;
	for (let i = 0; i < initials.length; i++) {
		hash = initials.charCodeAt(i) + ((hash << 5) - hash);
	}
	const hue = hash % 360;
	return `hsl(${hue}, 70%, 60%)`;
}

export const actions: Actions = {
	signup: async ({ url, request, locals: { supabase } }) => {
		const formData = await request.formData();
		// const firstName = formData.get('firstName') as string;
		// const lastName = formData.get('lastName') as string;
		const email = formData.get('email') as string;
		const password = formData.get('password') as string;
		const provider = formData.get('provider') as string;

		if (!password) {
			return fail(400, {
				success: false,
				errors: { password: 'Password is required' }
			});
		}
		switch (provider) {
			case 'email':
				const { error: signUpError } = await supabase.auth.signUp({
					email,
					password
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
					// console.log('Redirecting to GitHub URL');
					redirect(307, githubData.url);
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
