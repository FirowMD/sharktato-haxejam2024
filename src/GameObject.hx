import h2d.Object;
import h2d.Bitmap;

class GameObject extends Object {
    public var radius:Float;
    public var sprite:Bitmap;
    
    public function new(parent:Object) {
        super(parent);
    }
    
    function updateRadius() {
        radius = (sprite.tile.width + sprite.tile.height) * 0.25;
    }
    
    public function checkCollision(other:GameObject):Bool {
        var dx = x - other.x;
        var dy = y - other.y;
        var distance = Math.sqrt(dx * dx + dy * dy);
        return distance < (radius + other.radius);
    }
} 