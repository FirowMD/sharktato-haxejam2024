import h2d.Object;
import h2d.Bitmap;
import hxd.Res;

class Treasure extends GameObject {
    public var effect:TreasureEffect;
    
    public function new(parent:Object) {
        super(parent);
        sprite = new Bitmap(hxd.Res.assets.images.treasure.toTile(), this);
        sprite.tile.setCenterRatio();
        updateRadius();
        
        if (!hasFirstTreasureSpawned) {
            effect = TreasureEffect.HomingBullets;
            hasFirstTreasureSpawned = true;
        } else {
            effect = switch(Std.random(4)) {
                case 0: TreasureEffect.CooldownReduction;
                case 1: TreasureEffect.ShieldInstance;
                case 2: TreasureEffect.SpeedBonus;
                case 3: TreasureEffect.PiercingBullets;
                default: TreasureEffect.CooldownReduction;
            };
        }
    }
    
    private static var hasFirstTreasureSpawned:Bool = false;
    
    public static function resetState() {
        hasFirstTreasureSpawned = false;
    }
}

enum TreasureEffect {
    CooldownReduction;
    ShieldInstance;
    SpeedBonus;
    HomingBullets;
    PiercingBullets;
} 