import { fail } from '@sveltejs/kit';
import { generateAvatar } from '$lib/server';
import type { Actions } from './$types';

function getInitials(firstName: string, lastName: string): string {
	return (firstName.charAt(0) + lastName.charAt(0)).toUpperCase();
}

function getAvatarColor(initials: string): string {
	let hash = 0;
	for (let i = 0; i < initials.length; i++) {
		hash = initials.charCodeAt(i) + ((hash << 5) - hash);
	}
	const hue = hash % 360;
	return `hsl(${hue}, 70%, 60%)`;
}

export const actions: Actions = {
	setpasswordprofile: async ({ request, locals: { supabase } }) => {
		const formData = await request.formData();
		const firstName = formData.get('firstName') as string;
		const lastName = formData.get('lastName') as string;
		const password = formData.get('password') as string;
		const avatar = formData.get('avatar') as File | null;
		const initials = getInitials(firstName, lastName);
		const avatarColor = getAvatarColor(initials);
		let picture = '';

		let avatarFile = avatar;

		if (!avatarFile || avatarFile.size === 0) {
			avatarFile = generateAvatar(initials, avatarColor);
		}
		if (avatarFile) {
			const { data: uploadData, error: uploadError } = await supabase.storage
				.from('avatars')
				.upload(`${Date.now()}_${firstName}_${lastName}.png`, avatarFile, {
					contentType: 'image/png'
				});

			if (uploadError) {
				throw new Error(`Avatar upload failed: ${uploadError.message}`);
			}

			// Get the public URL of the uploaded file
			const {
				data: { publicUrl }
			} = supabase.storage.from('avatars').getPublicUrl(uploadData.path);

			picture = publicUrl;
		}

		if (!password) {
			return fail(400, {
				success: false,
				errors: { password: 'Password is required' }
			});
		}
		if (!firstName) {
			return fail(400, {
				success: false,
				errors: { firstName: 'First Name is required' }
			});
		}
		if (!lastName) {
			return fail(400, {
				success: false,
				errors: { firstName: 'Last Name is required' }
			});
		}
		const { error } = await supabase.auth.updateUser({
			password,
			data: { firstName: firstName, lastName: lastName, picture: picture }
		});
		if (error) {
			return fail(400, {
				success: false,
				errors: { update: error.message }
			});
		}
		return {
			success: true
		};
	}
};
