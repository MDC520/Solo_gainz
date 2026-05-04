
enum ColliderTarget { player, attack, kickAttack, bag, box, clone, cloneAttack }

class ColliderFrameData {
  double x, y, w, h, r;
  ColliderFrameData({this.x = 0, this.y = 0, this.w = 50, this.h = 50, this.r = 0});
}

class CombatData {
  static final Map<String, ColliderFrameData> frameData = {};

  static String getFrameKey(ColliderTarget target, String anim, int frame) {
    return '${target.name}_${anim}_$frame';
  }

  static ColliderFrameData getOrCreateFrameData(ColliderTarget target, String anim, int frame, {ColliderFrameData? defaults}) {
    final key = getFrameKey(target, anim, frame);
    if (!frameData.containsKey(key)) {
      frameData[key] = defaults ?? ColliderFrameData();
    }
    return frameData[key]!;
  }
}
