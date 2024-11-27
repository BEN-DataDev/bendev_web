<script lang="ts">
	interface Props {
		fillColour?: string;
		fillOpacity?: number;
		width?: number;
		height?: number;
		strokeColour?: string;
		strokeOpacity?: number;
		strokeWidth?: number;
	}
	let {
		fillColour = '#3388ff',
		fillOpacity = 0.9,
		width = 20,
		height = 15,
		strokeColour = '#3388ff',
		strokeOpacity = 1,
		strokeWidth = 1
	}: Props = $props();
</script>

<svg width={width + 2} height={height + 2} xmlns="http://www.w3.org/2000/svg">
	<rect
		x="1"
		y="1"
		{width}
		{height}
		fill={fillColour}
		fill-opacity={fillOpacity}
		stroke={strokeColour}
		stroke-opacity={strokeOpacity}
		stroke-width={strokeWidth}
	/>
</svg>
