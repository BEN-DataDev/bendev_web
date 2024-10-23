import { AuthApiError } from '@supabase/supabase-js';
import { fail, redirect, type Actions } from '@sveltejs/kit';

export const actions: Actions = {
	resetPassword: async (event) => {
		const {
			request,
			locals: { supabase }
		} = event;

		const formData = await request.formData();
		const email = formData.get('email') as string;

		const { error } = await supabase.auth.resetPasswordForEmail(email, {
			redirectTo: `${event.url.origin}/auth/callback/`
		});

		if (error) {
			console.log('Password Reset Error:', error);
			if (error instanceof AuthApiError && error.status === 400) {
				return fail(400, {
					error: 'Invalid email address'
				});
			}
			return fail(500, {
				message: 'Server error. Try again later.'
			});
		}

		// Password reset email sent successfully
		return {
			success: true,
			message: 'Password reset email sent. Check your inbox.'
		};
	}
};
