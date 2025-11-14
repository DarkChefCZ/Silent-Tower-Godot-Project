// Floor material shader - Supports dual texture blending and anti-tiling techniques
shader_type spatial;
render_mode depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;


// First texture set
uniform sampler2D texture1_albedo : source_color, filter_nearest, repeat_enable;      // Albedo map
uniform sampler2D texture1_normal : hint_normal, filter_linear_mipmap, repeat_enable;        // Normal map
uniform sampler2D texture1_roughness : hint_default_white, filter_linear_mipmap, repeat_enable; // Roughness map
uniform sampler2D texture1_ao : hint_default_white, filter_linear_mipmap, repeat_enable;     // Ambient occlusion map
uniform sampler2D texture1_height : hint_default_black, filter_linear_mipmap, repeat_enable; // Height map


// Second texture set
uniform sampler2D texture2_albedo : source_color, filter_nearest, repeat_enable;      // Albedo map
uniform sampler2D texture2_normal : hint_normal, filter_linear_mipmap, repeat_enable;        // Normal map
uniform sampler2D texture2_roughness : hint_default_white, filter_linear_mipmap, repeat_enable; // Roughness map
uniform sampler2D texture2_ao : hint_default_white, filter_linear_mipmap, repeat_enable;     // Ambient occlusion map
uniform sampler2D texture2_height : hint_default_black, filter_linear_mipmap, repeat_enable; // Height map




// Noise texture for blend control
uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable;

// Anti-tiling noise texture
uniform sampler2D tile_noise : source_color, filter_linear_mipmap, repeat_enable;


// Mathematical constants - Used for generating non-periodic noise
const float GOLDEN_RATIO = 1.618033988749;   // Golden ratio
const float SQRT2_PLUS_1 = 2.414213562373;   // √2 + 1
const float MY_E = 2.718281828459;           // Natural constant e
const float SQRT18 = 4.242640687119;         // √18
const float SQRT32 = 5.656854249492;         // √32


// Prime offsets - Used to avoid noise pattern repetition
const vec2 PRIME_OFFSET_1 = vec2(127.1, 311.7);
const vec2 PRIME_OFFSET_2 = vec2(269.5, 183.3);
const vec2 PRIME_OFFSET_3 = vec2(419.2, 371.9);
const vec2 PRIME_OFFSET_4 = vec2(73.2, 157.8);
const vec2 PRIME_OFFSET_5 = vec2(191.3, 271.9);
const vec2 PRIME_OFFSET_6 = vec2(317.5, 421.7);


// Shader configuration constants
const int MIN_VALID_TEXTURE_SIZE = 4;     // Minimum valid texture size
const float MIN_WEIGHT_THRESHOLD = 0.001; // Minimum weight threshold
const float DEFAULT_DEPTH_SCALE = 0.1;    // Default depth scale


// Basic parameters
uniform float texture_scale : hint_range(0.1, 10.0) = 1.0;   // Texture scale
uniform float noise_scale : hint_range(0.1, 5.0) = 1.0;      // Noise scale
uniform float blend_sharpness : hint_range(0.1, 5.0) = 1.0;  // Blend sharpness
uniform float uv_rotation : hint_range(0.0, 360.0) = 0.0;    // UV rotation angle
uniform float tile_offset : hint_range(0.0, 5.0) = 2.0;      // Anti-tiling offset


// Noise parameters group
group_uniforms noise_parameters;
uniform float hash_multiplier : hint_range(0.05, 0.2) = 0.1031;        // Hash multiplier
uniform float hash_offset : hint_range(20.0, 50.0) = 33.33;             // Hash offset
uniform float noise_frequency_1 : hint_range(1.0, 3.0) = 1.618;         // Noise frequency 1
uniform float noise_frequency_2 : hint_range(2.0, 4.0) = 2.414;         // Noise frequency 2
uniform float noise_frequency_3 : hint_range(3.0, 5.0) = 3.141;         // Noise frequency 3
uniform float noise_strength_1 : hint_range(0.05, 0.3) = 0.15;          // Noise strength 1
uniform float noise_strength_2 : hint_range(0.05, 0.3) = 0.12;          // Noise strength 2
uniform float noise_strength_3 : hint_range(0.05, 0.3) = 0.09;          // Noise strength 3
uniform float fbm_frequency_multiplier : hint_range(1.5, 3.0) = 2.07;   // FBM frequency multiplier
group_uniforms;


// Blending parameters group
group_uniforms blending_parameters;
uniform float blend_threshold_low : hint_range(0.0, 0.5) = 0.2;         // Blend threshold lower bound
uniform float blend_threshold_high : hint_range(0.5, 1.0) = 0.8;        // Blend threshold upper bound
uniform float smoothing_intensity_1 : hint_range(0.01, 0.1) = 0.02;     // Smoothing intensity 1
uniform float smoothing_intensity_2 : hint_range(0.01, 0.1) = 0.05;     // Smoothing intensity 2
uniform float smoothing_intensity_3 : hint_range(0.01, 0.2) = 0.1;      // Smoothing intensity 3
uniform float weight_threshold : hint_range(0.0001, 0.01) = 0.001;      // Weight threshold
uniform float weight_epsilon : hint_range(0.0001, 0.01) = 0.001;        // Weight epsilon
uniform float default_albedo : hint_range(0.0, 1.0) = 0.5;              // Default albedo
uniform float default_roughness : hint_range(0.0, 1.0) = 1.0;           // Default roughness
uniform float default_ao : hint_range(0.0, 1.0) = 1.0;                  // Default ambient occlusion
uniform float default_threshold : hint_range(0.01, 0.5) = 0.1;          // Default threshold
group_uniforms;


// Texture sampling parameters group
group_uniforms texture_sampling;
uniform int texture_size_threshold : hint_range(1, 16) = 4;              // Texture size threshold
uniform float tile_noise_scale_1 : hint_range(0.001, 0.01) = 0.003;     // Tile noise scale 1
uniform float tile_noise_scale_2 : hint_range(0.005, 0.015) = 0.007;    // Tile noise scale 2
uniform float tile_noise_scale_3 : hint_range(0.008, 0.02) = 0.011;     // Tile noise scale 3
uniform float tile_randomness_range : hint_range(8.0, 32.0) = 16.0;     // Tile randomness range
uniform float depth_scale : hint_range(0.01, 0.5) = 0.1;                // Depth scale
group_uniforms;


// Anti-tiling constants parameters group
group_uniforms anti_tiling_constants;
uniform float hash_prime_1 : hint_range(10.0, 20.0) = 12.9898;          // Hash prime 1
uniform float hash_prime_2 : hint_range(70.0, 90.0) = 78.233;           // Hash prime 2
uniform float hash_offset_1 : hint_range(40000.0, 50000.0) = 43758.5453; // Hash offset 1
uniform float hash_offset_2 : hint_range(25000.0, 35000.0) = 28001.8384; // Hash offset 2
uniform float extra_hash_prime_1 : hint_range(6.0, 10.0) = 7.13;        // Extra hash prime 1
uniform float extra_hash_prime_2 : hint_range(10.0, 15.0) = 11.17;      // Extra hash prime 2
uniform float extra_hash_offset_1 : hint_range(120.0, 140.0) = 127.1;   // Extra hash offset 1
uniform float extra_hash_offset_2 : hint_range(300.0, 320.0) = 311.7;   // Extra hash offset 2
uniform vec2 tile_sample_offset_1 = vec2(0.31, 0.47);                   // Tile sample offset 1
uniform vec2 tile_sample_offset_2 = vec2(0.73, 0.19);                   // Tile sample offset 2
uniform float blend_smoothstep_low : hint_range(0.05, 0.2) = 0.1;       // Blend smoothstep lower bound
uniform float blend_smoothstep_high : hint_range(0.8, 0.95) = 0.9;      // Blend smoothstep upper bound
uniform float blend_variation_factor : hint_range(0.1, 0.3) = 0.15;     // Blend variation factor
uniform float extra_offset_multiplier : hint_range(0.3, 0.7) = 0.5;     // Extra offset multiplier
group_uniforms;


// Domain warp parameters group
group_uniforms domain_warp;
uniform float domain_warp_freq_1 : hint_range(1.0, 2.0) = 1.3;          // Domain warp frequency 1
uniform float domain_warp_freq_2 : hint_range(1.5, 2.5) = 1.7;          // Domain warp frequency 2
uniform float domain_warp_freq_3 : hint_range(2.0, 3.0) = 2.1;          // Domain warp frequency 3
uniform float domain_warp_freq_4 : hint_range(2.0, 3.0) = 2.3;          // Domain warp frequency 4
uniform float domain_warp_freq_5 : hint_range(4.0, 6.0) = 4.7;          // Domain warp frequency 5
uniform float domain_warp_freq_6 : hint_range(4.5, 6.5) = 5.1;          // Domain warp frequency 6
uniform float domain_warp_strength_2 : hint_range(0.3, 0.8) = 0.6;      // Domain warp strength 2
uniform float domain_warp_strength_3 : hint_range(0.1, 0.5) = 0.3;      // Domain warp strength 3
group_uniforms;




// Hash function - Generate pseudo-random numbers
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * hash_multiplier);
    p3 += dot(p3, p3.yzx + hash_offset);
    return fract((p3.x + p3.y) * p3.z);
}


// Quintic interpolation function - Provides smooth transitions
float quintic(float t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}


// Value noise function - Grid-based noise generation
float noise(vec2 uv) {
    vec2 i = floor(uv);  // Grid coordinates
    vec2 f = fract(uv);  // Offset within grid
    
    // Get random values for four corners
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    // Use quintic interpolation for smoothing
    vec2 u = vec2(quintic(f.x), quintic(f.y));
    
    // Bilinear interpolation
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}


// Gradient noise function - Gradient vector-based noise generation
float gradient_noise(vec2 uv) {
    vec2 i = floor(uv);  // Grid coordinates
    vec2 f = fract(uv);  // Offset within grid
    
    // Generate gradient vectors for four corners
    vec2 g00 = normalize(vec2(hash(i) - 0.5, hash(i + vec2(0.1, 0.1)) - 0.5));
    vec2 g10 = normalize(vec2(hash(i + vec2(1.0, 0.0)) - 0.5, hash(i + vec2(1.1, 0.1)) - 0.5));
    vec2 g01 = normalize(vec2(hash(i + vec2(0.0, 1.0)) - 0.5, hash(i + vec2(0.1, 1.1)) - 0.5));
    vec2 g11 = normalize(vec2(hash(i + vec2(1.0, 1.0)) - 0.5, hash(i + vec2(1.1, 1.1)) - 0.5));
    
    // Calculate dot product of gradient and distance vectors
    float n00 = dot(g00, f);
    float n10 = dot(g10, f - vec2(1.0, 0.0));
    float n01 = dot(g01, f - vec2(0.0, 1.0));
    float n11 = dot(g11, f - vec2(1.0, 1.0));
    
    // Use quintic interpolation for smoothing
    vec2 u = vec2(quintic(f.x), quintic(f.y));
    
    return mix(mix(n00, n10, u.x), mix(n01, n11, u.x), u.y) * 0.5 + 0.5;
}


// Fractal Brownian Motion - Multi-layer noise stacking
float fbm(vec2 uv, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < octaves; i++) {
        // Blend value noise and gradient noise
        float n1 = noise(uv * frequency);
        float n2 = gradient_noise(uv * frequency + vec2(100.0, 200.0));
        value += amplitude * mix(n1, n2, 0.6);
        amplitude *= 0.5;
        frequency *= fbm_frequency_multiplier; // Use non-integer frequency multiplier to reduce periodicity
    }
    
    return value;
}


// Domain warp noise - Create complex noise patterns through multi-layer warping
float domain_warp_noise(vec2 uv, float strength) {
    // First layer warp
    vec2 warp1 = vec2(
        noise(uv * domain_warp_freq_1 + PRIME_OFFSET_1),
        noise(uv * domain_warp_freq_2 + PRIME_OFFSET_2)
    ) * strength;
    
    // Second layer warp (based on first layer)
    vec2 warp2 = vec2(
        gradient_noise(uv * domain_warp_freq_3 + warp1 + PRIME_OFFSET_3),
        gradient_noise(uv * domain_warp_freq_4 + warp1 + PRIME_OFFSET_1)
    ) * strength * domain_warp_strength_2;
    
    // Third layer warp (based on previous two layers)
    vec2 warp3 = vec2(
        noise(uv * domain_warp_freq_5 + warp1 + warp2 + PRIME_OFFSET_2),
        noise(uv * domain_warp_freq_6 + warp1 + warp2 + PRIME_OFFSET_3)
    ) * strength * domain_warp_strength_3;
    
    // Apply all warp layers to generate final noise
    return gradient_noise(uv + warp1 + warp2 + warp3);
}


// UV rotation function - Rotate UV coordinates around center point
vec2 rotate_uv(vec2 uv, float angle) {
    float rad = radians(angle);
    float cos_a = cos(rad);
    float sin_a = sin(rad);
    mat2 rotation_matrix = mat2(vec2(cos_a, -sin_a), vec2(sin_a, cos_a));
    return rotation_matrix * (uv - 0.5) + 0.5;
}


// Get varied UV coordinates - Apply scaling and rotation
vec2 get_varied_uv(vec2 base_uv, float scale_mult, float rotation_offset) {
    vec2 scaled_uv = base_uv * texture_scale * scale_mult;
    return rotate_uv(scaled_uv, uv_rotation + rotation_offset);
}


// Check if texture is valid - Avoid using invalid or placeholder textures
bool is_texture_valid(sampler2D tex) {
    // Sample texture center point
    vec4 sample_color = texture(tex, vec2(0.5, 0.5));
    
    // Check if pure white or pure black (usually placeholders)
    bool is_white = all(equal(sample_color.rgb, vec3(1.0)));
    bool is_black = all(equal(sample_color.rgb, vec3(0.0)));
    
    // Check if texture size is too small
    ivec2 tex_size = textureSize(tex, 0);
    bool is_small = tex_size.x <= texture_size_threshold && tex_size.y <= texture_size_threshold;
    
    // If texture is small and solid color, consider it invalid
    return !(is_small && (is_white || is_black));
}


// Anti-tiling texture sampling (RGB) - Eliminate texture repetition patterns
vec3 textureNoTile(sampler2D tex, vec2 uv, float v) {
    // Get random values from noise texture
    float k1 = texture(tile_noise, tile_noise_scale_1 * uv).x;
    float k2 = texture(tile_noise, tile_noise_scale_2 * uv + tile_sample_offset_1).y;
    float k3 = texture(tile_noise, tile_noise_scale_3 * uv + tile_sample_offset_2).z;
    float k = (k1 + k2 + k3) / 3.0;
    
    // Calculate UV derivatives for texture filtering
    vec2 duvdx = dFdx(uv);
    vec2 duvdy = dFdy(uv);
    
    // Generate random indices
    float l = k * tile_randomness_range;
    float f = fract(l);
    
    float ia = floor(l);
    float ib = ia + 1.0;
    
    // Calculate two random offsets
    vec2 offa = normalize(sin(vec2(ia * hash_prime_1, ia * hash_prime_2) + vec2(hash_offset_1, hash_offset_2))) * v;
    vec2 offb = normalize(sin(vec2(ib * hash_prime_1, ib * hash_prime_2) + vec2(hash_offset_1, hash_offset_2))) * v;
    
    // Add extra random offsets
    vec2 extra_offset_a = sin(vec2(ia * extra_hash_prime_1, ia * extra_hash_prime_2) + vec2(extra_hash_offset_1, extra_hash_offset_2)) * v * extra_offset_multiplier;
    vec2 extra_offset_b = sin(vec2(ib * extra_hash_prime_1, ib * extra_hash_prime_2) + vec2(extra_hash_offset_1, extra_hash_offset_2)) * v * extra_offset_multiplier;
    
    // Sample textures at two offset positions
    vec3 cola = textureGrad(tex, uv + offa + extra_offset_a, duvdx, duvdy).xyz;
    vec3 colb = textureGrad(tex, uv + offb + extra_offset_b, duvdx, duvdy).xyz;
    
    // Calculate blend factor based on color differences
    vec3 ab = cola - colb;
    float sum_ab = abs(ab.x) + abs(ab.y) + abs(ab.z);
    float blend_factor = smoothstep(blend_smoothstep_low, blend_smoothstep_high, f - blend_variation_factor * sum_ab);
    
    return mix(cola, colb, blend_factor);
}


// Anti-tiling texture sampling (single channel) - For roughness, AO and other single-channel maps
float textureNoTileSingle(sampler2D tex, vec2 uv, float v) {
    // Get random values from noise texture
    float k1 = texture(tile_noise, tile_noise_scale_1 * uv).x;
    float k2 = texture(tile_noise, tile_noise_scale_2 * uv + tile_sample_offset_1).y;
    float k3 = texture(tile_noise, tile_noise_scale_3 * uv + tile_sample_offset_2).z;
    float k = (k1 + k2 + k3) / 3.0;
    
    // Calculate UV derivatives for texture filtering
    vec2 duvdx = dFdx(uv);
    vec2 duvdy = dFdy(uv);
    
    // Generate random indices
    float l = k * tile_randomness_range;
    float f = fract(l);
    
    float ia = floor(l);
    float ib = ia + 1.0;
    
    // Calculate two random offsets
    vec2 offa = normalize(sin(vec2(ia * hash_prime_1, ia * hash_prime_2) + vec2(hash_offset_1, hash_offset_2))) * v;
    vec2 offb = normalize(sin(vec2(ib * hash_prime_1, ib * hash_prime_2) + vec2(hash_offset_1, hash_offset_2))) * v;
    
    // Add extra random offsets
    vec2 extra_offset_a = sin(vec2(ia * extra_hash_prime_1, ia * extra_hash_prime_2) + vec2(extra_hash_offset_1, extra_hash_offset_2)) * v * extra_offset_multiplier;
    vec2 extra_offset_b = sin(vec2(ib * extra_hash_prime_1, ib * extra_hash_prime_2) + vec2(extra_hash_offset_1, extra_hash_offset_2)) * v * extra_offset_multiplier;
    
    // Sample textures at two offset positions (red channel only)
    float cola = textureGrad(tex, uv + offa + extra_offset_a, duvdx, duvdy).r;
    float colb = textureGrad(tex, uv + offb + extra_offset_b, duvdx, duvdy).r;
    
    // Calculate blend factor based on value differences
    float ab = cola - colb;
    float blend_factor = smoothstep(blend_smoothstep_low, blend_smoothstep_high, f - blend_variation_factor * abs(ab));
    
    return mix(cola, colb, blend_factor);
}

// Fragment shader main function
void fragment() {
    vec2 base_uv = UV;
    
    // Generate different UV coordinates for two texture sets
    vec2 uv1 = get_varied_uv(base_uv, 1.0, 0.0);    // First texture set UV
    vec2 uv2 = get_varied_uv(base_uv, 1.3, 45.0);   // Second texture set UV (slightly larger and rotated)
    
    // Noise UV coordinates
    vec2 noise_uv = base_uv * noise_scale;
    
    // Generate multi-layer domain warp noise
    float domain_noise1 = domain_warp_noise(noise_uv * noise_frequency_1, noise_strength_1);
    float domain_noise2 = domain_warp_noise(noise_uv * noise_frequency_2 + PRIME_OFFSET_1, noise_strength_2);
    float domain_noise3 = domain_warp_noise(noise_uv * noise_frequency_3 + PRIME_OFFSET_2, noise_strength_3);
    
    // Generate detail noise layers
    float detail_noise1 = gradient_noise(noise_uv * MY_E + PRIME_OFFSET_4);
    float detail_noise2 = noise(noise_uv * SQRT18 + PRIME_OFFSET_5);
    float detail_noise3 = gradient_noise(noise_uv * SQRT32 + PRIME_OFFSET_6);
    
    // Sample from noise texture
    float noise_val = texture(noise_texture, noise_uv * GOLDEN_RATIO).r;
    
    // Combine all noise layers
    float base_noise = (domain_noise1 * 0.45 + domain_noise2 * 0.35 + domain_noise3 * 0.2);
    float detail_blend = (detail_noise1 * 0.4 + detail_noise2 * 0.35 + detail_noise3 * 0.25);
    float combined_noise = (base_noise * 0.6 + detail_blend * 0.3 + noise_val * 0.1);
    
    // Multi-layer smoothing to enhance contrast
    combined_noise = smoothstep(0.02, 0.98, combined_noise);
    combined_noise = smoothstep(0.05, 0.95, combined_noise);
    combined_noise = smoothstep(0.1, 0.9, combined_noise);
    

    // Check texture validity
    bool texture1_valid = is_texture_valid(texture1_albedo);
    bool texture2_valid = is_texture_valid(texture2_albedo);
    
    // Count valid textures
    int enabled_count = 0;
    if (texture1_valid) enabled_count++;
    if (texture2_valid) enabled_count++;
    
    // Calculate texture blend weights
    float weight1 = 0.0;
    float weight2 = 0.0;
    
    if (enabled_count == 1) {
        // When only one valid texture, use that texture
        if (texture1_valid) weight1 = 1.0;
        else if (texture2_valid) weight2 = 1.0;
    } else if (enabled_count == 2) {
        // When both textures are valid, blend based on noise
        float smooth_noise = smoothstep(0.2, 0.8, combined_noise);
        // Apply blend sharpness
        smooth_noise = pow(smooth_noise, blend_sharpness);
        
        weight1 = 1.0 - smooth_noise;
        weight2 = smooth_noise;
    }
    
    // Ensure invalid texture weights are 0
    if (!texture1_valid) weight1 = 0.0;
    if (!texture2_valid) weight2 = 0.0;
    
    // Calculate total weight
    float total_weight = weight1 + weight2;
    
    // Weight normalization
    if (total_weight <= weight_threshold) {
        weight1 = 0.0;
        weight2 = 0.0;
        total_weight = 0.0;
    } else {
        // Normalize weights
        weight1 /= total_weight;
        weight2 /= total_weight;
    }
    

    // Initialize texture sampling results
    vec4 albedo1 = vec4(0.0);
    vec4 albedo2 = vec4(0.0);
    vec3 normal1 = vec3(0.5, 0.5, 1.0);  // Default normal
    vec3 normal2 = vec3(0.5, 0.5, 1.0);
    float roughness1 = 1.0;              // Default roughness
    float roughness2 = 1.0;
    float ao1 = 1.0;                     // Default AO
    float ao2 = 1.0;
    float height1 = 0.0;                 // Default height
    float height2 = 0.0;
    
    // Sample first texture set (if valid)
    if (texture1_valid) {
        albedo1 = vec4(textureNoTile(texture1_albedo, uv1, tile_offset), texture(texture1_albedo, uv1).a);
        roughness1 = textureNoTileSingle(texture1_roughness, uv1, tile_offset);
        ao1 = textureNoTileSingle(texture1_ao, uv1, tile_offset);
        height1 = textureNoTileSingle(texture1_height, uv1, tile_offset);
    }
    
    // Sample second texture set (if valid)
    if (texture2_valid) {
        albedo2 = vec4(textureNoTile(texture2_albedo, uv2, tile_offset), texture(texture2_albedo, uv2).a);
        roughness2 = textureNoTileSingle(texture2_roughness, uv2, tile_offset);
        ao2 = textureNoTileSingle(texture2_ao, uv2, tile_offset);
        height2 = textureNoTileSingle(texture2_height, uv2, tile_offset);
    }
    

    // Blend all material properties
    vec4 final_albedo = albedo1 * weight1 + albedo2 * weight2;
    vec3 final_normal = normal1 * weight1 + normal2 * weight2;
    float final_roughness = roughness1 * weight1 + roughness2 * weight2;
    float final_ao = ao1 * weight1 + ao2 * weight2;
    float final_height = height1 * weight1 + height2 * weight2;
    
    // Output final results
    if (enabled_count == 0 || total_weight <= weight_threshold) {
        // Use default values when no valid textures
        ALBEDO = vec3(0.0, 0.0, 0.0);
        ALPHA = 0.0;
        NORMAL_MAP = vec3(0.5, 0.5, 1.0);
        ROUGHNESS = 1.0;
        AO = 1.0;
    } else {
        // Validate and correct final values
        if (length(final_normal) < 0.1) {
            final_normal = vec3(0.5, 0.5, 1.0);
        }
        if (final_ao < 0.1) {
            final_ao = 1.0;
        }
        
        // Set material outputs
        ALBEDO = final_albedo.rgb;
        ALPHA = 1.0;
        NORMAL_MAP = final_normal;
        ROUGHNESS = final_roughness;
        AO = final_ao;
    }
    
    // Set depth offset (parallax effect)
    //DEPTH = final_height * depth_scale;
}
