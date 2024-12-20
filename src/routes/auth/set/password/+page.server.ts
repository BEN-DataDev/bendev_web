import { fail } from '@sveltejs/kit';
import type { Actions } from './$types';

export const actions: Actions = {
	setpassword: async ({ request, locals: { supabase } }) => {
		const formData = await request.formData();
		const password = formData.get('password') as string;

		if (!password) {
			return fail(400, {
				success: false,
				errors: { password: 'Password is required' }
			});
		}

		const { error } = await supabase.auth.updateUser({ password });

		if (error) {
			return fail(400, {
				success: false,
				errors: { general: error.message }
			});
		}

		// Get the user data to determine where to redirect
		const {
			data: { user }
		} = await supabase.auth.getUser();

		return {
			success: true,
			redirectTo: user ? `/users/[${user.id}]/dashboard` : '/users'
		};
	}
};
