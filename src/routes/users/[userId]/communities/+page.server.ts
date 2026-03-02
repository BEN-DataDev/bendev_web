import { requireAuth } from '$lib/server/auth';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	await requireAuth(locals);

	// Fetch IDs of communities this user belongs to
	const { data: memberships } = await locals.supabase
		.from('communities_users')
		.select('community_id')
		.eq('user_id', params.userId);

	const communityIds = (memberships ?? []).map((m) => m.community_id);

	let communities: { id: string; name: string; public: boolean }[] = [];
	if (communityIds.length > 0) {
		const { data } = await locals.supabase
			.from('community')
			.select('id, name, public')
			.in('id', communityIds)
			.order('name', { ascending: true });
		communities = data ?? [];
	}

	return { communities };
};
