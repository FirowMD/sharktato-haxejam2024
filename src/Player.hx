import h2d.Object;
import h2d.Bitmap;
import hxd.Key;
import hxd.Res;
import Treasure.TreasureEffect;

class Player extends GameObject {
    public var speed:Float = 300.0;
    private var lastDx:Float = 1;
    public var worldWidth:Float;
    public var worldHeight:Float;
    private var shootCooldown:Float = 0;
    private var shootDelay:Float = 2.0;
    var game:Main;
    public var bulletLayer:h2d.Object;
    public var isHidden:Bool = false;
    private var hp:Int = 1;
    private var shieldActive:Bool = true;
    private var shieldSprite:Bitmap;
    private var shieldCooldown:Float = 0;
    private var shieldCooldownMax:Float = 9.0;
    private var targetX:Float = -1;
    private var targetY:Float = -1;
    private var moveSpeed:Float = 300.0;
    public var cooldownReduction:Int = 0;
    public var hasInvulnerability:Bool = false;
    public var invulnerabilityTimer:Float = 0;
    public var speedBonusCount:Int = 0;
    public var hasHomingBullets:Bool = false;
    public var piercingCount:Int = 0;
    private var treasureArrow:Bitmap;
    private var shieldInstances:Int = 1;
    private var maxShieldInstances:Int = 1;
    private var shieldRecharging:Bool = false;
    
    public function new(?parent:Object, worldWidth:Float, worldHeight:Float, game:Main) {
        super(parent);
        this.worldWidth = worldWidth;
        this.worldHeight = worldHeight;
        this.game = game;
        
        sprite = new Bitmap(hxd.Res.assets.images.player.toTile(), this);
        sprite.tile.setCenterRatio();
        updateRadius();
        
        sprite.scaleX = 1;
        sprite.scaleY = 1;
        
        shieldSprite = new Bitmap(hxd.Res.assets.images.abilities.shield.toTile(), this);
        shieldSprite.tile.setCenterRatio();
        
        shieldInstances = 1;
        maxShieldInstances = 1;
        shieldActive = true;
        shieldSprite.visible = true;
        
        shieldSprite.x = 0;
        shieldSprite.y = 0;
        
        treasureArrow = new Bitmap(hxd.Res.assets.images.treasure_arrow.toTile(), this);
        treasureArrow.tile.setCenterRatio();
        treasureArrow.visible = false;
        treasureArrow.setScale(0.7);
    }
    
    public function update(dt:Float) {
        var dx = 0.0;
        var dy = 0.0;
        
        if (Key.isDown(Key.W) || Key.isDown(Key.UP))    dy -= 1;
        if (Key.isDown(Key.S) || Key.isDown(Key.DOWN))  dy += 1;
        if (Key.isDown(Key.A) || Key.isDown(Key.LEFT))  dx -= 1;
        if (Key.isDown(Key.D) || Key.isDown(Key.RIGHT)) dx += 1;
        

        
        if (dx != 0 || dy != 0) {
            if (dx != 0 && dy != 0) {
                var len = Math.sqrt(dx * dx + dy * dy);
                dx /= len;
                dy /= len;
            }
            
            var newX = x + dx * moveSpeed * dt;
            var newY = y + dy * moveSpeed * dt;
            
            x = Math.max(0, Math.min(newX, worldWidth));
            y = Math.max(0, Math.min(newY, worldHeight));
            
            updateSpriteDirection(dx, dy);
        }
        else if (targetX >= 0 && targetY >= 0) {
            dx = targetX - x;
            dy = targetY - y;
            var len = Math.sqrt(dx * dx + dy * dy);
            
            if (len > 5) {
                dx /= len;
                dy /= len;
                
                var newX = x + dx * moveSpeed * dt;
                var newY = y + dy * moveSpeed * dt;
                
                x = Math.max(0, Math.min(newX, worldWidth));
                y = Math.max(0, Math.min(newY, worldHeight));
                
                updateSpriteDirection(dx, dy);
            } else {
                targetX = -1;
                targetY = -1;
            }
        }
        
        shootCooldown -= dt;
        
        if (shootCooldown <= 0) {
            var bulletDirection = sprite.rotation + Math.PI;
            if (sprite.scaleX < 0) {
                bulletDirection = Math.PI + bulletDirection;
            }
            var bullet = new Bullet(bulletLayer, x, y, bulletDirection);
            bullet.game = game;
            bullet.piercingLeft = piercingCount;
            if (hasHomingBullets) {
                bullet.setHoming(game.enemies);
            }
            game.bullets.push(bullet);
            shootCooldown = shootDelay;
            
            var shootSound = hxd.Res.assets.sounds.shark_shoot;
            shootSound.play();
        }
        
        if (shieldSprite != null) {
            shieldSprite.rotation = sprite.rotation;
            shieldSprite.scaleX = sprite.scaleX;
            shieldSprite.scaleY = 1;
        }
        
        if (shieldInstances < maxShieldInstances && shieldCooldown > 0) {
            shieldCooldown -= dt;
            if (shieldCooldown <= 0) {
                shieldInstances++;
                shieldActive = true;
                shieldSprite.visible = true;
                
                if (shieldInstances < maxShieldInstances) {
                    shieldCooldown = shieldCooldownMax;
                }
                
                game.updateScoreDisplay();
            }
        }
        
        if (hasInvulnerability) {
            invulnerabilityTimer += dt;
            if (invulnerabilityTimer >= 10) {
                invulnerabilityTimer = 0;
                shieldActive = true;
                shieldSprite.visible = true;
                applyInvertColors();
            }
        }
        
        if (!shieldActive && hasInvulnerability) {
            removeInvertColors();
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
    
    public function checkSeaweedHiding(seaweeds:Array<Seaweed>) {
        isHidden = false;
        for (seaweed in seaweeds) {
            if (checkCollision(seaweed)) {
                isHidden = true;
                break;
            }
        }
    }
    
    public function damage(amount:Int = 1) {
        var hitSound = hxd.Res.assets.sounds.shark_hit;
        hitSound.play();
        
        if (shieldInstances > 0) {
            shieldInstances--;
            
            shieldCooldown = shieldCooldownMax;
            
            if (shieldInstances <= 0) {
                shieldActive = false;
                shieldSprite.visible = false;
            }
            
            game.updateScoreDisplay();
            return;
        }
        
        hp -= amount;
        if (hp <= 0) {
            game.gameOver();
        }
    }
    
    private function areAllEffectsMaxed():Bool {
        return cooldownReduction >= 18 &&
               maxShieldInstances >= 4 &&
               speedBonusCount >= 10 &&
               hasHomingBullets &&
               piercingCount >= 10;
    }
    
    public function applyTreasureEffect(effect:TreasureEffect):String {
        if (areAllEffectsMaxed()) {
            game.addEffectScore();
            return "All effects maxed! Score doubled!";
        }
        
        var result = switch(effect) {
            case TreasureEffect.CooldownReduction:
                if (cooldownReduction < 18) {
                    cooldownReduction++;
                    shootDelay *= 0.95;
                    shieldCooldownMax *= 0.95;
                    "Cooldown reduced by 5%!";
                } else findAndApplyAvailableEffect();
                
            case TreasureEffect.ShieldInstance:
                if (maxShieldInstances < 4) {
                    maxShieldInstances++;
                    shieldInstances++;
                    shieldActive = true;
                    shieldSprite.visible = true;
                    "Shield capacity increased! (" + maxShieldInstances + " max charges)";
                } else findAndApplyAvailableEffect();
                
            case TreasureEffect.SpeedBonus:
                if (speedBonusCount < 10) {
                    speedBonusCount++;
                    moveSpeed *= 1.1;
                    "Speed increased by 10%!";
                } else findAndApplyAvailableEffect();
                
            case TreasureEffect.HomingBullets:
                if (!hasHomingBullets) {
                    hasHomingBullets = true;
                    "Bullets now home in on enemies!";
                } else findAndApplyAvailableEffect();
                
            case TreasureEffect.PiercingBullets:
                if (piercingCount < 10) {
                    piercingCount++;
                    "Bullets now pierce through " + (piercingCount + 1) + " enemies!";
                } else findAndApplyAvailableEffect();
        }
        return result;
    }
    
    private function findAndApplyAvailableEffect():String {
        if (cooldownReduction < 18) {
            cooldownReduction++;
            shootDelay *= 0.95;
            shieldCooldownMax *= 0.95;
            return "Cooldown reduced by 5%!";
        }
        if (maxShieldInstances < 4) {
            maxShieldInstances++;
            shieldInstances++;
            shieldActive = true;
            shieldSprite.visible = true;
            return "Shield capacity increased! (" + maxShieldInstances + " max charges)";
        }
        if (speedBonusCount < 10) {
            speedBonusCount++;
            moveSpeed *= 1.1;
            return "Speed increased by 10%!";
        }
        if (!hasHomingBullets) {
            hasHomingBullets = true;
            return "Bullets now home in on enemies!";
        }
        if (piercingCount < 10) {
            piercingCount++;
            return "Bullets now pierce through " + (piercingCount + 1) + " enemies!";
        }
        return "All effects maxed! Score doubled!";
    }
    
    private function applyInvertColors() {
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
    
    private function removeInvertColors() {
        sprite.filter = null;
    }
    
    public function updateTreasureArrow(treasure:Treasure) {
        if (treasure == null) {
            treasureArrow.visible = false;
            return;
        }
        
        treasureArrow.visible = true;
        
        var dx = treasure.x - x;
        var dy = treasure.y - y;
        
        var angle = Math.atan2(dy, dx);
        
        var arrowDistance = 200;
        treasureArrow.x = Math.cos(angle) * arrowDistance;
        treasureArrow.y = Math.sin(angle) * arrowDistance;
        
        treasureArrow.rotation = angle;
    }
    
    public function getShieldInstances():String {
        return '${shieldInstances}/${maxShieldInstances}';
    }
} 