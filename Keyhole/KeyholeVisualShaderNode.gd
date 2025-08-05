@tool
class_name KeywholeShaderNode extends VisualShaderNodeCustom

func _get_category() -> String:
	return "Features/Keyhole"

func _get_global_code(_mode: Shader.Mode) -> String:
	return "
global uniform vec2 keyhole_screen_position;
global uniform vec3 keyhole_world_position;
uniform sampler2D keyhole_depth_texture : hint_depth_texture;

// Source: https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
vec3 permute(vec3 x) {return mod(((x*34.0)+1.0)*x, 289.0);}
float keyhole_snoise(vec2 v){
	const vec4 C = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
	vec2 i = floor(v + dot(v, C.yy));
	vec2 x0 = v - i + dot(i, C.xx);
	vec2 i1;
	i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec4 x12 = x0.xyxy + C.xxzz;
	x12.xy -= i1;
	i = mod(i, 289.0);
	vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
	vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
	m = m*m;
	m = m*m;
	vec3 x = 2.0 * fract(p * C.www) - 1.0;
	vec3 h = abs(x) - 0.5;
	vec3 ox = floor(x + 0.5);
	vec3 a0 = x - ox;
	m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
	vec3 g;
	g.x  = a0.x  * x0.x  + h.x  * x0.y;
	g.yz = a0.yz * x12.xz + h.yz * x12.yw;
	return 130.0 * dot(m, g);
}
	"

func _get_code(input_vars: Array[String], output_vars: Array[String], _mode: Shader.Mode, _type: VisualShader.Type) -> String:
	return "
float aspect_ratio = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
vec2 correction = vec2(aspect_ratio, 1.0);
vec2 screen_uv = FRAGCOORD.xy / VIEWPORT_SIZE.xy;

vec3 dir = normalize(keyhole_world_position - NODE_POSITION_WORLD);
vec3 forward = normalize((INV_VIEW_MATRIX * vec4(0.0, 0.0, -1.0, 0.0)).xyz);
float dot_result = dot(dir, forward);

{radius} = max(0.0, {radius} * dot_result);
float r = length((screen_uv - keyhole_screen_position / VIEWPORT_SIZE.xy) * correction);
float alpha_circle = smoothstep({radius} - 0.5 * {radius}, {radius}, r);
{radius} *= 1.0 + {edge_thickness};
float edge_circle = smoothstep({radius} - 0.5 * {radius}, {radius}, r);

vec2 time_mod = TIME * {time_modulation}.yx;

float noise = smoothstep(keyhole_snoise(SCREEN_UV * correction / (1.0 - {noise_intensity}) + time_mod) * 0.5, 1.0, 0.5);
float noise_blend = mix(1.0, noise, {noise_amount});

float edge = smoothstep(0.0, noise_blend, edge_circle);
{output_edge} = smoothstep(0.5 + (1.0 - {edge_sharpness}) / 2.0, {edge_sharpness} / 2.0, edge);

{output_alpha} = smoothstep(0.0, noise_blend, alpha_circle);
	".format({"radius": input_vars[0], "edge_thickness": input_vars[1], "edge_sharpness": input_vars[2], "noise_amount": input_vars[3], "noise_intensity": input_vars[4], "time_modulation": input_vars[5], "output_edge": output_vars[0], "output_alpha": output_vars[1]})

func _get_description() -> String:
	return "Transforms alpha and adds keyholing."

func _get_input_port_count() -> int: return 6

func _get_input_port_default_value(port: int) -> Variant:
	match port:
		0: return 0.25
		1: return 0.025
		2: return 0.25
		3: return 0.75
		4: return 0.9
		5: return Vector2(0.0, 0.1)
	return null

func _get_input_port_name(port: int) -> String:
	match port:
		0: return "Radius"
		1: return "Edge Thickness"
		2: return "Edge Sharpness"
		3: return "Noise Amount"
		4: return "Noise Intensity"
		5: return "Time Modulation"
	return ""

func _get_input_port_type(port: int) -> PortType:
	match port:
		0: return PORT_TYPE_SCALAR
		1: return PORT_TYPE_SCALAR
		2: return PORT_TYPE_SCALAR
		3: return PORT_TYPE_SCALAR
		4: return PORT_TYPE_SCALAR
		5: return PORT_TYPE_VECTOR_2D
	return PORT_TYPE_SCALAR

func _get_name() -> String: return "Keyhole"

func _get_output_port_count() -> int: return 2

func _get_output_port_name(port: int) -> String:
	match port:
		0: return "Keyhole Edge"
		1: return "Keyhole Alpha"
	return ""

func _get_output_port_type(port: int) -> PortType:
	match port:
		0: return PORT_TYPE_SCALAR
		1: return PORT_TYPE_SCALAR
	return PORT_TYPE_SCALAR

func _is_available(mode: Shader.Mode, type: VisualShader.Type) -> bool:
	return mode == Shader.MODE_SPATIAL and type == VisualShader.TYPE_FRAGMENT
