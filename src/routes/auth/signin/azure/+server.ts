import { redirect } from '@sveltejs/kit';

export const GET = async ({ locals: { supabase }, url }) => {
	const { data, error } = await supabase.auth.signInWithOAuth({
		provider: 'azure',
		options: {
			redirectTo: url.origin + '/auth/callback',
			scopes: 'email'
		}
	});

	if (error) {
		console.error('Microsoft sign-in error:', error);
		return redirect(303, '/auth/auth-error');
	}

	if (data.url) {
		return redirect(307, data.url);
	}

	return redirect(307, '/auth/auth-error');
};
