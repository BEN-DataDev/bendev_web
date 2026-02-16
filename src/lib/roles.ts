export type RoleType = 'project' | 'community' | 'global';

export type RoleName =
	| 'owner'
	| 'admin'
	| 'editor'
	| 'gis'
	| 'viewer'
	| 'moderator'
	| 'member'
	| 'system_admin'
	| 'system_moderator';

export interface UserRole {
	entity_id: string | null;
	role_name: RoleName;
	role_type: RoleType;
}

/**
 * Parse user roles from a Supabase JWT access token.
 * Roles are embedded in the token via the custom_access_token_hook database function.
 */
export function parseUserRolesFromJWT(accessToken: string): UserRole[] {
	if (!accessToken) {
		console.error('Access token is empty or undefined');
		return [];
	}

	try {
		const parts = accessToken.split('.');
		if (parts.length !== 3) {
			console.error('Invalid JWT format');
			return [];
		}

		const payload = JSON.parse(
			new TextDecoder().decode(
				Uint8Array.from(atob(parts[1].replace(/-/g, '+').replace(/_/g, '/')), (c) =>
					c.charCodeAt(0)
				)
			)
		);

		if (payload.user_roles && Array.isArray(payload.user_roles)) {
			return payload.user_roles.map(
				(role: { entity_id: string | null; role_name: string; role_type: string }) => ({
					entity_id: role.entity_id,
					role_name: role.role_name as RoleName,
					role_type: role.role_type as RoleType
				})
			);
		} else {
			console.warn('No user_roles found in JWT payload');
			return [];
		}
	} catch (error) {
		console.error('Error parsing JWT:', error);
		return [];
	}
}

/** Check if the user has a specific role for a given entity. */
export function hasRole(
	roles: UserRole[],
	roleType: RoleType,
	roleName: RoleName,
	entityId?: string | null
): boolean {
	return roles.some(
		(r) =>
			r.role_type === roleType &&
			r.role_name === roleName &&
			(entityId === undefined || r.entity_id === entityId)
	);
}

/** Check if the user has any of the specified roles for a given entity. */
export function hasAnyRole(
	roles: UserRole[],
	roleType: RoleType,
	roleNames: RoleName[],
	entityId?: string | null
): boolean {
	return roles.some(
		(r) =>
			r.role_type === roleType &&
			roleNames.includes(r.role_name) &&
			(entityId === undefined || r.entity_id === entityId)
	);
}

/** Check if the user can edit a project (has owner, admin, editor, or gis role). */
export function canEditProject(roles: UserRole[], projectId: string): boolean {
	return hasAnyRole(roles, 'project', ['owner', 'admin', 'editor', 'gis'], projectId);
}

/** Check if the user can admin a project (has owner or admin role). */
export function canAdminProject(roles: UserRole[], projectId: string): boolean {
	return hasAnyRole(roles, 'project', ['owner', 'admin'], projectId);
}

/** Check if the user can edit a community (has owner or admin role). */
export function canEditCommunity(roles: UserRole[], communityId: string): boolean {
	return hasAnyRole(roles, 'community', ['owner', 'admin'], communityId);
}

/** Check if the user is a global admin. */
export function isGlobalAdmin(roles: UserRole[]): boolean {
	return hasAnyRole(roles, 'global', ['system_admin', 'admin']);
}
