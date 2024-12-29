import h2d.Object;
import h2d.Bitmap;
import hxd.Res;

class Enemy extends GameObject {
    var speed:Float;
    var target:Player;
    private var lastDx:Float = 1;
    private var wanderTimer:Float = 0;
    private var wanderDelay:Float = 3.0;
    private var wanderTarget:{ x:Float, y:Float };
    private var worldWidth:Float;
    private var worldHeight:Float;
    public var isNeutralized:Bool = false;
    private var neutralizeTime:Float = 0;
    private var neutralizeDuration:Float = 4.0;
    private var hitCooldown:Float = 0;
    private var hitCooldownDuration:Float = 1.5;
    public var canHitPlayer:Bool = true;
    public var isInvulnerable:Bool = false;
    private var shootTimer:Float = 0;
    private var shootDelay:Float = 5.0;
    public var bulletLayer:h2d.Object;
    private var baseSpeed:Float;
    
    public function new(parent:Object, target:Player, worldWidth:Float, worldHeight:Float, ?isInvulnerable:Bool = false) {
        super(parent);
        this.target = target;
        this.worldWidth = worldWidth;
        this.worldHeight = worldHeight;
        this.isInvulnerable = isInvulnerable;
        
        var tile = if (isInvulnerable) {
            hxd.Res.assets.images.shark.invuln.toTile();
        } else {
            switch Std.random(4) {
                case 0: hxd.Res.assets.images.shark.small.toTile();
                case 1: hxd.Res.assets.images.shark.medium.toTile();
                case 2: hxd.Res.assets.images.shark.standard.toTile();
                default: hxd.Res.assets.images.shark.big.toTile();
            }
        }
        
        sprite = new Bitmap(tile, this);
        sprite.tile.setCenterRatio();
        updateRadius();
        
        speed = if (isInvulnerable) {
            90.0;
        } else {
            switch Std.random(4) {
                case 0: 250.0;
                case 1: 200.0;
                case 2: 150.0;
                default: 100.0;
            }
        }
        
        baseSpeed = speed;
        
        if (isInvulnerable) {
            shootDelay = 4.0;
        }
    }
    
    public function update(dt:Float) {
        if (isInvulnerable) {
            shootTimer -= dt;
            if (shootTimer <= 0) {
                shootTimer = shootDelay;
                shoot();
            }
            
            if (wanderTarget == null || wanderTimer <= 0) {
                wanderTarget = {
                    x: Math.random() * worldWidth,
                    y: Math.random() * worldHeight
                };
                wanderTimer = wanderDelay;
            }
            wanderTimer -= dt;
            
            var dx = wanderTarget.x - x;
            var dy = wanderTarget.y - y;
            var len = Math.sqrt(dx * dx + dy * dy);
            
            if (len > 0) {
                dx /= len;
                dy /= len;
                x += dx * speed * dt;
                y += dy * speed * dt;
                updateSpriteDirection(dx, dy);
            }
            return;
        }
        
        if (!canHitPlayer) {
            hitCooldown -= dt;
            if (hitCooldown <= 0) {
                canHitPlayer = true;
            }
            return;
        }
        
        if (isNeutralized) {
            neutralizeTime -= dt;
            if (neutralizeTime <= 0) {
                isNeutralized = false;
                sprite.filter = null;
            }
            return;
        }
        
        if (target.isHidden) {
            if (wanderTarget == null || wanderTimer <= 0) {
                wanderTarget = {
                    x: Math.random() * worldWidth,
                    y: Math.random() * worldHeight
                };
                wanderTimer = wanderDelay;
            }
            wanderTimer -= dt;
            
            var dx = wanderTarget.x - x;
            var dy = wanderTarget.y - y;
            var len = Math.sqrt(dx * dx + dy * dy);
            
            if (len > 0) {
                dx /= len;
                dy /= len;
                x += dx * speed * dt;
                y += dy * speed * dt;
                updateSpriteDirection(dx, dy);
            }
        } else {
            var dx = target.x - x;
            var dy = target.y - y;
            var len = Math.sqrt(dx * dx + dy * dy);
            
            if (len > 0) {
                dx /= len;
                dy /= len;
                
                var newX = x + dx * speed * dt;
                var newY = y + dy * speed * dt;
                
                if (len > radius) {
                    x = newX;
                    y = newY;
                    
                    if (dx != 0) {
                        lastDx = dx;
                        sprite.scaleX = dx < 0 ? 1 : -1;
                    }
                    
                    if (dx != 0 || dy != 0) {
                        if (dx == 0) {
                            var verticalRotation = dy < 0 ? -Math.PI/2 : Math.PI/2;
                            sprite.rotation = lastDx < 0 ? -verticalRotation : verticalRotation;
                            sprite.scaleX = lastDx < 0 ? 1 : -1;
                        } else {
                            sprite.rotation = Math.atan2(dy, Math.abs(dx)) * (dx < 0 ? -1 : 1);
                        }
                    }
                }
            }
        }
    }
    
    private function updateSpriteDirection(dx:Float, dy:Float) {
        if (dx != 0) {
            lastDx = dx;
            sprite.scaleX = dx < 0 ? 1 : -1;
        }
        
        if (dx != 0 || dy != 0) {
            if (dx == 0) {
                var verticalRotation = dy < 0 ? -Math.PI/2 : Math.PI/2;
                sprite.rotation = lastDx < 0 ? -verticalRotation : verticalRotation;
                sprite.scaleX = lastDx < 0 ? 1 : -1;
            } else {
                sprite.rotation = Math.atan2(dy, Math.abs(dx)) * (dx < 0 ? -1 : 1);
            }
        }
    }
    
    public function neutralize() {
        isNeutralized = true;
        neutralizeTime = neutralizeDuration;
        
        var matrix = new h3d.Matrix();
        matrix.identity();
        matrix._11 = -1;
        matrix._22 = -1;
        matrix._33 = -1;
        matrix._41 = 1;
        matrix._42 = 1;
        matrix._43 = 1;
        sprite.filter = new h2d.filter.ColorMatrix(matrix);
    }
    
    public function onHitPlayer() {
        canHitPlayer = false;
        hitCooldown = hitCooldownDuration;
    }
    
    private function shoot() {
        if (bulletLayer == null) return;
        
        var bullet = new Bitmap(Res.load("assets/images/abilities/attack_enemy.png").toTile(), bulletLayer);
        bullet.tile.setCenterRatio();
        bullet.x = x;
        bullet.y = y;
        
        var dx = target.x - x;
        var dy = target.y - y;
        var angle = Math.atan2(dy, dx);
        bullet.rotation = angle;
        
        var speed = 300.0;
        var life = 3.0;
        var radius = 20.0;
        
        var timer = new haxe.Timer(16);
        timer.run = function() {
            bullet.x += Math.cos(angle) * speed * 0.016;
            bullet.y += Math.sin(angle) * speed * 0.016;
            life -= 0.016;
            
            var dx = target.x - bullet.x;
            var dy = target.y - bullet.y;
            var dist = Math.sqrt(dx * dx + dy * dy);
            
            if (dist < radius + target.radius) {
                target.damage();
                timer.stop();
                bullet.remove();
                return;
            }
            
            if (life <= 0) {
                timer.stop();
                bullet.remove();
            }
        };
    }
    
    public function increaseSpeed(percentage:Float) {
        speed = baseSpeed * (1 + percentage);
    }
} 