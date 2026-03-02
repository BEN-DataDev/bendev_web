import { requireAuth } from '$lib/server/auth';
import { error } from '@sveltejs/kit';
import { hasAnyRole } from '$lib/roles';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
	const { user, roles } = await requireAuth(locals);
	const { projectId } = params;

	const { data: rows, error: rpcError } = await locals.supabase.rpc('get_project', {
		p_id: projectId
	});

	if (rpcError || !rows || rows.length === 0) {
		error(404, 'Project not found or access denied.');
	}

	const project = rows[0];

	const { data: layers } = await locals.supabase.rpc('get_project_layers', {
		p_project_id: projectId
	});

	const { data: members } = await locals.supabase
		.from('projects_users')
		.select('user_id, userprofile:userprofile(firstname, lastname)')
		.eq('project_id', projectId);

	const userProjectRole =
		roles.find((r) => r.role_type === 'project' && r.entity_id === projectId)?.role_name ?? null;

	const canEdit = hasAnyRole(roles, 'project', ['owner', 'admin', 'editor', 'gis'], projectId);
	const canAdmin = hasAnyRole(roles, 'project', ['owner', 'admin'], projectId);

	return {
		project,
		layers: layers ?? [],
		members: members ?? [],
		userId: user.id,
		userProjectRole,
		canEdit,
		canAdmin
	};
};
