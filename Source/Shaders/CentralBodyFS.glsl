//#define SHOW_TILE_BOUNDARIES
//#define SHOW_TEXTURE_BOUNDARIES

#if TEXTURE_UNITS > 0
uniform sampler2D u_dayTextures[TEXTURE_UNITS];
uniform vec4 u_dayTextureTranslationAndScale[TEXTURE_UNITS];
uniform float u_dayTextureAlpha[TEXTURE_UNITS];
uniform float u_dayTextureBrightness[TEXTURE_UNITS];
uniform float u_dayTextureContrast[TEXTURE_UNITS];
uniform float u_dayTextureOneOverGamma[TEXTURE_UNITS];
uniform vec4 u_dayTextureTexCoordsExtent[TEXTURE_UNITS];
#endif

#ifdef SHOW_REFLECTIVE_OCEAN
uniform sampler2D u_waterMask;
uniform vec4 u_waterMaskTranslationAndScale;
#endif

varying vec3 v_positionMC;
varying vec3 v_positionEC;
varying vec2 v_textureCoordinates;

vec3 sampleAndBlend(
    vec3 previousColor,
    sampler2D texture,
    vec2 tileTextureCoordinates,
    vec4 textureCoordinateExtent,
    vec4 textureCoordinateTranslationAndScale,
    float textureAlpha,
    float textureBrightness,
    float textureContrast,
    float textureOneOverGamma)
{
    // This crazy step stuff sets the alpha to 0.0 if this following condition is true:
    //    tileTextureCoordinates.s < textureCoordinateExtent.s ||
    //    tileTextureCoordinates.s > textureCoordinateExtent.p ||
    //    tileTextureCoordinates.t < textureCoordinateExtent.t ||
    //    tileTextureCoordinates.t > textureCoordinateExtent.q
    // In other words, the alpha is zero if the fragment is outside the extent
    // covered by this texture.  Would an actual 'if' yield better performance?
    vec2 alphaMultiplier = step(textureCoordinateExtent.st, tileTextureCoordinates); 
    textureAlpha = textureAlpha * alphaMultiplier.x * alphaMultiplier.y;
    
    alphaMultiplier = step(vec2(0.0), textureCoordinateExtent.pq - tileTextureCoordinates);
    textureAlpha = textureAlpha * alphaMultiplier.x * alphaMultiplier.y;
    
    vec2 translation = textureCoordinateTranslationAndScale.xy;
    vec2 scale = textureCoordinateTranslationAndScale.zw;
    vec2 textureCoordinates = tileTextureCoordinates * scale + translation;
    vec4 sample = texture2D(texture, textureCoordinates);
    vec3 color = sample.rgb;
    float alpha = sample.a;
    
    color = mix(vec3(0.0, 0.0, 0.0), color, textureBrightness);
    color = mix(vec3(0.5, 0.5, 0.5), color, textureContrast);
    
    color = pow(color, vec3(textureOneOverGamma));

#ifdef SHOW_TEXTURE_BOUNDARIES
    if (textureCoordinates.x < (1.0/256.0) || textureCoordinates.x > (255.0/256.0) ||
        textureCoordinates.y < (1.0/256.0) || textureCoordinates.y > (255.0/256.0))
    {
        color = vec3(1.0, 1.0, 0.0);
        alpha = 1.0;
    }
#endif

    return mix(previousColor, color, alpha * textureAlpha);
}

vec3 computeDayColor(vec3 initialColor, vec2 textureCoordinates);

void main()
{
    // The clamp below works around an apparent bug in Chrome Canary v23.0.1241.0
    // where the fragment shader sees textures coordinates < 0.0 and > 1.0 for the
    // fragments on the edges of tiles even though the vertex shader is outputting
    // coordinates strictly in the 0-1 range.
    vec3 initialColor = vec3(0.0, 0.0, 0.5);
    vec3 startDayColor = computeDayColor(initialColor, clamp(v_textureCoordinates, 0.0, 1.0));

#ifdef SHOW_TILE_BOUNDARIES
    if (v_textureCoordinates.x < (1.0/256.0) || v_textureCoordinates.x > (255.0/256.0) ||
        v_textureCoordinates.y < (1.0/256.0) || v_textureCoordinates.y > (255.0/256.0))
    {
        startDayColor = vec3(1.0, 0.0, 0.0);
    }
#endif

    vec4 color = vec4(startDayColor, 1.0);

#ifdef SHOW_REFLECTIVE_OCEAN
    vec2 waterMaskTranslation = u_waterMaskTranslationAndScale.xy;
    vec2 waterMaskScale = u_waterMaskTranslationAndScale.zw;
    vec2 waterMaskTextureCoordinates = v_textureCoordinates * waterMaskScale + waterMaskTranslation;

    float mask = texture2D(u_waterMask, waterMaskTextureCoordinates).r;

    if (mask > 0.0)
    {
        vec3 normalMC = normalize(czm_geodeticSurfaceNormal(v_positionMC, vec3(0.0), vec3(1.0)));   // normalized surface normal in model coordinates
        vec3 normalEC = normalize(czm_normal * normalMC);                                           // normalized surface normal in eye coordiantes
#ifdef SHOW_OCEAN_WAVES
        mat3 enuToEye = czm_eastNorthUpToEyeCoordinates(v_positionMC, normalEC);
        color = computeWaterColor(v_positionEC, czm_ellipsoidWgs84TextureCoordinates(normalMC), enuToEye, startDayColor, mask);
#else
	    czm_material material;

	    material.emission = startDayColor;
	    material.diffuse = vec3(0.1);
	    material.normal = normalEC;
	    material.specular = mix(0.0, 1.0, mask);
	    material.shininess = 10.0;

	    color = czm_phong(normalize(v_positionEC), material);
#endif
    }
#endif

    
    gl_FragColor = color;
}
