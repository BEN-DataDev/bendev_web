import { createServerClient } from '@supabase/ssr';
import { type Handle, redirect } from '@sveltejs/kit';
import { sequence } from '@sveltejs/kit/hooks';

import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public';

// function parseUserRolesFromJWT(accessToken: string) {
// 	try {
// 		const payload = JSON.parse(Buffer.from(accessToken.split('.')[1], 'base64').toString());
// 		return payload.user_roles || [];
// 	} catch (error) {
// 		console.error('Error parsing JWT:', error);
// 		return [];
// 	}
// }

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

const supabase: Handle = async ({ event, resolve }) => {
	/**
	 * Creates a Supabase client specific to this server request.
	 *
	 * The Supabase client gets the Auth token from the request cookies.
	 */
	event.locals.supabase = createServerClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
		cookies: {
			getAll: () => event.cookies.getAll(),
			/**
			 * SvelteKit's cookies API requires `path` to be explicitly set in
			 * the cookie options. Setting `path` to `/` replicates previous/
			 * standard behavior.
			 */
			setAll: (cookiesToSet) => {
				cookiesToSet.forEach(({ name, value, options }) => {
					event.cookies.set(name, value, { ...options, path: '/' });
				});
			}
		}
	});

	/**
	 * Unlike `supabase.auth.getSession()`, which returns the session _without_
	 * validating the JWT, this function also calls `getUser()` to validate the
	 * JWT before returning the session.
	 */
	event.locals.safeGetSession = async () => {
		const {
			data: { session }
		} = await event.locals.supabase.auth.getSession();

		if (!session) {
			return { session: null, user: null, roles: [] };
		}

		const {
			data: { user },
			error
		} = await event.locals.supabase.auth.getUser();
		if (error) {
			// JWT validation has failed
			return { session: null, user: null, roles: [] };
		}

		const roles = parseUserRolesFromJWT(session.access_token);

		return { session, user, roles };
	};

	if ('suppressGetSessionWarning' in event.locals.supabase.auth) {
		// @ts-expect-error - suppressGetSessionWarning is not part of the official API
		event.locals.supabase.auth.suppressGetSessionWarning = true;
	} else {
		console.warn(
			'SupabaseAuthClient#suppressGetSessionWarning was removed. See https://github.com/supabase/auth-js/issues/888.'
		);
	}

	return resolve(event, {
		filterSerializedResponseHeaders(name) {
			/**
			 * Supabase libraries use the `content-range` and `x-supabase-api-version`
			 * headers, so we need to tell SvelteKit to pass it through.
			 */
			return name === 'content-range' || name === 'x-supabase-api-version';
		}
	});
};

export const handle: Handle = sequence(supabase);
