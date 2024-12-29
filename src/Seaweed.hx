import h2d.Object;
import h2d.Bitmap;
import hxd.Res;

class Seaweed extends GameObject {
    private var lifetime:Float;
    private var fadeTime:Float = 2.0;
    private var isFading:Bool = false;
    private var fadeAlpha:Float = 1.0;
    
    public function new(?parent:Object) {
        super(parent);
        
        var size = Std.random(3);
        var tile = switch size {
            case 0: hxd.Res.assets.images.seaweed.small.toTile();
            case 1: hxd.Res.assets.images.seaweed.medium.toTile();
            case 2: hxd.Res.assets.images.seaweed.big.toTile();
            default: hxd.Res.assets.images.seaweed.small.toTile();
        };
        sprite = new Bitmap(tile, this);
        sprite.tile.setCenterRatio();
        updateRadius();
        
        lifetime = 10 + Math.random() * 10;
    }
    
    public function update(dt:Float) {
        if (!isFading) {
            lifetime -= dt;
            if (lifetime <= 0) {
                isFading = true;
            }
        } else {
            fadeAlpha -= dt / fadeTime;
            sprite.alpha = fadeAlpha;
            
            if (fadeAlpha <= 0) {
                remove();
            }
        }
    }
    
    public static function spawnRandom(parent:Object, worldWidth:Int, worldHeight:Int, count:Int, ?store:Array<Seaweed>) {
        for (i in 0...count) {
            var seaweed = new Seaweed(parent);
            seaweed.x = Std.random(worldWidth);
            seaweed.y = Std.random(worldHeight);
            if (store != null) store.push(seaweed);
        }
    }
}