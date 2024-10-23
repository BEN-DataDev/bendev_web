import { redirect } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ url, locals: { supabase } }) => {
	const token_hash = url.searchParams.get('token_hash');
	const type = url.searchParams.get('type') as
		| 'signup'
		| 'invite'
		| 'recovery'
		| 'email'
		| 'magiclink'
		| null;
	const next = url.searchParams.get('next') ?? '/';

	if (token_hash && type) {
		let verifyType: 'signup' | 'invite' | 'recovery' | 'email';

		switch (type) {
			case 'signup':
			case 'invite':
			case 'recovery':
			case 'email':
				verifyType = type;
				break;
			default:
				console.error('Invalid OTP type');
				return redirect(303, '/auth/auth-error');
		}

		const { error } = await supabase.auth.verifyOtp({ token_hash, type: verifyType });
		if (error) {
			console.error('OTP verification error:', error);
			return redirect(303, '/auth/auth-error');
		}

		// For password reset, redirect to the password reset page
		if (type === 'recovery') {
			return redirect(303, '/auth/set/password');
		}

		// For signup, we need to get the user ID after verification
		if (type === 'signup' && next === '/auth/callback/redirect-to/profile') {
			const {
				data: { user }
			} = await supabase.auth.getUser();
			if (user) {
				return redirect(303, `/profile/${user.id}`);
			}
		}

		// For other types (invite), redirect to the specified next page
		return redirect(303, next);
	}

	// Handle magic link signin
	const code = url.searchParams.get('code');
	if (code) {
		const { data, error } = await supabase.auth.exchangeCodeForSession(code);
		if (error) {
			console.error('Code exchange error:', error);
			return redirect(303, '/auth/auth-code-error');
		}
		if (data.user) {
			return redirect(303, `/profile/${data.user.id}`);
		}
	}

	console.error('Unhandled authentication callback');
	return redirect(303, '/auth/auth-error');
};
