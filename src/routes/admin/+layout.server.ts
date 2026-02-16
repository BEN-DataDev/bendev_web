import { requireGlobalAdmin } from '$lib/server/auth';
import type { LayoutServerLoad } from './$types';

export const load = (async ({ locals }) => {
	await requireGlobalAdmin(locals);
	return {};
}) satisfies LayoutServerLoad;
