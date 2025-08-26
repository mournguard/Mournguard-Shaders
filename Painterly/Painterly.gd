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
				VERTEX = VERTEX + NORMAL * vec3(0.001);
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

				vec3 angle = (vec4(NORMAL, 1.0) * VIEW_MATRIX).xyz;
				vec3 offset = vec3(0.0);

				vec3 uv_r = painterly_vertex * vec3({scale_r}) + offset * vec3(1.0, -1.0, 1.0);
				vec4 paint_r = painterly_triplanar_texture({paint_map}, painterly_triplanar_power_normal, uv_r);
				float blend_r = smoothstep(paint_r.r, 1.0, 1.0 - (paint_r.r / {coverage_r})) * COLOR.r;
				vec3 dir_r = clamp({direction_r}, vec3(-1.0), vec3(1.0)) * -1.0;
				float dir_blend_r = mix(1.0, 0.0, dot((dir_r), angle));

				vec3 uv_g = painterly_vertex * vec3({scale_g}) + offset * vec3(1.0, -1.0, 1.0);
				vec4 paint_g = painterly_triplanar_texture({paint_map}, painterly_triplanar_power_normal, uv_g) * COLOR.g;
				float blend_g = smoothstep(paint_g.g, 1.0, 1.0 - (paint_g.g / {coverage_g}));
				vec3 dir_g = clamp({direction_g}, -1.0, 1.0) * -1.0;
				float dir_blend_g = mix(1.0, 0.0, dot((dir_g), angle));

				vec3 uv_b = painterly_vertex * vec3({scale_b}) + offset * vec3(1.0, -1.0, 1.0);
				vec4 paint_b = painterly_triplanar_texture({paint_map}, painterly_triplanar_power_normal, uv_b) * COLOR.b;
				float blend_b = smoothstep(paint_b.b, 1.0, 1.0 - (paint_b.b / {coverage_b}));
				vec3 dir_b = clamp({direction_b}, -1.0, 1.0) * -1.0;
				float dir_blend_b = mix(1.0, 0.0, dot((dir_b), angle));

				vec3 dir_blend = vec3(dir_blend_r, dir_blend_g, dir_blend_b);

				vec4 mixed = mix({base_color}, {color_r}, vec4({color_r}.a * blend_r) * dir_blend.r);
				mixed = mix(mixed, {color_g}, vec4({color_g}.a * blend_g) * dir_blend.g);
				mixed = mix(mixed, {color_b}, vec4({color_b}.a * blend_b) * dir_blend.b);

				{out_color} = clamp(mixed, 0.0, 1.0);
				{out_color}.a = blend_r;
				{out_roughness} = mix({base_roughness}, {paint_roughness}, clamp(blend_r * dir_blend.x, 0.0, 1.0));
			".format({
				"base_color": input_vars[0],
				"base_roughness": input_vars[1],
				"paint_roughness": input_vars[2],
				"color_r": input_vars[3],
				"coverage_r": input_vars[4],
				"scale_r": input_vars[5],
				"direction_r": input_vars[6],
				"color_g": input_vars[7],
				"coverage_g": input_vars[8],
				"scale_g": input_vars[9],
				"direction_g": input_vars[10],
				"color_b": input_vars[11],
				"coverage_b": input_vars[12],
				"scale_b": input_vars[13],
				"direction_b": input_vars[14],
				"paint_map": input_vars[15],
				"out_color": output_vars[0],
				"out_roughness": output_vars[1],
			})
	return ""

func _get_description() -> String:
	return "3 Layers of brushstrokes laid out using two different splats."

func _get_input_port_count() -> int: return 16

func _get_input_port_default_value(port: int) -> Variant:
	match port:
		0: return Vector4.ONE
		1: return 0.5
		2: return 0.5
		3: return Vector4.ONE
		4: return 0.0
		5: return 1.0
		6: return Vector3.ZERO
		7: return Vector4.ONE
		8: return 0.0
		9: return 1.0
		10: return Vector3.ZERO
		11: return Vector4.ONE
		12: return 0.0
		13: return 1.0
		14: return Vector3.ZERO
		15: return null
	return null

func _get_input_port_name(port: int) -> String:
	match port:
		0: return "Base Color"
		1: return "Base Roughness"
		2: return "Paint Roughness"
		3: return "Color R"
		4: return "Coverage R"
		5: return "Scale R"
		6: return "Direction R"
		7: return "Color G"
		8: return "Coverage G"
		9: return "Scale G"
		10: return "Direction G"
		11: return "Color B"
		12: return "Coverage B"
		13: return "Scale B"
		14: return "Direction B"
		15: return "Paint Map"
	return ""

func _get_input_port_type(port: int) -> PortType:
	match port:
		0: return PORT_TYPE_VECTOR_4D
		1: return PORT_TYPE_SCALAR
		2: return PORT_TYPE_SCALAR
		3: return PORT_TYPE_VECTOR_4D
		4: return PORT_TYPE_SCALAR
		5: return PORT_TYPE_SCALAR
		6: return PORT_TYPE_VECTOR_3D
		7: return PORT_TYPE_VECTOR_4D
		8: return PORT_TYPE_SCALAR
		9: return PORT_TYPE_SCALAR
		10: return PORT_TYPE_VECTOR_3D
		11: return PORT_TYPE_VECTOR_4D
		12: return PORT_TYPE_SCALAR
		13: return PORT_TYPE_SCALAR
		14: return PORT_TYPE_VECTOR_3D
		15: return PORT_TYPE_SAMPLER
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
