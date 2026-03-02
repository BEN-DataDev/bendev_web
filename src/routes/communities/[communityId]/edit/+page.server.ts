import { requireCommunityRole } from '$lib/server/auth';
import { redirect, fail, error } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	await requireCommunityRole(locals, params.communityId, ['owner', 'admin']);

	const { data: rows, error: rpcError } = await locals.supabase.rpc('get_community', {
		p_id: params.communityId
	});

	if (rpcError || !rows || rows.length === 0) {
		error(404, 'Community not found.');
	}

	return { community: rows[0] };
};

export const actions: Actions = {
	default: async ({ request, params, locals }) => {
		await requireCommunityRole(locals, params.communityId, ['owner', 'admin']);

		const formData = await request.formData();
		const name = (formData.get('name') as string)?.trim();
		const isPublic = formData.get('public') === 'on';
		const extentGeojson = (formData.get('extent_geojson') as string)?.trim() || null;

		if (!name) return fail(422, { error: 'Community name is required.' });

		const { data: updated, error: rpcError } = await locals.supabase.rpc('update_community', {
			p_id: params.communityId,
			p_name: name,
			p_extent_geojson: extentGeojson,
			p_public: isPublic
		});

		if (rpcError || !updated) {
			console.error('update_community rpc error:', rpcError);
			return fail(500, { error: 'Failed to update community. Please try again.' });
		}

		redirect(303, `/communities/${params.communityId}`);
	}
};
