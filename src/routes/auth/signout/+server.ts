import { redirect } from '@sveltejs/kit';

export const GET = async ({ locals: { supabase } }) => {
	const { error: supabaseError } = await supabase.auth.signOut();
	if (supabaseError) {
		console.error('Sign out error:', supabaseError);
		const encodedErrorMessage = encodeURIComponent(supabaseError.message || 'Unknown error');
		redirect(303, `/?signout=error&message=${encodedErrorMessage}`);
	}
	// Redirect with a success message
	redirect(303, '/?signout=success');
};
