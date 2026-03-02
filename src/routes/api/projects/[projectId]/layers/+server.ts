import { json, error } from '@sveltejs/kit';
import { requireAuth } from '$lib/server/auth';
import { hasAnyRole } from '$lib/roles';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ params, locals }) => {
	await requireAuth(locals);
	const { projectId } = params;

	const { data, error: rpcError } = await locals.supabase.rpc('get_project_layers', {
		p_project_id: projectId
	});

	if (rpcError) {
		error(500, 'Failed to load layers.');
	}

	return json(data ?? []);
};

export const POST: RequestHandler = async ({ params, locals, request }) => {
	const { roles } = await requireAuth(locals);
	const { projectId } = params;

	if (!hasAnyRole(roles, 'project', ['owner', 'admin', 'editor', 'gis'], projectId)) {
		error(403, 'Forbidden: insufficient project permissions.');
	}

	const body = await request.json();
	const { name, layer_type, geojson, style, source_url, description } = body as {
		name: string;
		layer_type: string;
		geojson?: GeoJSON.FeatureCollection | null;
		style?: Record<string, unknown> | null;
		source_url?: string | null;
		description?: string | null;
	};

	if (!name || !layer_type) {
		error(422, 'Missing required fields: name, layer_type.');
	}

	const { data: layerId, error: rpcError } = await locals.supabase.rpc('create_project_layer', {
		p_project_id: projectId,
		p_name: name,
		p_layer_type: layer_type,
		p_geojson_text: geojson ? JSON.stringify(geojson) : null,
		p_style: style ?? null,
		p_source_url: source_url ?? null,
		p_description: description ?? null
	});

	if (rpcError) {
		error(500, 'Failed to create layer.');
	}

	return json({ id: layerId }, { status: 201 });
};
