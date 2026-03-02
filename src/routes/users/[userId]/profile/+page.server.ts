import { requireAuth } from '$lib/server/auth';
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	await requireAuth(locals);

	const { data: profile, error: dbError } = await locals.supabase
		.from('userprofile')
		.select('id, firstname, lastname, bio, avatar_path')
		.eq('id', params.userId)
		.single();

	if (dbError || !profile) {
		error(404, 'User not found.');
	}

	return { profile };
};
