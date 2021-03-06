/*global define*/
define([
        '../Core/destroyObject'
    ], function(
        destroyObject) {
    "use strict";

    /**
     * DOC_TBA
     *
     * @alias ShaderCache
     *
     * @internalConstructor
     *
     * @see Context#getShaderCache
     */
    var ShaderCache = function(context) {
        this._context = context;
        this._shaders = {};
        this._shadersToRelease = {};
    };

    /**
     * DOC_TBA
     *
     * @memberof ShaderCache
     *
     * @returns {ShaderProgram} DOC_TBA.
     */
    ShaderCache.prototype.getShaderProgram = function(vertexShaderSource, fragmentShaderSource, attributeLocations) {
        // TODO: compare attributeLocations!
        var keyword = vertexShaderSource + fragmentShaderSource;
        var cachedShader;

        if (this._shaders[keyword]) {
            cachedShader = this._shaders[keyword];
        } else {
            var sp = this._context.createShaderProgram(vertexShaderSource, fragmentShaderSource, attributeLocations);

            cachedShader = {
                cache : this,
                shaderProgram : sp,
                keyword : keyword,
                count : 0
            };

            // A shader can't be in more than one cache.
            sp._cachedShader = cachedShader;
            this._shaders[keyword] = cachedShader;
        }

        ++cachedShader.count;
        return cachedShader.shaderProgram;
    };

    /**
     * DOC_TBA
     * @memberof ShaderCache
     */
    ShaderCache.prototype.destroyReleasedShaderPrograms = function() {
        var shadersToRelease = this._shadersToRelease;

        for ( var keyword in shadersToRelease) {
            if (shadersToRelease.hasOwnProperty(keyword)) {
                // Check the count again here because the shader may have been requested
                // after it was released, in which case, we are avoiding thrashing the cache.
                var cachedShader = shadersToRelease[keyword];
                if (cachedShader.count === 0) {
                    delete this._shaders[cachedShader.keyword];
                    cachedShader.shaderProgram.destroy();
                }
            }
        }

        this._shadersToRelease = {};
    };

    /**
     * DOC_TBA
     *
     * @memberof ShaderCache
     *
     * @parameter {ShaderProgram} shaderProgram DOC_TBA.
     */
    ShaderCache.prototype.releaseShaderProgram = function(shaderProgram) {
        if (shaderProgram) {
            var cachedShader = shaderProgram._cachedShader;
            if (cachedShader && (--cachedShader.count === 0)) {
                this._shadersToRelease[cachedShader.keyword] = cachedShader;
            }
        }

        return null;
    };

    /**
     * DOC_TBA
     * @memberof ShaderCache
     */
    ShaderCache.prototype.isDestroyed = function() {
        return false;
    };

    /**
     * DOC_TBA
     * @memberof ShaderCache
     */
    ShaderCache.prototype.destroy = function() {
        var shaders = this._shaders;

        for ( var keyword in shaders) {
            if (shaders.hasOwnProperty(keyword)) {
                shaders[keyword].shaderProgram.destroy();
            }
        }

        return destroyObject(this);
    };

    return ShaderCache;
});