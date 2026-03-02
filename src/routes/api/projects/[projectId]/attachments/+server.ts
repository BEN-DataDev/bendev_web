import { json, error } from '@sveltejs/kit';
import { requireAuth } from '$lib/server/auth';
import { hasAnyRole } from '$lib/roles';
import type { RequestHandler } from './$types';

const IMAGE_BUCKET = 'project-images';
const FILE_BUCKET = 'project-attachments';

function bucketForCategory(category: string): string {
	return category === 'image' ? IMAGE_BUCKET : FILE_BUCKET;
}

export const GET: RequestHandler = async ({ params, locals }) => {
	await requireAuth(locals);
	const { projectId } = params;

	const { data, error: dbError } = await locals.supabase
		.from('project_attachments')
		.select('id, file_name, file_path, file_type, file_size, category, description, created_at')
		.eq('project_id', projectId)
		.order('created_at', { ascending: false });

	if (dbError) {
		error(500, 'Failed to load attachments.');
	}

	// Generate public URLs for images; private files get null (signed URL fetched on demand)
	const rows = (data ?? []).map((a) => ({
		...a,
		public_url:
			a.category === 'image'
				? locals.supabase.storage.from(IMAGE_BUCKET).getPublicUrl(a.file_path).data.publicUrl
				: null
	}));

	return json(rows);
};

export const POST: RequestHandler = async ({ params, locals, request }) => {
	const { roles, user } = await requireAuth(locals);
	const { projectId } = params;

	if (!hasAnyRole(roles, 'project', ['owner', 'admin', 'editor', 'gis'], projectId)) {
		error(403, 'Forbidden: insufficient project permissions.');
	}

	const formData = await request.formData();
	const file = formData.get('file') as File | null;
	const category = (formData.get('category') as string | null) ?? 'document';
	const description = (formData.get('description') as string | null) ?? null;

	if (!file || file.size === 0) {
		error(422, 'No file provided.');
	}

	const validCategories = ['document', 'image', 'report', 'data', 'other'];
	if (!validCategories.includes(category)) {
		error(422, `Invalid category. Must be one of: ${validCategories.join(', ')}`);
	}

	const bucket = bucketForCategory(category);
	const storagePath = `${projectId}/${crypto.randomUUID()}/${file.name}`;

	const { error: uploadError } = await locals.supabase.storage
		.from(bucket)
		.upload(storagePath, file, { contentType: file.type });

	if (uploadError) {
		error(500, `Storage upload failed: ${uploadError.message}`);
	}

	const { data: inserted, error: insertError } = await locals.supabase
		.from('project_attachments')
		.insert({
			project_id: projectId,
			file_name: file.name,
			file_path: storagePath,
			file_type: file.type,
			file_size: file.size,
			category,
			description: description || null,
			uploaded_by: user.id
		})
		.select('id')
		.single();

	if (insertError) {
		// Attempt storage cleanup on DB failure (best-effort)
		await locals.supabase.storage.from(bucket).remove([storagePath]);
		error(500, 'Failed to save attachment record.');
	}

	return json({ id: inserted.id }, { status: 201 });
};
