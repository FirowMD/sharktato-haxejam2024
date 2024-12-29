import h2d.Object;
import h2d.Bitmap;
import hxd.Res;

class Bullet extends GameObject {
    var lifeTime:Float = 2.0;
    var speed:Float = 500.0;
    var direction:Float;
    var scaleAnim:Float = 0.5;
    var targetScale:Float = 1.5;
    var scaleSpeed:Float = 0.8;
    public var piercingLeft:Int = 0;
    private var target:Enemy;
    private var hitEnemies:Array<Enemy>;
    public var game:Main;
    
    public function new(parent:Object, x:Float, y:Float, direction:Float) {
        super(parent);
        
        sprite = new Bitmap(hxd.Res.assets.images.abilities.attack.toTile(), this);
        sprite.tile.setCenterRatio();
        updateRadius();
        
        this.x = x;
        this.y = y;
        this.direction = direction;
        
        sprite.rotation = direction;
        sprite.setScale(scaleAnim);
        
        hitEnemies = [];
    }
    
    public function update(dt:Float) {
        if (target != null) {
            if (target.isNeutralized || target.parent == null) {
                setHoming(game.enemies);
            } else {
                var dx = target.x - x;
                var dy = target.y - y;
                direction = Math.atan2(dy, dx);
                sprite.rotation = direction;
            }
        }
        
        if (scaleAnim < targetScale) {
            scaleAnim += scaleSpeed * dt;
            sprite.setScale(Math.min(scaleAnim, targetScale));
        }
        
        x += Math.cos(direction) * speed * dt;
        y += Math.sin(direction) * speed * dt;
        
        lifeTime -= dt;
        if (lifeTime <= 0) {
            remove();
        }
    }
    
    public function setHoming(enemies:Array<Enemy>) {
        var closestDist = Math.POSITIVE_INFINITY;
        target = null;
        
        for (enemy in enemies) {
            if (!enemy.isNeutralized && !hasHitEnemy(enemy)) {
                var dx = enemy.x - x;
                var dy = enemy.y - y;
                var dist = dx * dx + dy * dy;
                if (dist < closestDist) {
                    closestDist = dist;
                    target = enemy;
                }
            }
        }
    }
    
    public function hasHitEnemy(enemy:Enemy):Bool {
        return hitEnemies.indexOf(enemy) != -1;
    }
    
    public function addHitEnemy(enemy:Enemy) {
        hitEnemies.push(enemy);
    }
} 