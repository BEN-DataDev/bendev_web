import { redirect, fail } from '@sveltejs/kit';

import type { Actions } from './$types';

export const actions: Actions = {
	signup: async ({ url, request, locals: { supabase } }) => {
		const formData = await request.formData();
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
						redirectTo: `${url.origin}/users`
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
