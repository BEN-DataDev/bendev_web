import { error } from '@sveltejs/kit';
import { requireAuth } from '$lib/server/auth';
import { hasAnyRole } from '$lib/roles';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const { roles } = await requireAuth(locals);
	const { communityId } = params;

	const { data: rows, error: rpcError } = await locals.supabase.rpc('get_community', {
		p_id: communityId
	});

	if (rpcError || !rows || rows.length === 0) {
		error(404, 'Community not found.');
	}

	const { data: rawMembers } = await locals.supabase
		.from('communities_users')
		.select('user_id, userprofile:userprofile(firstname, lastname)')
		.eq('community_id', communityId);

	const { data: communityRoles } = await locals.supabase
		.from('user_roles')
		.select('user_id, role_name')
		.eq('role_type', 'community')
		.eq('entity_id', communityId);

	const roleByUser = Object.fromEntries(
		(communityRoles ?? []).map((r) => [r.user_id, r.role_name])
	);

	const members = (rawMembers ?? []).map((m) => {
		const profileArr = m.userprofile as { firstname: string; lastname: string }[] | null;
		const profile = Array.isArray(profileArr) ? profileArr[0] : null;
		return {
			user_id: m.user_id,
			firstname: profile?.firstname ?? '',
			lastname: profile?.lastname ?? '',
			role: roleByUser[m.user_id] ?? 'member'
		};
	});

	const canAdmin = hasAnyRole(roles, 'community', ['owner', 'admin'], communityId);

	return {
		community: rows[0],
		members,
		canAdmin
	};
};
