import { redirect } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ locals: { supabase, safeGetSession } }) => {
	const session = await safeGetSession();

	if (!session) {
		return redirect(303, '/auth/signin');
	}

	const {
		data: { user }
	} = await supabase.auth.getUser();

	if (user) {
		return redirect(303, `/users/[${user.id}]/dashboard`);
	} else {
		return redirect(303, '/auth/auth-verify-error');
	}
};
