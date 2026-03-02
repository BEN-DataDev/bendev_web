import { requireAuth } from '$lib/server/auth';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	await requireAuth(locals);

	const { data: users } = await locals.supabase
		.from('userprofile')
		.select('id, firstname, lastname, bio')
		.order('firstname', { ascending: true })
		.limit(100);

	return { users: users ?? [] };
};
