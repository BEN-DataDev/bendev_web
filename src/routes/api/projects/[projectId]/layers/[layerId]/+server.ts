import { json, error } from '@sveltejs/kit';
import { requireAuth } from '$lib/server/auth';
import { hasAnyRole } from '$lib/roles';
import type { RequestHandler } from './$types';

export const PUT: RequestHandler = async ({ params, locals, request }) => {
	const { roles } = await requireAuth(locals);
	const { projectId, layerId } = params;

	if (!hasAnyRole(roles, 'project', ['owner', 'admin', 'editor', 'gis'], projectId)) {
		error(403, 'Forbidden: insufficient project permissions.');
	}

	const body = await request.json();
	const { name, visible, display_order, style, geojson } = body as {
		name?: string | null;
		visible?: boolean | null;
		display_order?: number | null;
		style?: Record<string, unknown> | null;
		geojson?: GeoJSON.FeatureCollection | null;
	};

	const { error: rpcError } = await locals.supabase.rpc('update_project_layer', {
		p_layer_id: layerId,
		p_name: name ?? null,
		p_visible: visible ?? null,
		p_display_order: display_order ?? null,
		p_style: style ?? null,
		p_geojson_text: geojson ? JSON.stringify(geojson) : null
	});

	if (rpcError) {
		error(500, 'Failed to update layer.');
	}

	return json({ success: true });
};

export const DELETE: RequestHandler = async ({ params, locals }) => {
	const { roles } = await requireAuth(locals);
	const { projectId, layerId } = params;

	if (!hasAnyRole(roles, 'project', ['owner', 'admin', 'editor', 'gis'], projectId)) {
		error(403, 'Forbidden: insufficient project permissions.');
	}

	const { error: deleteError } = await locals.supabase
		.from('project_layers')
		.delete()
		.eq('id', layerId)
		.eq('project_id', projectId);

	if (deleteError) {
		error(500, 'Failed to delete layer.');
	}

	return new Response(null, { status: 204 });
};
