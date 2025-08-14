@tool
class_name PainterlyShaderNode extends VisualShaderNodeCustom

func _get_category() -> String:
	return "Features/Painterly"

func _get_global_code(_mode: Shader.Mode) -> String:
	return "
		vec4 painterly_triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
			vec4 samp = vec4(0.0);
			samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
			samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
			samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
			return samp;
		}

		varying vec3 painterly_vertex;
	"

func _get_func_code(_mode: Shader.Mode, type: VisualShader.Type) -> String:
	match type:
		VisualShader.Type.TYPE_VERTEX:
			return "
				painterly_vertex = VERTEX;
			"
	return ""

func _get_code(input_vars: Array[String], output_vars: Array[String], _mode: Shader.Mode, type: VisualShader.Type) -> String:
	match type:
		VisualShader.Type.TYPE_FRAGMENT:
			return "
				vec3 frag_normal = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
				vec3 painterly_triplanar_power_normal = pow(abs(frag_normal), vec3(0.5));
				painterly_triplanar_power_normal /= dot(painterly_triplanar_power_normal, vec3(1.0));
				vec3 painterly_triplanar_pos = painterly_vertex * vec3({scale}) + {offset};
				painterly_triplanar_pos *= vec3(1.0, -1.0, 1.0);

				vec3 dir = clamp({direction}, -1.0, 1.0) * -1.0;
				vec3 angle = (vec4(NORMAL, 1.0) * VIEW_MATRIX).xyz;
				float dir_blend_factor = dot(dir, angle);
				float dir_blend = mix(1.0, 0.0, dir_blend_factor);

				vec4 paint_texture = painterly_triplanar_texture({paint_map}, painterly_triplanar_power_normal, painterly_triplanar_pos);

				int coverage_channel = int(clamp({coverage_channel}, 0, 3));
				int brush_channel = int(clamp({brush_channel}, 0, 3));
				float blend = {color}.a * smoothstep(paint_texture[coverage_channel], 1.0, 1.0 - (paint_texture[brush_channel] / {coverage}));

				vec4 mixed = mix({base_color}, {color}, vec4(blend) * dir_blend);

				{out_color} = clamp(mixed, 0.0, 1.0);
				{out_roughness} = mix({base_roughness}, {roughness_affect}, clamp(blend * dir_blend, 0.0, 1.0));
			".format({
				"base_color": input_vars[0],
				"base_roughness": input_vars[1],
				"roughness_affect": input_vars[2],
				"color": input_vars[3],
				"coverage": input_vars[4],
				"paint_map": input_vars[5],
				"coverage_channel": input_vars[6],
				"brush_channel": input_vars[7],
				"direction": input_vars[8],
				"scale": input_vars[9],
				"offset": input_vars[10],
				"out_color": output_vars[0],
				"out_roughness": output_vars[1],
			})
	return ""

func _get_description() -> String:
	return "3 Layers of brushstrokes laid out using two different splats."

func _get_input_port_count() -> int: return 11

func _get_input_port_default_value(port: int) -> Variant:
	match port:
		0: return Vector4.ZERO
		1: return 0.5
		2: return 0.5
		3: return Vector4.ZERO
		4: return 1.0
		5: return null
		6: return 1
		7: return 1
		8: return Vector3.ZERO
		9: return 1.0
		10: return Vector3.ZERO
	return null

func _get_input_port_name(port: int) -> String:
	match port:
		0: return "Base Color"
		1: return "Base Roughness"
		2: return "Roughness Affect"
		3: return "Color"
		4: return "Coverage"
		5: return "Paint Map"
		6: return "Coverage Channel"
		7: return "Brush Channel"
		8: return "Direction"
		9: return "Scale"
		10: return "Offset"
	return ""

func _get_input_port_type(port: int) -> PortType:
	match port:
		0: return PORT_TYPE_VECTOR_4D
		1: return PORT_TYPE_SCALAR
		2: return PORT_TYPE_SCALAR
		3: return PORT_TYPE_VECTOR_4D
		4: return PORT_TYPE_SCALAR
		5: return PORT_TYPE_SAMPLER
		6: return PORT_TYPE_SCALAR
		7: return PORT_TYPE_SCALAR
		8: return PORT_TYPE_VECTOR_3D
		9: return PORT_TYPE_SCALAR
		10: return PORT_TYPE_VECTOR_3D
	return PORT_TYPE_SCALAR

func _get_name() -> String: return "Painterly"

func _get_output_port_count() -> int: return 2

func _get_output_port_name(port: int) -> String:
	match port:
		0: return "Color"
		1: return "Roughness"
	return ""

func _get_output_port_type(port: int) -> PortType:
	match port:
		0: return PORT_TYPE_VECTOR_4D
		1: return PORT_TYPE_SCALAR
	return PORT_TYPE_SCALAR

func _is_available(mode: Shader.Mode, type: VisualShader.Type) -> bool:
	return mode == Shader.MODE_SPATIAL and type == VisualShader.TYPE_FRAGMENT
