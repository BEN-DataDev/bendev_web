- [1. Task Description](#1-task-description)
  - [1.1. Best Practices](#11-best-practices)
- [2. Implementation](#2-implementation)
  - [2.1. Steps](#21-steps)
    - [2.1.1. Database Schema Setup](#211-database-schema-setup)
    - [2.1.2. Role-Based Access Control](#212-role-based-access-control)
    - [2.1.3. Fine-Grained Permissions](#213-fine-grained-permissions)
    - [2.1.4. Granting Permissions](#214-granting-permissions)
    - [2.1.5. Revoking Permissions](#215-revoking-permissions)
    - [2.1.6. Server-Side Checks](#216-server-side-checks)
    - [2.1.7. Client-Side Enhancements](#217-client-side-enhancements)
    - [2.1.8. Admin Dashboard](#218-admin-dashboard)
  - [2.2. Database Schema](#22-database-schema)
    - [2.2.1. Row Level Security (RLS)](#221-row-level-security-rls)
    - [2.2.2. User Roles and Permissions](#222-user-roles-and-permissions)
      - [2.2.2.1. User Roles List](#2221-user-roles-list)
      - [2.2.2.2. Create Custom Tables for Roles and Permissions](#2222-create-custom-tables-for-roles-and-permissions)
      - [2.2.2.2.1. Create Custom Table for Mapping Roles to Routes](#22221-create-custom-table-for-mapping-roles-to-routes)
      - [2.2.2.3. Custom RPC Function](#2223-custom-rpc-function)
      - [2.2.2.4. Database Trigger](#2224-database-trigger)
  - [2.3. Application Authentication](#23-application-authentication)
    - [2.3.1. Create a Supabase Client in Hooks](#231-create-a-supabase-client-in-hooks)
    - [2.3.2. Authentication Middleware](#232-authentication-middleware)
    - [2.3.3. Role-Based Access Control In Components](#233-role-based-access-control-in-components)
    - [2.3.4. Field-Level Access Control](#234-field-level-access-control)
  - [2.4. Route Protection In Application](#24-route-protection-in-application)
  - [2.5. Admin Dashboard In Application](#25-admin-dashboard-in-application)
    - [2.5.1. API Routes for Admin Functions](#251-api-routes-for-admin-functions)
  - [2.6. Summary](#26-summary)

# 1. Task Description
We will be using supabase for authentication. 
    - We don't want to change the auth.users table as this is a supabase managed schema.
    - We want to map the roles to the routes using supabase tables.
    - We want handle cases where a user belongs to multiple roles and needs access to multiple routes.
    - We want to use the `@supabase/ssr` package.
We want to be able to restrict access to certain routes to certain users and want some users with access to a route to be able to edit certain fileds in certain tables shown on that route. 
We also want some users to be 'Admin' users with all rights on all routes. 
    - We want 'Admin' users to be able to administer the access rights from the application. 
    - We want fine-grained access control within individual components based on user roles.
    - We want grant or revoke permissions for users or groups of users.
    - We want to automate the role assignment process for new users.

## 1.1. Best Practices
    Separation of concerns: Authentication, authorization, and business logic are kept separate.
    Server-side validation: Critical security checks are performed on the server.
    Client-side enhancements: UI reflects user capabilities based on their role.
    Scalability: The system can easily accommodate new roles and permissions.
    Security: All sensitive operations are gated behind proper authentication and authorization checks.

# 2. Implementation
## 2.1. Steps
### 2.1.1. Database Schema Setup
First, ensure we have a proper database schema setup for managing roles and permissions. This involves tables for roles, users, and permissions.
Use Supabase's Row Level Security feature for automatic data filtering based on user roles
Use a Supabase Trigger that fires when a new row is inserted into the auth.users table. This trigger can then insert a corresponding entry into the 'user_roles' table.

### 2.1.2. Role-Based Access Control
Implement role-based access control in the application:
    - Create custom roles (e.g., Admin, Editor, User) in the database.
    - Assign roles to users either during registration or through an admin interface.
    - Implement checks throughout the application based on user roles.

### 2.1.3. Fine-Grained Permissions
For more granular control, implement a permission system:
    - Create a permissions table in your database.
    - Define specific permissions (e.g., edit_post, delete_user).
    - Associate permissions with roles or individual users.

### 2.1.4. Granting Permissions
To grant permissions:
    - Update the user's role in the database if granting role-based permissions.
    - Add specific permissions to the user's record if granting individual permissions.
    - Ensure your authentication middleware fetches the updated role/permissions information.

### 2.1.5. Revoking Permissions
To revoke permissions:
    - Remove the user from a role or update their role to one with fewer privileges.
    - Delete specific permissions associated with the user.
    - Clear any cached permission information in your application.

### 2.1.6. Server-Side Checks
Always implement server-side checks for critical operations.

### 2.1.7. Client-Side Enhancements
While client-side checks aren't secure on their own, they can enhance the user experience.

### 2.1.8. Admin Dashboard
Create an admin interface for managing roles and permissions.

## 2.2. Database Schema
### 2.2.1. Row Level Security (RLS)
Use Supabase's Row Level Security feature for automatic data filtering based on user roles:
```sql
    CREATE POLICY select_policy ON public.users FOR SELECT USING (auth.uid() = id);
```

### 2.2.2. User Roles and Permissions
We need to establish a system for user roles and permissions:
    1. Create a roles table in Supabase to store available roles (e.g., 'User', 'Editor', 'Admin').
    2. Add a role_id column to the auth.users table to associate each user with a role.
    3. Create a permissions table to store route-level permissions for each role.

#### 2.2.2.1. User Roles List

#### 2.2.2.2. Create Custom Tables for Roles and Permissions
Instead of adding a column to the 'auth.users' table, we'll create separate tables for roles and permissions:
```sql 
    CREATE TABLE IF NOT EXISTS custom_roles (
        id SERIAL PRIMARY KEY,
        name VARCHAR(50) UNIQUE NOT NULL
    );

    INSERT INTO custom_roles (name) VALUES ('User'), ('Editor'), ('Admin');

    CREATE TABLE IF NOT EXISTS user_roles (
        id SERIAL PRIMARY KEY,
        user_id UUID REFERENCES auth.users(id),
        role_id INTEGER REFERENCES custom_roles(id),
        UNIQUE(user_id, role_id)
    );
```
#### 2.2.2.2.1. Create Custom Table for Mapping Roles to Routes
Mapping roles to routes is an important part of implementing role-based access control in our SvelteKit application. To manage these mappings dynamically we will build a dedicated table.
```sql
        CREATE TABLE route_permissions (
        id SERIAL PRIMARY KEY,
        path TEXT NOT NULL,
        role TEXT NOT NULL,
        UNIQUE(path, role)
        );

        INSERT INTO route_permissions (path, role) VALUES
        ('/dashboard', 'admin'),
        ('/dashboard', 'editor'),
        ('/settings', 'admin'),
        ('/settings', 'user'),
        ('/admin-panel', 'admin');
```

#### 2.2.2.3. Custom RPC Function
Create a custom RPC function in Supabase to fetch the user along with their role:
```sql
    CREATE OR REPLACE FUNCTION get_user_with_roles(p_id UUID)
    RETURNS TABLE(
        id UUID,
        email VARCHAR,
        role_name  TEXT[]
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

#### 2.2.2.4. Database Trigger
Create a database trigger to automatically assign a default role to new users:
```sql
    CREATE OR REPLACE FUNCTION assign_default_role()
    RETURNS TRIGGER AS $$
    BEGIN
    INSERT INTO user_roles (user_id, role_id)
    VALUES (NEW.id, (SELECT id FROM custom_roles WHERE name = 'default_role'));
    RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    DROP TRIGGER IF EXISTS assign_default_role_trigger ON auth.users;
    CREATE TRIGGER assign_default_role_trigger
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE assign_default_role();
```

## 2.3. Application Authentication

### 2.3.1. Create a Supabase Client in Hooks
Create a hook to initialize the Supabase client:
```ts
    // src/hooks.server.ts
    import { createServerSupabaseClient } from '@supabase/ssr';

    export const handle = createServerSupabaseClient({
        supabaseUrl: process.env.SUPABASE_URL,
        supabaseKey: process.env.SUPABASE_ANON_KEY,
    });

    export const getSession = handle.getSession;
```
### 2.3.2. Authentication Middleware
Create a middleware function to fetch the user's role, check authentication and set up the user object:
```ts
// src/hooks.server.ts
import { handle } from '@sveltejs/kit';
import type { Handle } from '@sveltejs/kit';

export const handle: Handle = async ({ event, resolve }) => {
    const session = await event.locals.getSession();
    
    if (session?.user) {
        // Fetch user details including role
        const { data: user, error } = await fetch(
            `${process.env.SUPABASE_URL}/rest/v1/rpc/get_user_with_role`,
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

            const userRole = session.user.role;
            const currentPath = event.url.pathname;

            const { data, error } = await supabase
            .from('route_permissions')
            .select('*')
            .eq('path', currentPath)
            .eq('role', userRole);

            if (error || !data.length) {
            throw redirect(303, '/unauthorized');
            }
        
        event.locals.user = user;
    }

    return await resolve(event);
};
```
This middleware checks for an authenticated session and fetches the user's details, including their role.

### 2.3.3. Role-Based Access Control In Components
Once we have the user's role available in event.locals.user, we can use it in your components to control access:
```ts
    <script lang="ts">
    import { page } from '$app/stores';

    let showAdminContent = false;

    $: if ($page.data && $page.data.user) {
        showAdminContent = $page.data.user.role === 'Admin';
    }
    </script>

    {#if showAdminContent}
        <div>
            <!-- Admin-only content -->
        </div>
    {/if}

    <div>
        <!-- Content visible to all authenticated users -->
    </div>
```

###  2.3.4. Field-Level Access Control
For field-level access control, you can implement this in your component logic:
```ts
<script lang="ts">
    import { page } from '$app/stores';

    let editing = false;

    $: if ($page.data && $page.data.user) {
        editing = hasFieldEditPermission($page.data.user.role.name, 'field_name');
    }

    function hasFieldEditPermission(roleName: string, fieldName: string): boolean {
        // Implement logic to check if the given role has edit permission for the field
        // This could involve querying the permissions table
    }
</script>

    {#if editing}
    <button on:click={() => editing = true}>Edit</button>
    {/if}

    <input bind:value={value} disabled={!editing} />
```
This code checks if the user has permission to edit a specific field before rendering the input field.

## 2.4. Route Protection In Application
Implement route protection using SvelteKit's load functions:
```ts
// src/routes/[route].ts
    import type { PageLoad } from './$types';

    export const load: PageLoad = async ({ locals }) => {
        if (!locals.user || !hasPermission(locals.user.role.name, '[route]')) {
            throw redirect(303, '/login');
        }

        // Load protected content here
    };

    function hasPermission(roleName: string, route: string): boolean {
        // Implement logic to check if the given role has permission for the route
        // This could involve querying the permissions table
    }
```
This code checks if the user has the necessary permissions for the route before loading the content.


## 2.5. Admin Dashboard In Application
Create an admin dashboard for managing roles and permissions:
```ts
//-- src/routes/admin/dashboard.svelte
<script lang="ts">
    import { onMount } from 'svelte';
    import { goto } from '$app/navigation';

    let roles = [];
    let permissions = [];

    onMount(async () => {
        const rolesResponse = await fetch('/api/admin/roles');
        roles = await rolesResponse.json();

        const permissionsResponse = await fetch('/api/admin/permissions');
        permissions = await permissionsResponse.json();
    });

    async function savePermissions() {
        // Implement saving permissions logic
    }

    async function addRole() {
        // Implement adding role logic
    }
</script>

    <h1>Admin Dashboard</h1>

    <h2>Roles</h2>
    <ul>
        {#each roles as role}
            <li>{role.name}</li>
        {/each}
    </ul>

    <button on:click={addRole}>Add Role</button>

    <h2>Permissions</h2>
 
    <form on:submit|preventDefault={grantPermission}>
        <input type="text" bind:value={userId} placeholder="User ID" />
        <select bind:value={permissionId}>
            {#each permissions as permission}
                <option value={permission.id}>{permission.name}</option>
            {/each}
        </select>
        <button type="submit">Grant Permission</button>
    </form>

    <form on:submit|preventDefault={revokePermission}>
        <input type="text" bind:value={userId} placeholder="User ID" />
        <select bind:value={permissionId}>
            {#each permissions as permission}
                <option value={permission.id}>{permission.name}</option>
            {/each}
        </select>
        <button type="submit">Revoke Permission</button>
    </form>
```

### 2.5.1. API Routes for Admin Functions
Create API routes to handle admin operations:
```ts
// src/routes/api/admin/[...slug].ts
    import { json } from '@sveltejs/kit';
    import type { RequestHandler } from './$types';

    export const GET = async ({ locals }) => {
        if (!locals.user || !isAdmin(locals.user.role.name)) {
            return json({ error: 'Unauthorized' }, { status: 401 });
        }

        // Handle GET requests for admin operations
    };

    export const POST = async ({ request, locals }) => {
        if (!locals.user || !isAdmin(locals.user.role.name)) {
            return json({ error: 'Unauthorized' }, { status: 401 });
        }

        // Handle POST requests for admin operations
    };

    function isAdmin(roleName: string): boolean {
        return roleName === 'Admin';
    }
```

## 2.6. Summary
  1. We've implemented a robust role-based access control system using Supabase.
  2. Authentication middleware ensures that every request has a valid user object attached.
  3. Route protection is handled at the server-side using SvelteKit's load functions.
  4. Field-level access control is implemented in the client-side components.
  5. An admin dashboard allows for centralized management of roles and permissions.
  6. API routes handle admin-specific operations securely.

 