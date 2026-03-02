import { requireCommunityRole } from '$lib/server/auth';
import { fail, error } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const { user } = await requireCommunityRole(locals, params.communityId, ['owner', 'admin']);
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

	return {
		community: rows[0],
		members,
		currentUserId: user.id
	};
};

export const actions: Actions = {
	remove: async ({ request, params, locals }) => {
		await requireCommunityRole(locals, params.communityId, ['owner', 'admin']);
		const { communityId } = params;

		const formData = await request.formData();
		const userId = formData.get('user_id') as string;

		if (!userId) return fail(422, { error: 'Missing user_id.' });

		// Prevent removing the last owner
		const { data: owners } = await locals.supabase
			.from('user_roles')
			.select('user_id')
			.eq('role_type', 'community')
			.eq('entity_id', communityId)
			.eq('role_name', 'owner');

		if (owners && owners.length === 1 && owners[0].user_id === userId) {
			return fail(422, { error: 'Cannot remove the only community owner.' });
		}

		await locals.supabase
			.from('user_roles')
			.delete()
			.eq('user_id', userId)
			.eq('role_type', 'community')
			.eq('entity_id', communityId);

		const { error: deleteError } = await locals.supabase
			.from('communities_users')
			.delete()
			.eq('community_id', communityId)
			.eq('user_id', userId);

		if (deleteError) {
			return fail(500, { error: 'Failed to remove member.' });
		}

		return { success: true };
	},

	changeRole: async ({ request, params, locals }) => {
		await requireCommunityRole(locals, params.communityId, ['owner', 'admin']);
		const { communityId } = params;

		const formData = await request.formData();
		const userId = formData.get('user_id') as string;
		const newRole = formData.get('role') as string;

		const validRoles = ['owner', 'admin', 'member'];
		if (!userId || !validRoles.includes(newRole)) {
			return fail(422, { error: 'Invalid request.' });
		}

		const { error: updateError } = await locals.supabase
			.from('user_roles')
			.update({ role_name: newRole as 'owner' | 'admin' | 'member' })
			.eq('user_id', userId)
			.eq('role_type', 'community')
			.eq('entity_id', communityId);

		if (updateError) {
			return fail(500, { error: 'Failed to update role.' });
		}

		return { success: true };
	}
};
