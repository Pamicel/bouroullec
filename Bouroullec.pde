import toxi.geom.*;

ArrayList<Vec2D> curve = new ArrayList<Vec2D>();
Vec2D[] resampledCurve = null;

class Ribon {
  float linearDensity;
  ArrayList<Vec2D[]> curves = new ArrayList<Vec2D[]>();

  Ribon(float linearDensity) {
    this.linearDensity = linearDensity;
  }

  void addToEnd(ArrayList<Vec2D> curve) {
    Vec2D[] resampledCurve = densityResample(curve, linearDensity);
    this.curves.add(resampledCurve);
  }

  void addToFront(ArrayList<Vec2D> curve) {
    Vec2D[] resampledCurve = densityResample(curve, linearDensity);
    Vec2D[] reverse = new Vec2D[resampledCurve.length];
    for (int i = 0; i < resampledCurve.length; i++) {
      reverse[i] = resampledCurve[resampledCurve.length - i - 1];
    }
    this.curves.add(0, reverse);
  }

  void displayCurve(PGraphics layer) {
    int curveLen = this.curves.size();
    if (curveLen == 0) {
      return;
    }

    layer.stroke(0);
    layer.noFill();
    layer.beginShape();
    Vec2D pos;
    Vec2D[] currentCurve;
    for (int curveIndex = 0; curveIndex < curveLen; curveIndex++) {
      currentCurve = this.curves.get(curveIndex);
      for (int i = 0; i < currentCurve.length; i++) {
        pos = currentCurve[i];
        layer.circle(pos.x, pos.y, 5);
        layer.vertex(pos.x, pos.y);
      }
    }
    layer.endShape();
  }

  Vec2D[] getButtonsPositions(float ribonWid) {
    int len = this.curves.size();
    Vec2D[] firstCurve = this.curves.get(0);
    Vec2D[] lastCurve = this.curves.get(len - 1);
    Vec2D[] buttonsPositions = new Vec2D[6];

    buttonsPositions[0] = firstCurve[0];
    buttonsPositions[1] = firstCurve[0].add(firstCurve[1].sub(firstCurve[0])).getRotated(PI).getNormalizedTo(ribonWid / 2);
    buttonsPositions[2] = firstCurve[0].add(firstCurve[1].sub(firstCurve[0])).getRotated(-PI).getNormalizedTo(ribonWid / 2);
    buttonsPositions[3] = lastCurve[lastCurve.length - 1].add(lastCurve[lastCurve.length - 2].sub(lastCurve[lastCurve.length - 1])).getRotated(PI).getNormalizedTo(ribonWid / 2);
    buttonsPositions[4] = lastCurve[lastCurve.length - 1].add(lastCurve[lastCurve.length - 2].sub(lastCurve[lastCurve.length - 1])).getRotated(-PI).getNormalizedTo(ribonWid / 2);
    buttonsPositions[5] = lastCurve[lastCurve.length - 1];

    return buttonsPositions;
  }
}

PGraphics layer1, layer2;
float LINEAR_DENSITY = 1.0 / 10; // 1 point every 10 pixels
Ribon ribon = new Ribon(LINEAR_DENSITY);

void setup() {
  size(800, 800);
  noFill();
  layer1 = createGraphics(width, height);
  layer2 = createGraphics(width, height);
}

float signedAngle(Vec2D pos) {
  Vec2D normalVector = new Vec2D(1,0);
  float angle = acos(pos.getNormalized().dot(normalVector));
  if (pos.sub(normalVector).y < 0) {
    angle = -angle;
  }
  return angle;
}

Vec2D pos = new Vec2D(0, 0);

void draw() {
  background(255);

  Vec2D pos;
  if (mousePressed) {
    stroke(0);
    beginShape();
    for (int i = 0; i < curve.size(); i++) {
      pos = curve.get(i);
      circle(pos.x, pos.y, 5);
      vertex(pos.x, pos.y);
    }
    endShape();
  }

  layer1.beginDraw();
  layer1.clear();
  ribon.displayCurve(layer1);
  layer1.endDraw();

  image(layer1, 0, 0);
}

Vec2D[] remapCurve(Vec2D[] curve, Vec2D targetPointA, Vec2D targetPointB) {
  Vec2D curvePointA = curve[0];
  Vec2D curvePointB = curve[curve.length - 1];

  Vec2D curveDirVec = curvePointB.sub(curvePointA);
  Vec2D targetDirVec = targetPointB.sub(targetPointA);

  float curveAngle = signedAngle(curveDirVec);
  float targetAngle = signedAngle(targetDirVec);

  float angle = targetAngle - curveAngle;

  float curveLen = curveDirVec.magnitude();
  float targetLen = targetDirVec.magnitude();

  float scale = targetLen / curveLen;

  Vec2D[] remaped = new Vec2D[curve.length];
  remaped[0] = targetPointA.copy();
  for (int i = 1; i < curve.length; i++) {
    remaped[i] = curve[i].sub(curve[0]).scale(scale).getRotated(angle).add(targetPointA);
  }

  return remaped;
}

void mouseDragged() {
  curve.add(new Vec2D(mouseX, mouseY));
}

void mousePressed() {
  curve = new ArrayList<Vec2D>();
  curve.add(new Vec2D(mouseX, mouseY));
}

void mouseReleased() {
  resampledCurve = densityResample(curve, 1.0 / 10);
  ribon.addToEnd(curve);
}