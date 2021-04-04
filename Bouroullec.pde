import toxi.geom.*;
import java.util.*;

ArrayList<Vec2D> curve = new ArrayList<Vec2D>();
Vec2D[] resampledCurve = null;

RibonEndPositions ribonEndPositions;

class RibonEndButtons {
  Vec2D rightBank, leftBank, center;
  float radius = 5;
  RibonEndButtons () {}

  private boolean isHover (Vec2D position, int mX, int mY) {
    return position.distanceToSquared(new Vec2D(mX, mY)) < (this.radius * this.radius);
  }

  boolean isHoverLeftBank(int mX, int mY) {
    return this.isHover(this.leftBank, mX, mY);
  }
  boolean isHoverRightBank(int mX, int mY) {
    return this.isHover(this.leftBank, mX, mY);
  }
  boolean isHoverCenter(int mX, int mY) {
    return this.isHover(this.leftBank, mX, mY);
  }

  void display(PGraphics layer) {
    layer.noStroke();
    layer.fill(255, 0, 0);
    layer.circle(this.center.x, this.center.y, this.radius);
    layer.fill(0, 255, 0);
    layer.circle(this.rightBank.x, this.rightBank.y, this.radius);
    layer.fill(0, 0, 255);
    layer.circle(this.leftBank.x, this.leftBank.y, this.radius);
  }
}

class Ribon {
  float linearDensity;
  ArrayList<Vec2D[]> curves = new ArrayList<Vec2D[]>();
  RibonEndButtons frontButtons = null;
  RibonEndButtons backButtons = null;

  Ribon(float linearDensity) {
    this.linearDensity = linearDensity;
  }

  void addFirstCurve(ArrayList<Vec2D> curve) {
    this.addToBack(curve);
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
      this.frontButtons.display(layer);
      this.backButtons.display(layer);
    }
  }
}

class RibonEndPositions {
  int nw = 6, nh = 6;
  ArrayList<Ribon>[] ribons;
  int areaW, areaH;

  RibonEndPositions(int areaW, int areaH) {
    this.areaW = areaW;
    this.areaH = areaH;
    this.ribons = new ArrayList[this.nw * this.nh];
    for (int i = 0; i < this.ribons.length; i++) {
      this.ribons[i] = null;
    }
  }

  private int positionIndex (Vec2D position) {
    float normXpos = position.x / this.areaW;
    int xindex = floor(normXpos * this.nw);
    float normYpos = position.y / this.areaH;
    int yindex = floor(normYpos * this.nh);
    return xindex + this.nw * yindex;
  }

  private void placeRibonAt(int index, Ribon ribon) {
    if (this.ribons[index] == null) {
      this.ribons[index] = new ArrayList<Ribon>();
    }
    this.ribons[index].add(ribon);
  }

  ArrayList<Ribon> getRibonsAt(int mX, int mY) {
    int index = this.positionIndex(new Vec2D(mX, mY));
    if (this.ribons[index] != null) {
      return this.ribons[index];
    }
    return null;
  }

  void addRibon(Ribon ribon) {
    HashSet<Integer> indices = new HashSet<Integer>();
    indices.add(this.positionIndex(ribon.frontButtons.center));
    indices.add(this.positionIndex(ribon.frontButtons.leftBank));
    indices.add(this.positionIndex(ribon.frontButtons.rightBank));
    indices.add(this.positionIndex(ribon.backButtons.center));
    indices.add(this.positionIndex(ribon.backButtons.leftBank));
    indices.add(this.positionIndex(ribon.backButtons.rightBank));

    Iterator<Integer> it = indices.iterator();
    while(it.hasNext()) {
      this.placeRibonAt(it.next(), ribon);
    }
  }

  void addRibons(ArrayList<Ribon> ribons) {
    Iterator<Ribon> it = ribons.iterator();
    while(it.hasNext()) {
      this.addRibon(it.next());
    }
  }
}

PGraphics ribonsLayer, buttonsLayer, interactiveLayer;
float LINEAR_DENSITY = 1.0 / 10; // 1 point every 10 pixels
ArrayList<Ribon> ribons = new ArrayList<Ribon>();

void setup() {
  size(800, 800);
  noFill();
  ribonsLayer = createGraphics(width, height);
  buttonsLayer = createGraphics(width, height);
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

  image(ribonsLayer, 0, 0);
  image(buttonsLayer, 0, 0);
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

void printRibons() {
  ribonsLayer.beginDraw();
  ribonsLayer.clear();
  ribonsLayer.endDraw();
  Ribon currentRibon;
  for (int i = 0; i < ribons.size(); i++) {
    currentRibon = ribons.get(i);
    ribonsLayer.beginDraw();
    currentRibon.displayCurve(ribonsLayer);
    ribonsLayer.endDraw();
  }
}

void printRibonButtons() {
  Ribon currentRibon;
  buttonsLayer.beginDraw();
  buttonsLayer.clear();
  buttonsLayer.endDraw();
  for (int i = 0; i < ribons.size(); i++) {
    currentRibon = ribons.get(i);
    buttonsLayer.beginDraw();
    currentRibon.displayEndButtons(buttonsLayer);
    buttonsLayer.endDraw();
  }
}

void mouseReleased() {
  resampledCurve = densityResample(curve, 1.0 / 10);
  Ribon newRibon = new Ribon(LINEAR_DENSITY);
  newRibon.addFirstCurve(curve);
  newRibon.computeEndButtons(20);
  ribons.add(newRibon);

  ribonEndPositions = new RibonEndPositions(width, height);
  ribonEndPositions.addRibons(ribons);

  printRibons();
  printRibonButtons();
}