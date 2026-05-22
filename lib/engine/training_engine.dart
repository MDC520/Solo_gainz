import 'dart:math' as math;
import 'dart:ui' show Rect, Offset;
import 'combat_engine.dart' as ce;

// ── Game Object Classes ─────────────────────────────────────────────────────

class GameBox {
  double x;
  double y = 0.0;
  double rotation = 0.0;
  double colliderOffsetX = 0.0;
  double colliderOffsetY = 0.0;
  double colliderWidth;
  double colliderHeight;
  double velX = 0.0;
  double velY = 0.0;
  double get weight => 10.0;

  GameBox({required this.x, required double width, required double height})
      : colliderWidth = width, colliderHeight = height;
}

class DamageNumber {
  double x;
  double y;
  int damage;
  double opacity = 1.0;
  double velY = 2.0;

  DamageNumber({required this.x, required this.y, required this.damage});

  void update() {
    y += velY;
    velY *= 0.95;
    opacity -= 0.02;
  }
}

class GameClone {
  double x;
  double startX;
  double y = 0.0;
  double rotation = 0.0;
  bool isPunching = false;
  DateTime? punchStartTime;
  bool isHit = false;
  DateTime? hitStartTime;
  bool isKnockback = false;
  bool isGettingUp = false;
  DateTime? getUpStartTime;
  bool isWalking = false;
  bool isRecovering = false;
  bool flip = true;
  double colliderW = 40.0;
  double colliderH = 103.0;
  double colliderOffsetX = -20.0;
  double colliderOffsetY = 0.0;

  GameClone({required this.x}) : startX = x;

  void update() {
    if (isKnockback) {
      if (hitStartTime != null) {
        final elapsed = DateTime.now().difference(hitStartTime!).inMilliseconds;
        if (elapsed > 800) {
          isKnockback = false;
          isGettingUp = true;
          getUpStartTime = DateTime.now();
        }
      }
      return;
    }
    if (isGettingUp) {
      if (getUpStartTime != null) {
        final elapsed = DateTime.now().difference(getUpStartTime!).inMilliseconds;
        if (elapsed > 400) {
          isGettingUp = false;
          getUpStartTime = null;
        }
      }
      return;
    }
    if (isHit) return;
    if (x != startX) {
      isWalking = true;
      isRecovering = true;
      flip = x > startX;
      double dx = startX - x;
      if (dx.abs() < 2.5) {
        x = startX;
        isWalking = false;
        isRecovering = false;
        flip = true;
      } else {
        x += dx.sign * 2.5;
      }
    } else {
      isWalking = false;
      isRecovering = false;
    }
  }

  void punch() {
    if (isPunching || isHit || isKnockback || isGettingUp) return;
    isPunching = true;
    punchStartTime = DateTime.now();
  }

  void onHit(bool isKick, double dir, {Duration? customDuration}) {
    if (isKnockback || isGettingUp || isRecovering) return;
    if (!isKick && isHit) return;
    isPunching = false;
    isRecovering = true;
    if (isKick) {
      isHit = false;
      isKnockback = true;
      isGettingUp = false;
      flip = (dir > 0);
      hitStartTime = DateTime.now();
      x += dir * 80;
    } else {
      isHit = true;
      hitStartTime = DateTime.now();
      x += dir * 20;
    }
  }

  String getCurrentAnimation() {
    if (isKnockback) return 'Knockback';
    if (isGettingUp) return 'GetUp';
    if (isHit) return 'Hit';
    if (isPunching) return 'Punch01';
    if (isWalking) return 'Walk';
    return 'Idle';
  }
}

// ── Training Engine ─────────────────────────────────────────────────────────

class TrainingEngine {
  // Player state
  double playerWorldX = 100.0;
  double velocityX = 0.0;
  double joystickInputX = 0.0;
  bool isMoving = false;
  bool isRunning = false;
  bool flip = false;
  bool isJumping = false;
  double playerY = 0.0;
  double velocityY = 0.0;
  bool isGrounded = true;

  // Combat
  bool isPunching = false;
  DateTime? punchStartTime;
  bool isKicking = false;
  DateTime? kickStartTime;
  bool isPlayerHit = false;
  final List<DamageNumber> damageNumbers = [];

  // Grabbing
  bool isGrabbing = false;
  bool canGrab = false;
  GameBox? grabbedBox;
  int grabSide = 0;
  bool isPushingBox = false;
  bool isPullingBox = false;

  // Input flags (set externally)
  bool leftPressed = false;
  bool rightPressed = false;
  bool jumpPressed = false;
  bool runPressed = false;
  bool attackPressed = false;
  bool kickPressed = false;

  // Game objects
  final List<GameBox> boxes;
  final GameClone clone;

  // Constants
  static const double walkAccel = 0.4;
  static const double runAccel = 0.8;
  static const double friction = 0.88;
  static const double airFriction = 0.96;
  static const double maxWalkSpeed = 3.5;
  static const double maxRunSpeed = 7.5;
  static const double gravity = -1.4;
  static const double jumpForce = 22.0;
  static const double fallMultiplier = 1.6;
  static const double groundY = 120.0;
  static const double mapWidth = 2000.0;

  // Collider defaults
  double debugPunchOffsetX = 38.0;
  double debugPunchOffsetY = 41.0;
  double debugPunchWidth = 107.0;
  double debugPunchHeight = 14.0;
  double debugPunchRotation = 0.0;
  double debugKickOffsetX = 45.0;
  double debugKickOffsetY = 30.0;
  double debugKickWidth = 90.0;
  double debugKickHeight = 25.0;
  double debugKickRotation = 0.0;
  double playerHitboxW = 40.0;
  double playerHitboxH = 103.0;
  double playerHitboxOffsetX = -20.0;
  double playerHitboxOffsetY = 0.0;
  double playerHitboxRotation = 0.0;
  double cloneAttackOffsetX = 38.0;
  double cloneAttackOffsetY = 41.0;
  double cloneAttackWidth = 107.0;
  double cloneAttackHeight = 14.0;
  double cloneAttackRotation = 0.0;

  TrainingEngine()
      : clone = GameClone(x: 1500),
        boxes = [GameBox(x: 800, width: 90, height: 90)] {
    ce.CombatData.frameData[ce.CombatData.getFrameKey(ce.ColliderTarget.attack, 'Punch01', 2)] =
        ce.ColliderFrameData(x: 33, y: 55, w: 107, h: 14, r: 0);
    ce.CombatData.frameData[ce.CombatData.getFrameKey(ce.ColliderTarget.kickAttack, 'Kick01', 2)] =
        ce.ColliderFrameData(x: 38.0, y: 79.0, w: 65.0, h: 11.0, r: -13 * math.pi / 180);
  }

  // ── Core Update Loop ──

  void tick() {
    joystickInputX = (rightPressed ? 1.0 : 0.0) - (leftPressed ? 1.0 : 0.0);

    if (isPunching || isKicking) {
      joystickInputX = 0;
      velocityX = 0;
    }

    clone.update();

    for (int i = damageNumbers.length - 1; i >= 0; i--) {
      damageNumbers[i].update();
      if (damageNumbers[i].opacity <= 0) damageNumbers.removeAt(i);
    }

    _updateHorizontalPhysics();
    _updateGrabbedBox();
    _updateVerticalPhysics();
    _updateBoxCollisions();
    _updateCloneCollision();
    _updateBoxBoxCollisions();
    _updateDirection();
    _updateGrabProximity();
    _updateWorldBounds();

    // Grounded check
    bool groundedOnBox = false;
    for (var box in boxes) {
      if (box == grabbedBox) continue;
      double pBottom = playerY + playerHitboxOffsetY;
      double bBottom = box.y + box.colliderOffsetY;
      if (velocityY <= 0 && pBottom > bBottom + box.colliderHeight * 0.5) {
        groundedOnBox = true;
      }
    }
    isGrounded = (playerY <= 0) || groundedOnBox;

    _detectPunchHit();
    _detectKickHit();
    _detectCloneAttack();
  }

  void _updateHorizontalPhysics() {
    bool canRun = runPressed && isGrounded && grabbedBox == null && !isPunching && !isKicking && !isJumping;
    double accel = canRun ? runAccel : walkAccel;
    if (!isGrounded) accel *= 0.4;

    if (joystickInputX.abs() > 0.1) {
      velocityX += joystickInputX * accel;
    } else {
      velocityX *= (isGrounded ? friction : airFriction);
    }

    double currentMaxSpeed = canRun ? maxRunSpeed : maxWalkSpeed;
    if (velocityX.abs() > currentMaxSpeed) {
      velocityX = velocityX.sign * currentMaxSpeed;
    }

    playerWorldX += velocityX;
  }

  void _updateGrabbedBox() {
    if (grabbedBox == null) {
      isPushingBox = false;
      isPullingBox = false;
      return;
    }
    if (grabSide == 1) {
      grabbedBox!.x = playerWorldX + playerHitboxOffsetX + playerHitboxW;
      flip = false;
    } else {
      grabbedBox!.x = playerWorldX + playerHitboxOffsetX - grabbedBox!.colliderWidth;
      flip = true;
    }
    grabbedBox!.velX = velocityX;
    isPushingBox = false;
    isPullingBox = false;
    if (velocityX.abs() > 0.1) {
      if ((grabSide == 1 && velocityX > 0) || (grabSide == -1 && velocityX < 0)) {
        isPushingBox = true;
      } else {
        isPullingBox = true;
      }
    }
  }

  void _updateVerticalPhysics() {
    if (!isJumping && playerY <= 0) return;
    double currentGravity = gravity;
    if (velocityY < 0) currentGravity *= fallMultiplier;
    velocityY += currentGravity;
    playerY += velocityY;
    if (playerY <= 0) {
      playerY = 0;
      velocityY = 0;
      isJumping = false;
    }
  }

  void _updateBoxCollisions() {
    bool groundedOnBox = false;
    for (var box in boxes) {
      if (box != grabbedBox) {
        box.velX *= 0.9;
        box.x += box.velX;
      }
      if (box.y > 0) {
        box.velY += gravity;
        box.y += box.velY;
        if (box.y < 0) { box.y = 0; box.velY = 0; }
      }
      if (box == grabbedBox) continue;

      double pLeft = playerWorldX + playerHitboxOffsetX;
      double pRight = pLeft + playerHitboxW;
      double pBottom = playerY + playerHitboxOffsetY;
      double pTop = pBottom + playerHitboxH;
      double bLeft = box.x + box.colliderOffsetX;
      double bRight = bLeft + box.colliderWidth;
      double bBottom = box.y + box.colliderOffsetY;
      double bTop = bBottom + box.colliderHeight;
      bool overlapX = (pRight > bLeft) && (pLeft < bRight);
      bool overlapY = (pTop > bBottom) && (pBottom < bTop);

      if (overlapX && overlapY) {
        if (velocityY <= 0 && pBottom > bBottom + box.colliderHeight * 0.5) {
          playerY = bTop - playerHitboxOffsetY;
          velocityY = 0;
          isJumping = false;
          groundedOnBox = true;
        } else {
          if (pLeft + playerHitboxW / 2 < bLeft + box.colliderWidth / 2) {
            playerWorldX = bLeft - playerHitboxW - playerHitboxOffsetX;
          } else {
            playerWorldX = bRight - playerHitboxOffsetX;
          }
          velocityX = 0;
        }
      }
    }
    isGrounded = (playerY <= 0) || groundedOnBox;
  }

  void _updateCloneCollision() {
    if (clone.isKnockback) return;
    double pLeft = playerWorldX + playerHitboxOffsetX;
    double pRight = pLeft + playerHitboxW;
    double pBottom = playerY + playerHitboxOffsetY;
    double pTop = pBottom + playerHitboxH;
    double cLeft = clone.x + clone.colliderOffsetX;
    double cRight = cLeft + clone.colliderW;
    double cBottom = clone.y + clone.colliderOffsetY;
    double cTop = cBottom + clone.colliderH;
    bool overlapCloneX = (pRight > cLeft) && (pLeft < cRight);
    bool overlapCloneY = (pTop > cBottom) && (pBottom < cTop);

    if (overlapCloneX && overlapCloneY) {
      if (velocityY <= 0 && pBottom > cBottom + clone.colliderH * 0.7) {
        velocityY = jumpForce * 0.6;
        playerY = cTop - playerHitboxOffsetY;
        clone.onHit(true, flip ? -0.5 : 0.5, customDuration: const Duration(milliseconds: 1500));
        velocityX = flip ? -8.0 : 8.0;
      } else {
        if (pLeft + playerHitboxW / 2 < cLeft + clone.colliderW / 2) {
          playerWorldX = cLeft - playerHitboxW - playerHitboxOffsetX;
        } else {
          playerWorldX = cRight - playerHitboxOffsetX;
        }
        velocityX = 0;
      }
    }
  }

  void _updateBoxBoxCollisions() {
    for (int i = 0; i < boxes.length; i++) {
      for (int j = i + 1; j < boxes.length; j++) {
        var b1 = boxes[i];
        var b2 = boxes[j];
        double b1L = b1.x + b1.colliderOffsetX;
        double b1R = b1L + b1.colliderWidth;
        double b1B = b1.y + b1.colliderOffsetY;
        double b1T = b1B + b1.colliderHeight;
        double b2L = b2.x + b2.colliderOffsetX;
        double b2R = b2L + b2.colliderWidth;
        double b2B = b2.y + b2.colliderOffsetY;
        double b2T = b2B + b2.colliderHeight;
        bool overlapX = (b1R > b2L) && (b1L < b2R);
        bool overlapY = (b1T > b2B) && (b1B < b2T);

        if (overlapX && overlapY) {
          if (b1L < b2L) {
            double overlap = b1R - b2L;
            b1.x -= overlap / 2;
            b2.x += overlap / 2;
            double avgVel = (b1.velX + b2.velX) / 2;
            b1.velX = avgVel;
            b2.velX = avgVel;
          } else {
            double overlap = b2R - b1L;
            b1.x += overlap / 2;
            b2.x -= overlap / 2;
            double avgVel = (b1.velX + b2.velX) / 2;
            b1.velX = avgVel;
            b2.velX = avgVel;
          }
        }
      }
    }
  }

  void _updateDirection() {
    isMoving = velocityX.abs() > 0.1;
    if (grabbedBox == null && !isPunching && !isKicking) {
      if (joystickInputX < 0) flip = true;
      if (joystickInputX > 0) flip = false;
    }
  }

  void _updateGrabProximity() {
    canGrab = false;
    if (isGrabbing || !isGrounded) return;
    double pLeft = playerWorldX + playerHitboxOffsetX;
    double pRight = pLeft + playerHitboxW;
    double pBottom = playerY + playerHitboxOffsetY;
    double pTop = pBottom + playerHitboxH;

    for (var box in boxes) {
      double bLeft = box.x + box.colliderOffsetX;
      double bRight = bLeft + box.colliderWidth;
      double bBottom = box.y + box.colliderOffsetY;
      double bTop = bBottom + box.colliderHeight;
      bool overlapY = (pTop > bBottom) && (pBottom < bTop);
      if (!overlapY) continue;
      if (pRight >= bLeft - 15 && pRight <= bLeft + box.colliderWidth / 2) {
        canGrab = true;
        break;
      } else if (pLeft <= bRight + 15 && pLeft >= bLeft + box.colliderWidth / 2) {
        canGrab = true;
        break;
      }
    }
  }

  void _updateWorldBounds() {
    if (playerWorldX + playerHitboxOffsetX < 0) {
      playerWorldX = -playerHitboxOffsetX;
      velocityX = 0;
    } else if (playerWorldX > mapWidth) {
      playerWorldX = mapWidth;
      velocityX = 0;
    }
  }

  void _detectPunchHit() {
    if (!isPunching || punchStartTime == null) return;
    const int impactFrame = 2;
    final elapsed = DateTime.now().difference(punchStartTime!).inMilliseconds;
    int frame = (elapsed / (1000 / 12)).floor();
    if (frame != impactFrame) return;

    final data = ce.CombatData.getOrCreateFrameData(ce.ColliderTarget.attack, 'Punch01', impactFrame,
        defaults: ce.ColliderFrameData(x: debugPunchOffsetX, y: debugPunchOffsetY, w: debugPunchWidth, h: debugPunchHeight, r: debugPunchRotation));

    double pCenter = playerWorldX + playerHitboxOffsetX + (playerHitboxW / 2);
    double reachX = flip ? pCenter - data.x : pCenter + data.x;
    Rect attackRect = Rect.fromCenter(
      center: Offset(reachX, groundY + playerY + data.y + (data.h / 2)),
      width: data.w,
      height: data.h,
    );

    if (!clone.isHit && !clone.isKnockback && !clone.isRecovering) {
      Rect cloneRect = Rect.fromLTWH(
        clone.x + clone.colliderOffsetX, groundY + clone.y + clone.colliderOffsetY,
        clone.colliderW, clone.colliderH,
      );
      if (attackRect.overlaps(cloneRect)) {
        clone.onHit(false, flip ? -1 : 1);
        damageNumbers.add(DamageNumber(x: attackRect.center.dx, y: attackRect.center.dy, damage: 15));
      }
    }
  }

  void _detectKickHit() {
    if (!isKicking || kickStartTime == null) return;
    const int impactFrame = 2;
    final elapsed = DateTime.now().difference(kickStartTime!).inMilliseconds;
    int frame = (elapsed / (1000 / 12)).floor();
    if (frame != impactFrame) return;

    final data = ce.CombatData.getOrCreateFrameData(ce.ColliderTarget.kickAttack, 'Kick01', impactFrame,
        defaults: ce.ColliderFrameData(x: debugKickOffsetX, y: debugKickOffsetY, w: debugKickWidth, h: debugKickHeight, r: debugKickRotation));

    double pCenter = playerWorldX + playerHitboxOffsetX + (playerHitboxW / 2);
    double reachX = flip ? pCenter - data.x : pCenter + data.x;
    Rect attackRect = Rect.fromCenter(
      center: Offset(reachX, groundY + playerY + data.y + (data.h / 2)),
      width: data.w,
      height: data.h,
    );

    if (!clone.isHit && !clone.isKnockback && !clone.isRecovering) {
      Rect cloneRect = Rect.fromLTWH(
        clone.x + clone.colliderOffsetX, groundY + clone.y + clone.colliderOffsetY,
        clone.colliderW, clone.colliderH,
      );
      if (attackRect.overlaps(cloneRect)) {
        clone.onHit(true, flip ? -1 : 1);
        damageNumbers.add(DamageNumber(x: attackRect.center.dx, y: attackRect.center.dy, damage: 30));
      }
    }
  }

  void _detectCloneAttack() {
    if (!clone.isPunching || clone.punchStartTime == null) return;
    final elapsed = DateTime.now().difference(clone.punchStartTime!).inMilliseconds;
    if (elapsed <= 330) return;

    double cCenter = clone.x + clone.colliderOffsetX + (clone.colliderW / 2);
    double reachX = clone.flip ? cCenter - cloneAttackOffsetX : cCenter + cloneAttackOffsetX;

    Rect cAttackRect = Rect.fromLTWH(
      reachX - (cloneAttackWidth / 2),
      clone.y + cloneAttackOffsetY,
      cloneAttackWidth,
      cloneAttackHeight,
    );
    Rect pRect = Rect.fromLTWH(
      playerWorldX + playerHitboxOffsetX,
      playerY + playerHitboxOffsetY,
      playerHitboxW,
      playerHitboxH,
    );

    if (cAttackRect.overlaps(pRect) && !isPlayerHit) {
      isPlayerHit = true;
      isPunching = false;
      velocityX = clone.flip ? -5 : 5;
    }
  }

  // ── Action Methods ──

  void jump() {
    if (isJumping || !isGrounded || isPunching || isKicking) return;
    endGrab();
    isJumping = true;
    velocityY = jumpForce;
    isRunning = false;
  }

  void punch() {
    if (isPunching || isKicking || isRunning || isJumping || grabbedBox != null) return;
    isPunching = true;
    punchStartTime = DateTime.now();
  }

  void kick() {
    if (isPunching || isKicking || isRunning || isJumping || grabbedBox != null) return;
    isKicking = true;
    kickStartTime = DateTime.now();
  }

  void endGrab() {
    isGrabbing = false;
    grabbedBox = null;
    isPushingBox = false;
    isPullingBox = false;
  }

  void startGrab() {
    if (!isGrounded) return;
    isGrabbing = true;
    for (var box in boxes) {
      bool overlapY = (playerY + playerHitboxH > box.y + box.colliderOffsetY) &&
          (playerY + playerHitboxOffsetY < box.y + box.colliderOffsetY + box.colliderHeight);
      if (!overlapY) continue;
      if ((playerWorldX + playerHitboxOffsetX + playerHitboxW) >= (box.x + box.colliderOffsetX) - 10 &&
          (playerWorldX + playerHitboxOffsetX + playerHitboxW) <= (box.x + box.colliderOffsetX) + box.colliderWidth / 2) {
        grabbedBox = box;
        grabSide = 1;
        break;
      } else if ((playerWorldX + playerHitboxOffsetX) <= (box.x + box.colliderOffsetX) + box.colliderWidth + 10 &&
          (playerWorldX + playerHitboxOffsetX) >= (box.x + box.colliderOffsetX) + box.colliderWidth / 2) {
        grabbedBox = box;
        grabSide = -1;
        break;
      }
    }
  }

  int calculateBoxChain(GameBox startBox, double direction) {
    int count = 1;
    GameBox current = startBox;
    List<GameBox> visited = [startBox];
    bool foundNext = true;
    while (foundNext) {
      foundNext = false;
      for (var other in boxes) {
        if (visited.contains(other)) continue;
        bool overlapY = (current.y + current.colliderOffsetY + current.colliderHeight > other.y + other.colliderOffsetY) &&
            (current.y + current.colliderOffsetY < other.y + other.colliderOffsetY + other.colliderHeight);
        if (!overlapY) continue;
        bool touching = false;
        if (direction >= 0) {
          touching = (current.x + current.colliderOffsetX + current.colliderWidth >= (other.x + other.colliderOffsetX) - 10) &&
              (current.x + current.colliderOffsetX < (other.x + other.colliderOffsetX) + 5);
        } else {
          touching = (other.x + other.colliderOffsetX + other.colliderWidth >= (current.x + current.colliderOffsetX) - 10) &&
              (other.x + other.colliderOffsetX < (current.x + current.colliderOffsetX) + 5);
        }
        if (touching) {
          visited.add(other);
          current = other;
          count++;
          foundNext = true;
          break;
        }
      }
    }
    return count;
  }

  // ── Query ──

  String getCurrentAnimation() {
    if (isPlayerHit) return 'Hit';
    if (isKicking) return 'Kick01';
    if (isPunching) return 'Punch01';
    if (isJumping || !isGrounded) {
      return velocityY > 0 ? 'Jump' : 'Jump Fall';
    }
    if (grabbedBox != null) {
      if (isPushingBox) return 'Push';
      if (isPullingBox) return 'Pull';
      return 'PushIdle';
    }
    if (isMoving) {
      return isRunning ? 'Run' : 'Walk';
    }
    return 'Idle';
  }

  int getAnimFrameCount(String anim) => ce.getAnimFrameCount(anim);

  String getFrameAssetPath(String anim, int frameIdx) => ce.getFrameAssetPath(anim, frameIdx);

  int getCurrentFrameIndex(String anim, DateTime startTime, double fps) {
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    int frame = (elapsed / (1000 / fps)).floor();
    return frame.clamp(0, getAnimFrameCount(anim) - 1);
  }
}
