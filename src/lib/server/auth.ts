import { error, redirect } from '@sveltejs/kit';
import { hasAnyRole, isGlobalAdmin as checkGlobalAdmin, type RoleName, type RoleType, type UserRole } from '$lib/roles';

interface SessionData {
	session: { user: { id: string } } | null;
	user: { id: string } | null;
	roles: UserRole[];
}

/**
 * Require the user to be authenticated. Redirects to sign-in if not.
 * Returns the session data for further checks.
 */
export async function requireAuth(
	locals: App.Locals
): Promise<SessionData & { session: NonNullable<SessionData['session']>; user: NonNullable<SessionData['user']> }> {
	const { session, user, roles } = await locals.safeGetSession();

	if (!session || !user) {
		redirect(303, '/auth/signin');
	}

	return { session, user, roles };
}

/**
 * Require the user to have a specific global role.
 * Redirects to sign-in if not authenticated, throws 403 if not authorized.
 */
export async function requireGlobalAdmin(locals: App.Locals) {
	const data = await requireAuth(locals);

	if (!checkGlobalAdmin(data.roles)) {
		error(403, 'Forbidden: global admin role required');
	}

	return data;
}

/**
 * Require the user to have a specific role.
 * Redirects to sign-in if not authenticated, throws 403 if not authorized.
 */
export async function requireRole(
	locals: App.Locals,
	roleType: RoleType,
	roleName: RoleName,
	entityId?: string
) {
	const data = await requireAuth(locals);

	const hasIt = data.roles.some(
		(r) =>
			r.role_type === roleType &&
			r.role_name === roleName &&
			(entityId === undefined || r.entity_id === entityId)
	);

	if (!hasIt) {
		error(403, `Forbidden: ${roleType} ${roleName} role required`);
	}

	return data;
}

/**
 * Require the user to have a project role (owner, admin, editor, or gis).
 * Redirects to sign-in if not authenticated, throws 403 if not authorized.
 */
export async function requireProjectRole(
	locals: App.Locals,
	projectId: string,
	roleNames: RoleName[] = ['owner', 'admin', 'editor', 'gis']
) {
	const data = await requireAuth(locals);

	if (!hasAnyRole(data.roles, 'project', roleNames, projectId)) {
		error(403, 'Forbidden: insufficient project permissions');
	}

	return data;
}

/**
 * Require the user to have a community role (owner or admin).
 * Redirects to sign-in if not authenticated, throws 403 if not authorized.
 */
export async function requireCommunityRole(
	locals: App.Locals,
	communityId: string,
	roleNames: RoleName[] = ['owner', 'admin']
) {
	const data = await requireAuth(locals);

	if (!hasAnyRole(data.roles, 'community', roleNames, communityId)) {
		error(403, 'Forbidden: insufficient community permissions');
	}

	return data;
}
