import { redirect } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ url, locals: { supabase } }) => {
	const token_hash = url.searchParams.get('token_hash');
	const type = url.searchParams.get('type');
	const redirectTo = url.searchParams.get('redirectTo');

	if (token_hash && type === 'invite') {
		const { error } = await supabase.auth.verifyOtp({
			token_hash,
			type: 'invite'
		});

		if (error) {
			console.error('Invitation verification error:', error);
			return redirect(303, '/auth/auth-invite-error');
		}
		return redirect(303, '/auth/set/password/profile');
	} else if (token_hash && type === 'signup') {
		const { error } = await supabase.auth.verifyOtp({
			token_hash,
			type
		});

		if (error) {
			console.error('Signup email confirmation error:', error);
			return redirect(303, '/auth/auth-email-error');
		}
		return redirect(302, redirectTo || '/auth/set/profile');
	}
	// Handle other authentication flows (if any)
	const code = url.searchParams.get('code');
	if (code) {
		const { error } = await supabase.auth.exchangeCodeForSession(code);
		if (error) {
			console.error('Code exchange error:', error);
			return redirect(303, '/auth/auth-code-error');
		}
		// Successful code exchange, redirect to the desired page
		console.log('Code exchanged successfully');
		return redirect(303, '/');
	}

	// If we reach here, it means we couldn't handle the request
	console.error('Unhandled authentication callback');
	return redirect(303, '/auth/auth-error');
};
