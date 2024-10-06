export function generateAvatar(initials: string, avatarColor: string): File {
	const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
      <circle cx="50" cy="50" r="50" fill="${avatarColor}" />
      <text x="50" y="50" font-family="Arial" font-size="36" font-weight="bold" fill="white" text-anchor="middle" dominant-baseline="central">
        ${initials}
      </text>
    </svg>
  `;

	const buffer = Buffer.from(svg);
	return new File([buffer], 'avatar.svg', { type: 'image/svg+xml' });
}
