import { requireAuth } from '$lib/server/auth';
import { redirect, fail } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	await requireAuth(locals);

	const { data: communities } = await locals.supabase
		.from('community')
		.select('id, name')
		.order('name');

	return {
		communities: communities ?? []
	};
};

export const actions: Actions = {
	default: async ({ request, locals }) => {
		await requireAuth(locals);

		const formData = await request.formData();
		const name = (formData.get('name') as string)?.trim();
		const description = (formData.get('description') as string)?.trim() || null;
		const status = (formData.get('status') as string) || 'draft';
		const start_date = (formData.get('start_date') as string) || null;
		const end_date = (formData.get('end_date') as string) || null;
		const community_id = (formData.get('community_id') as string) || null;
		const isPublic = formData.get('public') === 'on';
		const boundaryGeojson = (formData.get('geometry_geojson') as string)?.trim() || null;

		if (!name) {
			return fail(422, { error: 'Project name is required.' });
		}
		if (!community_id) {
			return fail(422, { error: 'A community is required.' });
		}

		const { data: projectId, error: rpcError } = await locals.supabase.rpc('create_project', {
			p_name: name,
			p_description: description,
			p_status: status,
			p_start_date: start_date ?? undefined,
			p_end_date: end_date ?? undefined,
			p_community_id: community_id,
			p_public: isPublic,
			p_boundary_geojson: boundaryGeojson
		});

		if (rpcError || !projectId) {
			console.error('create_project rpc error:', rpcError);
			return fail(500, { error: 'Failed to create project. Please try again.' });
		}

		redirect(303, `/projects/${projectId}`);
	}
};
