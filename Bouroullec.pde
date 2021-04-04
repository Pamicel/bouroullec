import toxi.geom.*;

ArrayList<Vec2D> curve = new ArrayList<Vec2D>();
Vec2D[] resampledCurve = null;

class RibonEndButtons {
  Vec2D rightBank, leftBank, center;
  RibonEndButtons () {}
}

class Ribon {
  float linearDensity;
  ArrayList<Vec2D[]> curves = new ArrayList<Vec2D[]>();
  RibonEndButtons frontButtons = null;
  RibonEndButtons backButtons = null;

  Ribon(float linearDensity) {
    this.linearDensity = linearDensity;
  }

  void addToBack(ArrayList<Vec2D> curve) {
    Vec2D[] processedCurve;

    int curvesLen = this.curves.size();
    Vec2D[] resampledCurve = densityResample(curve, linearDensity);
    if (curvesLen != 0) {
      Vec2D[] endCurve = this.curves.get(curvesLen - 1);
      Vec2D referencePoint = endCurve[endCurve.length - 1];
      Vec2D translation = referencePoint.sub(resampledCurve[0]);
      // translate
      processedCurve = new Vec2D[resampledCurve.length];
      for (int i = 0; i < resampledCurve.length; i++) {
        processedCurve[i] = resampledCurve[i].add(translation);
      }
    } else {
      processedCurve = resampledCurve;
    }

    this.curves.add(processedCurve);
  }

  void addToFront(ArrayList<Vec2D> curve) {
    Vec2D[] resampledCurve = densityResample(curve, linearDensity);
    Vec2D translation = new Vec2D(0, 0);

    if (this.curves.size() != 0) {
      Vec2D[] frontCurve = this.curves.get(0);
      Vec2D referencePoint = frontCurve[0];
      translation = referencePoint.sub(resampledCurve[0]);
    }

    // Reverse and translate
    Vec2D[] processedCurve = new Vec2D[resampledCurve.length];
    for (int i = 0; i < resampledCurve.length; i++) {
      processedCurve[i] = resampledCurve[resampledCurve.length - i - 1].add(translation);
    }

    this.curves.add(0, processedCurve);
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

  void computeEndButtons(float ribonWid) {
    int len = this.curves.size();
    Vec2D[] firstCurve = this.curves.get(0);
    Vec2D[] lastCurve = this.curves.get(len - 1);

    this.frontButtons = new RibonEndButtons();
    this.backButtons = new RibonEndButtons();

    this.frontButtons.center = firstCurve[0];
    this.frontButtons.leftBank = firstCurve[0].add(firstCurve[1].sub(firstCurve[0]).getRotated(HALF_PI).getNormalizedTo(ribonWid / 2));
    this.frontButtons.rightBank = firstCurve[0].add(firstCurve[1].sub(firstCurve[0]).getRotated(-HALF_PI).getNormalizedTo(ribonWid / 2));
    this.backButtons.rightBank = lastCurve[lastCurve.length - 1].add(lastCurve[lastCurve.length - 2].sub(lastCurve[lastCurve.length - 1]).getRotated(HALF_PI).getNormalizedTo(ribonWid / 2));
    this.backButtons.leftBank = lastCurve[lastCurve.length - 1].add(lastCurve[lastCurve.length - 2].sub(lastCurve[lastCurve.length - 1]).getRotated(-HALF_PI).getNormalizedTo(ribonWid / 2));
    this.backButtons.center = lastCurve[lastCurve.length - 1];
  }

  void displayEndButtons(PGraphics layer) {
    if (this.frontButtons != null && this.backButtons != null) {
      layer.noStroke();
      layer.fill(255, 0, 0);
      layer.circle(this.frontButtons.center.x, this.frontButtons.center.y, 5);
      layer.circle(this.backButtons.center.x, this.backButtons.center.y, 5);
      layer.fill(0, 255, 0);
      layer.circle(this.frontButtons.rightBank.x, this.frontButtons.rightBank.y, 5);
      layer.circle(this.backButtons.rightBank.x, this.backButtons.rightBank.y, 5);
      layer.fill(0, 0, 255);
      layer.circle(this.frontButtons.leftBank.x, this.frontButtons.leftBank.y, 5);
      layer.circle(this.backButtons.leftBank.x, this.backButtons.leftBank.y, 5);
    }
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

  layer2.beginDraw();
  layer2.clear();
  ribon.displayEndButtons(layer2);
  layer2.endDraw();

  image(layer1, 0, 0);
  image(layer2, 0, 0);
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
  ribon.addToBack(curve);
  ribon.computeEndButtons(20);
}