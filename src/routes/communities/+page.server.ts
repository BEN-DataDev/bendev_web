// TODO Load list of communities (with pagination)
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
	const supabase = locals.supabase;

	const { data: communities } = await supabase.rpc('get_communities_with_transformed_extent');

	return {
		communities: communities || []
	};
};
