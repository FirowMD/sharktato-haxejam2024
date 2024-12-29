class CyberpunkShader extends h3d.shader.ScreenShader {
    static var SRC = {
        @param var texture : Sampler2D;
        @param var time : Float;
        
        function fragment() {
            var uv = input.uv;
            var color = texture.get(uv);
            
            var redShift = vec2(cos(time) * 0.005, sin(time) * 0.005);
            var blueShift = vec2(sin(time) * 0.005, cos(time) * 0.005);
            
            var red = texture.get(uv + redShift).r;
            var green = color.g;
            var blue = texture.get(uv + blueShift).b;
            
            var glow = sin(time * 2.0) * 0.05 + 0.1;
            
            var isBackground = (color.r + color.g + color.b) > 2.0;
            
            if (isBackground) {
                output.color = color;
            } else {
                output.color = vec4(
                    red + glow,
                    green + glow * 0.7,
                    blue + glow,
                    color.a
                );
            }
        }
    };
} 