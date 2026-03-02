import { error } from '@sveltejs/kit';
import { requireAuth } from '$lib/server/auth';
import type { RequestHandler } from './$types';

type LayerRow = {
	id: string;
	name: string;
	geojson: GeoJSON.FeatureCollection | null;
};

function safeName(s: string): string {
	return s
		.replace(/[^\w\s-]/g, '')
		.trim()
		.replace(/\s+/g, '_');
}

export const GET: RequestHandler = async ({ params, locals, url }) => {
	await requireAuth(locals);
	const { projectId } = params;
	const layerId = url.searchParams.get('layer');

	// Verify project exists and user has access (RPC enforces RLS)
	const { data: rows, error: projectError } = await locals.supabase.rpc('get_project', {
		p_id: projectId
	});

	if (projectError || !rows || rows.length === 0) {
		error(404, 'Project not found.');
	}

	const project = rows[0] as {
		projectname: string;
		boundary: GeoJSON.Geometry | null;
		status: string | null;
		description: string | null;
	};

	const { data: layerRows } = await locals.supabase.rpc('get_project_layers', {
		p_project_id: projectId
	});

	const layers = (layerRows ?? []) as LayerRow[];

	if (layerId) {
		const layer = layers.find((l) => l.id === layerId);
		if (!layer) error(404, 'Layer not found.');

		const fc: GeoJSON.FeatureCollection = layer.geojson ?? { type: 'FeatureCollection', features: [] };
		const filename = `${safeName(layer.name) || 'layer'}.geojson`;

		return new Response(JSON.stringify(fc, null, 2), {
			headers: {
				'Content-Type': 'application/geo+json',
				'Content-Disposition': `attachment; filename="${filename}"`
			}
		});
	}

	// Full project export: boundary + all layer features
	const features: GeoJSON.Feature[] = [];

	if (project.boundary) {
		features.push({
			type: 'Feature',
			geometry: project.boundary,
			properties: {
				_type: 'project_boundary',
				name: project.projectname,
				status: project.status ?? null,
				description: project.description ?? null
			}
		});
	}

	for (const layer of layers) {
		const layerFeatures = layer.geojson?.features ?? [];
		for (const f of layerFeatures) {
			features.push({
				...f,
				properties: {
					...(f.properties ?? {}),
					_layer_name: layer.name,
					_layer_id: layer.id
				}
			});
		}
	}

	const fc: GeoJSON.FeatureCollection = { type: 'FeatureCollection', features };
	const filename = `${safeName(project.projectname) || 'project'}.geojson`;

	return new Response(JSON.stringify(fc, null, 2), {
		headers: {
			'Content-Type': 'application/geo+json',
			'Content-Disposition': `attachment; filename="${filename}"`
		}
	});
};
