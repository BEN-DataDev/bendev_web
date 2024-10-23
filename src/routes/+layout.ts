import { createBrowserClient, createServerClient, isBrowser } from '@supabase/ssr';
import { PUBLIC_SUPABASE_ANON_KEY, PUBLIC_SUPABASE_URL } from '$env/static/public';
import type { LayoutLoad } from './$types';

function parseUserRolesFromJWT(accessToken: string) {
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

		// Decode the payload (second part of the token)
		const payload = JSON.parse(
			decodeURIComponent(escape(atob(parts[1].replace(/-/g, '+').replace(/_/g, '/'))))
		);

		// Check if user_roles exists in the payload
		if (payload.user_roles && Array.isArray(payload.user_roles)) {
			return payload.user_roles.map((role: { entity_id: any; role_name: any; role_type: any }) => ({
				entity_id: role.entity_id,
				role_name: role.role_name,
				role_type: role.role_type
			}));
		} else {
			console.warn('No user_roles found in JWT payload');
			return [];
		}
	} catch (error) {
		console.error('Error parsing JWT:', error);
		return [];
	}
}

export const load: LayoutLoad = async ({ data, depends, fetch }) => {
	/**
	 * Declare a dependency so the layout can be invalidated, for example, on
	 * session refresh.
	 */
	depends('supabase:auth');
	depends('app:root');

	const supabase = isBrowser()
		? createBrowserClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
				global: {
					fetch
				}
			})
		: createServerClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
				global: {
					fetch
				},
				cookies: {
					getAll() {
						return data.cookies;
					}
				}
			});

	/**
	 * It's fine to use `getSession` here, because on the client, `getSession` is
	 * safe, and on the server, it reads `session` from the `LayoutData`, which
	 * safely checked the session using `safeGetSession`.
	 */
	const {
		data: { session }
	} = await supabase.auth.getSession();

	const {
		data: { user }
	} = await supabase.auth.getUser();

	let roles = [];
	if (session?.access_token) {
		roles = parseUserRolesFromJWT(session.access_token);
	} else {
		console.warn('No access token found in session');
	}

	return { session, supabase, user, roles };
};
