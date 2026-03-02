import { requireAuth } from '$lib/server/auth';
import { redirect, fail } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	await requireAuth(locals);
	return {};
};

export const actions: Actions = {
	default: async ({ request, locals }) => {
		await requireAuth(locals);

		const formData = await request.formData();
		const name = (formData.get('name') as string)?.trim();
		const isPublic = formData.get('public') === 'on';
		const extentGeojson = (formData.get('extent_geojson') as string)?.trim() || null;

		if (!name) {
			return fail(422, { error: 'Community name is required.' });
		}
		if (!extentGeojson) {
			return fail(422, { error: 'Please draw the community boundary on the map.' });
		}

		const { data: communityId, error: rpcError } = await locals.supabase.rpc(
			'create_community',
			{
				p_name: name,
				p_extent_geojson: extentGeojson,
				p_public: isPublic
			}
		);

		if (rpcError || !communityId) {
			console.error('create_community rpc error:', rpcError);
			return fail(500, { error: 'Failed to create community. Please try again.' });
		}

		redirect(303, `/communities/${communityId}`);
	}
};
