import { json, error } from '@sveltejs/kit';
import { requireAuth } from '$lib/server/auth';
import { hasAnyRole } from '$lib/roles';
import type { RequestHandler } from './$types';

const IMAGE_BUCKET = 'project-images';
const FILE_BUCKET = 'project-attachments';

/** GET — return a signed download URL for private attachments (1-hour expiry). */
export const GET: RequestHandler = async ({ params, locals }) => {
	await requireAuth(locals);
	const { projectId, attachmentId } = params;

	const { data: attachment, error: dbError } = await locals.supabase
		.from('project_attachments')
		.select('id, file_path, file_type, category')
		.eq('id', attachmentId)
		.eq('project_id', projectId)
		.single();

	if (dbError || !attachment) {
		error(404, 'Attachment not found.');
	}

	if (attachment.category === 'image') {
		const { data } = locals.supabase.storage.from(IMAGE_BUCKET).getPublicUrl(attachment.file_path);
		return json({ url: data.publicUrl });
	}

	const { data: signed, error: signError } = await locals.supabase.storage
		.from(FILE_BUCKET)
		.createSignedUrl(attachment.file_path, 3600);

	if (signError || !signed) {
		error(500, 'Failed to generate download link.');
	}

	return json({ url: signed.signedUrl });
};

/** DELETE — remove from storage and from the DB. */
export const DELETE: RequestHandler = async ({ params, locals }) => {
	const { roles } = await requireAuth(locals);
	const { projectId, attachmentId } = params;

	if (!hasAnyRole(roles, 'project', ['owner', 'admin', 'editor', 'gis'], projectId)) {
		error(403, 'Forbidden: insufficient project permissions.');
	}

	const { data: attachment, error: fetchError } = await locals.supabase
		.from('project_attachments')
		.select('id, file_path, category')
		.eq('id', attachmentId)
		.eq('project_id', projectId)
		.single();

	if (fetchError || !attachment) {
		error(404, 'Attachment not found.');
	}

	const bucket = attachment.category === 'image' ? IMAGE_BUCKET : FILE_BUCKET;

	await locals.supabase.storage.from(bucket).remove([attachment.file_path]);

	const { error: deleteError } = await locals.supabase
		.from('project_attachments')
		.delete()
		.eq('id', attachmentId)
		.eq('project_id', projectId);

	if (deleteError) {
		error(500, 'Failed to delete attachment record.');
	}

	return new Response(null, { status: 204 });
};
