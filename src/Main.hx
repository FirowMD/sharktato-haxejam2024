import h2d.Scene.ScaleMode;
import hxd.Res;
import h3d.shader.ScreenShader;
import hxd.res.Sound;

class Main extends hxd.App {
    var player:Player;
    var world:h2d.Object;
    var worldWidth:Int = 5120;
    var worldHeight:Int = 2880;
    public var bullets:Array<Bullet>;
    public var enemies:Array<Enemy>;
    var spawnTimer:Float = 0;
    var spawnDelay:Float = 1.0;
    var maxEnemies:Int = 36;
    var maxInvulnerableEnemies:Int = 10;
    var currentMaxEnemies:Int = 0;
    var layerBullets:h2d.Object;
    var layerEnemies:h2d.Object;
    var layerPlayer:h2d.Object;
    var shader:CyberpunkShader;
    var time:Float = 0;
    var seaweeds:Array<Seaweed>;
    var treasureSpawnTimer:Float = 0;
    var treasureSpawnDelay:Float = 1.0;
    var currentTreasure:Treasure;
    var effectText:h2d.Text;
    var effectTextTimer:Float = 0;
    private var score:Int = 0;
    private var scoreText:h2d.Text;
    private var uiLayer:h2d.Object;
    private var hasInvulnerableSharkAtScore:Bool = false;
    private var backgroundMusic:hxd.snd.Channel;
    private var speedBonusApplied:Int = 0;
    private var baseSpawnDelay:Float = 3.0;
    private var baseMaxEnemies:Int = 10;
    private var gameOverText:h2d.Text;
    private var isGameOver:Bool = false;
    private var splashScreen:h2d.Bitmap;
    private var isSplashScreenActive:Bool = true;
    private var splashScreenAlpha:Float = 1.0;
    private var hasStartedFading:Bool = false;
    
    override function init() {
        showSplashScreen();
        
        var window = hxd.Window.getInstance();
        window.resize(1280, 720);
        s2d.scaleMode = Stretch(1280, 720);
        engine.backgroundColor = 0x1a4569;
        window.addResizeEvent(function() {
            s2d.scaleMode = Stretch(window.width, window.height);
        });
        
        world = new h2d.Object(s2d);
        bullets = [];
        enemies = [];
        seaweeds = [];
        
        layerBullets = new h2d.Object(world);
        layerEnemies = new h2d.Object(world);
        layerPlayer = new h2d.Object(world);
        
        Seaweed.spawnRandom(world, worldWidth, worldHeight, 30 + Std.random(20), seaweeds);
        player = new Player(layerPlayer, worldWidth, worldHeight, this);
        player.bulletLayer = layerBullets;
        player.x = worldWidth * 0.5;
        player.y = worldHeight * 0.5;
        
        var bounds = new h2d.Graphics(world);
        bounds.lineStyle(2, 0xFFFFFF);
        bounds.drawRect(0, 0, worldWidth, worldHeight);
        
        shader = new CyberpunkShader();
        s2d.filter = new h2d.filter.Shader(shader);
        
        var effectLayer = new h2d.Object(s2d);
        effectText = new h2d.Text(hxd.res.DefaultFont.get(), effectLayer);
        effectText.scale(2);
        effectText.visible = false;
        effectText.textAlign = Center;
        effectText.textColor = 0xFFFFFF;
        
        uiLayer = new h2d.Object(s2d);
        scoreText = new h2d.Text(hxd.res.DefaultFont.get(), uiLayer);
        scoreText.scale(2);
        scoreText.x = 20;
        scoreText.y = 20;
        scoreText.textColor = 0xFFFFFF;
        scoreText.maxWidth = 200;
        updateScoreDisplay();
        
        if (hxd.res.Sound.supportedFormat(Wav)) {
            var sound = hxd.Res.assets.sounds.background;
            backgroundMusic = sound.play(true);
            backgroundMusic.volume = 0.5;
        }
        
        spawnDelay = baseSpawnDelay;
        currentMaxEnemies = baseMaxEnemies;
        
        gameOverText = new h2d.Text(hxd.res.DefaultFont.get(), uiLayer);
        gameOverText.scale(3);
        gameOverText.textAlign = Center;
        gameOverText.textColor = 0xFF0000;
        gameOverText.visible = false;
        
        resetGame();
        
        world.visible = false;
        uiLayer.visible = false;
    }
    
    private function showSplashScreen() {
        splashScreen = new h2d.Bitmap(hxd.Res.assets.images.splashscreen.toTile(), s2d);
        
        var vpWidth = 1280;
        var vpHeight = 720;
        
        var scaleX = vpWidth / splashScreen.tile.width;
        var scaleY = vpHeight / splashScreen.tile.height;
        var scale = Math.min(scaleX, scaleY);
        
        splashScreen.setScale(scale);
        
        splashScreen.x = (vpWidth - splashScreen.tile.width * scale) * 0.5;
        splashScreen.y = (vpHeight - splashScreen.tile.height * scale) * 0.5;
    }
    
    function spawnEnemy() {
        var regularCount = 0;
        var invulnCount = 0;
        for (enemy in enemies) {
            if (enemy.isInvulnerable) invulnCount++;
            else regularCount++;
        }
        
        if (regularCount >= currentMaxEnemies) return;
        
        var minRegularSharks = Std.int(currentMaxEnemies * 0.7);
        if (regularCount < minRegularSharks) {
            var enemy = new Enemy(world, player, worldWidth, worldHeight, false);
            
            switch Std.random(4) {
                case 0: enemy.x = Math.random() * worldWidth; enemy.y = 0;
                case 1: enemy.x = worldWidth; enemy.y = Math.random() * worldHeight;
                case 2: enemy.x = Math.random() * worldWidth; enemy.y = worldHeight;
                case 3: enemy.x = 0; enemy.y = Math.random() * worldHeight;
            }
            
            enemies.push(enemy);
        }
    }
    
    private function checkScoreThresholds() {
        var currentThreshold = Math.floor(score / 200);
        
        if (currentThreshold > speedBonusApplied && speedBonusApplied < 20) {
            speedBonusApplied++;
            for (enemy in enemies) {
                enemy.increaseSpeed(0.10 * speedBonusApplied * 1.0);
            }
        }
        
        currentMaxEnemies = Std.int(Math.min(maxEnemies, baseMaxEnemies + currentThreshold));
    }
    
    override function update(dt:Float) {
        if (isSplashScreenActive) {
            if (!hasStartedFading && (
                hxd.Key.isPressed(hxd.Key.SPACE) ||
                hxd.Key.isPressed(hxd.Key.ENTER) ||
                hxd.Key.isPressed(hxd.Key.ESCAPE) ||
                hxd.Key.isPressed(hxd.Key.MOUSE_LEFT)
            )) {
                hasStartedFading = true;
            }
            
            if (hasStartedFading) {
                splashScreenAlpha -= dt;
                splashScreen.alpha = Math.max(0, splashScreenAlpha);
                
                if (splashScreenAlpha <= 0) {
                    splashScreen.remove();
                    isSplashScreenActive = false;
                    world.visible = true;
                    uiLayer.visible = true;
                }
                return;
            }
            return;
        }
        
        if (isGameOver) {
            if (hxd.Key.isPressed(hxd.Key.SPACE)) {
                resetGame();
            }
            return;
        }
        
        checkScoreThresholds();
        
        spawnTimer += dt;
        if (spawnTimer >= spawnDelay) {
            spawnTimer = 0;
            spawnEnemy();
        }
        
        var i = enemies.length;
        while (i-- > 0) {
            enemies[i].update(dt);
        }
        
        player.update(dt);
        
        var i = bullets.length;
        while (i-- > 0) {
            bullets[i].update(dt);
            if (bullets[i].parent == null) {
                bullets.splice(i, 1);
            }
        }
        
        var window = hxd.Window.getInstance();
        var deadZoneSize = 100;
        
        var targetX = player.x - window.width * 0.5;
        var targetY = player.y - window.height * 0.5;
        
        targetX = Math.max(0, Math.min(targetX, worldWidth - window.width));
        targetY = Math.max(0, Math.min(targetY, worldHeight - window.height));
        
        var cameraSpeed = 0.1;
        s2d.x = -hxd.Math.lerp(-s2d.x, targetX, cameraSpeed);
        s2d.y = -hxd.Math.lerp(-s2d.y, targetY, cameraSpeed);
        
        for (bullet in bullets.copy()) {
            for (enemy in enemies.copy()) {
                if (!enemy.isInvulnerable &&
                    bullet.checkCollision(enemy) && 
                    !bullet.hasHitEnemy(enemy)) {
                    enemy.neutralize();
                    bullet.addHitEnemy(enemy);
                    
                    if (bullet.piercingLeft > 0) {
                        bullet.piercingLeft--;
                    } else {
                        bullet.remove();
                        bullets.remove(bullet);
                        break;
                    }
                }
            }
        }
        
        for (enemy in enemies.copy()) {
            if (enemy.checkCollision(player)) {
                if (!enemy.isInvulnerable && enemy.isNeutralized) {
                    enemy.remove();
                    enemies.remove(enemy);
                    score += 250;
                    updateScoreDisplay();
                    hxd.Res.assets.sounds.shark_eat.play();
                } else if (enemy.canHitPlayer) {
                    player.damage();
                    enemy.onHitPlayer();
                }
            }
        }
        
        var i = seaweeds.length;
        while (i-- > 0) {
            seaweeds[i].update(dt);
            if (seaweeds[i].parent == null) {
                seaweeds.splice(i, 1);
                var newSeaweed = new Seaweed(world);
                newSeaweed.x = Math.random() * worldWidth;
                newSeaweed.y = Math.random() * worldHeight;
                seaweeds.push(newSeaweed);
            }
        }
        
        time += dt;
        shader.time = time;
        
        player.checkSeaweedHiding(seaweeds);
        
        treasureSpawnTimer += dt;
        if (treasureSpawnTimer >= treasureSpawnDelay && currentTreasure == null) {
            treasureSpawnTimer = 0;
            currentTreasure = new Treasure(world);
            currentTreasure.x = Math.random() * worldWidth;
            currentTreasure.y = Math.random() * worldHeight;
        }
        
        if (currentTreasure != null && player.checkCollision(currentTreasure)) {
            var message = player.applyTreasureEffect(currentTreasure.effect);
            var textX = currentTreasure.x;
            var textY = currentTreasure.y - 10;
            currentTreasure.remove();
            currentTreasure = null;
            score += 200;
            updateScoreDisplay();
            
            hxd.Res.assets.sounds.shark_eat.play();
            
            effectText.text = message;
            effectText.visible = true;
            effectText.setPosition(textX, textY);
            effectTextTimer = 2.0;
        }
        
        if (effectTextTimer > 0) {
            effectTextTimer -= dt;
            if (effectTextTimer <= 0) {
                effectText.visible = false;
            }
        }
        
        player.updateTreasureArrow(currentTreasure);
        
        uiLayer.setPosition(-s2d.x, -s2d.y);
        
        if (score > 0 && score % 100 == 0 && !hasInvulnerableSharkAtScore) {
            var currentInvulnCount = 0;
            for (enemy in enemies) {
                if (enemy.isInvulnerable) currentInvulnCount++;
            }
            
            var numSharks = Std.int(Math.min(10 - currentInvulnCount, 1 + Math.floor(score / 1000)));
            
            if (numSharks > 0) {
                for (i in 0...numSharks) {
                    var invulnShark = new Enemy(world, player, worldWidth, worldHeight, true);
                    invulnShark.bulletLayer = layerBullets;
                    
                    switch Std.random(4) {
                        case 0:
                            invulnShark.x = Math.random() * worldWidth;
                            invulnShark.y = 0;
                        case 1:
                            invulnShark.x = worldWidth;
                            invulnShark.y = Math.random() * worldHeight;
                        case 2:
                            invulnShark.x = Math.random() * worldWidth;
                            invulnShark.y = worldHeight;
                        case 3:
                            invulnShark.x = 0;
                            invulnShark.y = Math.random() * worldHeight;
                    }
                    
                    enemies.push(invulnShark);
                }
            }
            hasInvulnerableSharkAtScore = true;
        } else if (score % 100 != 0) {
            hasInvulnerableSharkAtScore = false;
        }
    }
    
    public function updateScoreDisplay() {
        scoreText.text = 'Score: ${score}\nShields: ${player.getShieldInstances()}';
    }
    
    public function addEffectScore() {
        score += 1000;
        updateScoreDisplay();
    }
    
    public function gameOver() {
        isGameOver = true;
        gameOverText.text = 'Game Over!\nFinal Score: ${score}\n\nPress SPACE to play again';
        gameOverText.visible = true;
        gameOverText.setPosition(
            hxd.Window.getInstance().width * 0.5,
            hxd.Window.getInstance().height * 0.4
        );
    }
    
    private function resetGame() {
        score = 0;
        isGameOver = false;
        speedBonusApplied = 0;
        spawnDelay = baseSpawnDelay;
        maxEnemies = baseMaxEnemies;
        hasInvulnerableSharkAtScore = false;
        
        Treasure.resetState();
        
        for (enemy in enemies.copy()) enemy.remove();
        for (bullet in bullets.copy()) bullet.remove();
        if (currentTreasure != null) currentTreasure.remove();
        enemies = [];
        bullets = [];
        currentTreasure = null;
        
        if (player != null) player.remove();
        player = new Player(layerPlayer, worldWidth, worldHeight, this);
        player.bulletLayer = layerBullets;
        player.x = worldWidth * 0.5;
        player.y = worldHeight * 0.5;
        
        gameOverText.visible = false;
        
        updateScoreDisplay();
    }
    
    static function main() {
        hxd.Res.initEmbed();
        new Main();
    }
}