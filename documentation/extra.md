Handling cases where a user belongs to multiple roles and needs access to multiple routes requires a slightly more complex approach. Here's how you can implement this in your SvelteKit app with Supabase:

Database Structure: First, ensure your database structure supports multiple roles per user. You might have a many-to-many relationship between users and roles:
```sql
        CREATE TABLE users (
        id UUID PRIMARY KEY,
        -- other user fields...
        );

        CREATE TABLE roles (
        id SERIAL PRIMARY KEY,
        name VARCHAR(50) UNIQUE NOT NULL
        );

        CREATE TABLE user_roles (
        user_id UUID REFERENCES users(id),
        role_id INTEGER REFERENCES roles(id),
        PRIMARY KEY(user_id, role_id)
        );
```
Fetch User Roles: Modify your authentication middleware to fetch all roles associated with the user:
```ts
    // src/hooks.server.ts
    export const handleAuth: Handle = async ({ event, resolve }) => {
    const session = await getSession(event);

    if (session?.user) {
        // Fetch user details including all roles
        const { data: user, error } = await fetch(
        `${process.env.SUPABASE_URL}/rest/v1/rpc/get_user_with_roles`,
        {
            method: 'POST',
            headers: new Headers({
            apikey: process.env.SUPABASE_ANON_KEY!,
            Authorization: `Bearer ${session.access_token}`,
            }),
            body: JSON.stringify({ id: session.user.id }),
        }
        ).then((res) => res.json());

        if (error) console.error('Error fetching user:', error);
        
        event.locals.user = user;
    }

    return await resolve(event);
    };
```

Custom RPC Function: Create a custom RPC function in Supabase to fetch the user along with all their roles:
```sql
    CREATE OR REPLACE FUNCTION get_user_with_roles(p_id UUID)
    RETURNS TABLE(
    id UUID,
    email VARCHAR,
    role_names TEXT[]
    ) AS $$
    BEGIN
    RETURN QUERY
    SELECT au.id, au.email, ARRAY_AGG(cr.name ORDER BY cr.name) AS role_names
    FROM auth.users au
    LEFT JOIN user_roles ur ON au.id = ur.user_id
    LEFT JOIN roles cr ON ur.role_id = cr.id
    WHERE au.id = p_id
    GROUP BY au.id, au.email;
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER;
```
Route Protection: Modify your route protection logic to check against multiple roles:
    ```ts
    // src/routes/[route].ts
    import type { PageLoad } from './$types';
    import { handleAuth } from '$lib/server';

    export const load: PageLoad = async ({ locals }) => {
    await handleAuth({ event: { locals } });

    if (!locals.user || !hasPermission(locals.user.role_names, '[route]')) {
        throw redirect(303, '/unauthorized');
    }

    // Load protected content here
    };

    function hasPermission(userRoles: string[], route: string): boolean {
    // Check if any of the user's roles have permission for the route
    // This could involve querying a permissions table or checking against predefined rules
    }
    Permission Mapping: Instead of mapping individual routes to roles, you might want to map permissions to roles and then associate those permissions with routes. This approach scales better for complex scenarios:
    // src/lib/accessControl.js
    export const rolePermissions = {
    admin: ['view_dashboard', 'edit_settings', 'access_admin_panel'],
    editor: ['view_dashboard', 'edit_settings'],
    user: ['view_dashboard']
    };

    export const permissionRoutes = {
    view_dashboard: ['/dashboard'],
    edit_settings: ['/settings'],
    access_admin_panel: ['/admin-panel']
    };
```
Then, in your authentication middleware:

```ts
    import { rolePermissions, permissionRoutes } from '$lib/accessControl';

    export const handleAuth: Handle = async ({ event, resolve }) => {
    const session = await getSession(event);

    if (session?.user) {
        const userRoles = session.user.role_names;
        const currentPath = event.url.pathname;

        const userPermissions = new Set<string>();
        userRoles.forEach(role => {
        rolePermissions[role]?.forEach(permission => userPermissions.add(permission));
        });

        const hasPermission = Object.values(permissionRoutes).some(routes =>
        routes.includes(currentPath) && Array.from(userPermissions).includes(Object.keys(permissionRoutes).find(key => permissionRoutes[key].includes(currentPath)))
        );

        if (!hasPermission) {
        throw redirect(303, '/unauthorized');
        }
    }

    return await resolve(event);
    };
```
Admin Interface: Create an interface for managing user roles:
```ts
    // src/routes/admin/manage-user-roles.svelte
    <script lang="ts">
    import { onMount } from 'svelte';
    import { goto } from '$app/navigation';

    let users = [];
    let roles = [];

    onMount(async () => {
    const usersResponse = await fetch('/api/admin/users');
    users = await usersResponse.json();

    const rolesResponse = await fetch('/api/admin/roles');
    roles = await rolesResponse.json();
    });

    async function updateUserRoles(userId: string, selectedRoles: string[]) {
    // Implement updating user roles logic
    }
    </script>

    <h1>Manage User Roles</h1>

    {#each users as user}
    <div>
        <span>{user.username}</span>
        <select bind:value={selectedRoles[user.id]} multiple>
        {#each roles as role}
            <option value={role.id}>{role.name}</option>
        {/each}
        </select>
        <button on:click={() => updateUserRoles(user.id, selectedRoles[user.id])}>Save</button>
    </div>
    {/each}
```
By implementing these steps, you create a flexible system that can handle users with multiple roles and grant access to multiple routes accordingly. Remember to always validate permissions on the server-side for security reasons, even if you implement client-side checks for better user experience.```