import { requireAuth } from '$lib/server/auth';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	await requireAuth(locals);

	const { data: projects } = await locals.supabase
		.from('projects')
		.select(
			'id, projectname, description, status, start_date, end_date, public, created_at, community_id, community:community(name)'
		)
		.order('last_updated', { ascending: false });

	return {
		projects: projects ?? []
	};
};
