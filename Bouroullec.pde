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
    return this.isHover(this.rightBank, mX, mY);
  }
  boolean isHoverCenter(int mX, int mY) {
    return this.isHover(this.center, mX, mY);
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
  ArrayList<Vec2D[]> curves = new ArrayList<Vec2D[]>();
  ArrayList<Vec2D[]> normals = new ArrayList<Vec2D[]>();
  RibonEndButtons frontButtons = null,
                  backButtons = null;
  Ribon leftRibon = null,
        rightRibon = null;

  float ribonWid = 20.0;

  Ribon(Vec2D[] curve) {
    this.addToBack(curve);
  }

  void addToBack(Vec2D[] curve) {
    Vec2D[] processedCurve;

    int curvesLen = this.curves.size();
    if (curvesLen != 0) {
      Vec2D[] endCurve = this.curves.get(curvesLen - 1);
      Vec2D referencePoint = endCurve[endCurve.length - 1];
      Vec2D translation = referencePoint.sub(curve[0]);
      // translate
      processedCurve = new Vec2D[curve.length];
      for (int i = 0; i < curve.length; i++) {
        processedCurve[i] = curve[i].add(translation);
      }
    } else {
      processedCurve = curve;
    }

    this.normals.add(this.computeCurveNormals(processedCurve));
    this.curves.add(processedCurve);
  }

  void addToFront(Vec2D[] curve) {
    Vec2D translation = new Vec2D(0, 0);

    if (this.curves.size() != 0) {
      Vec2D[] frontCurve = this.curves.get(0);
      Vec2D referencePoint = frontCurve[0];
      translation = referencePoint.sub(curve[0]);
    }

    // Reverse and translate
    Vec2D[] processedCurve = new Vec2D[curve.length];
    for (int i = 0; i < curve.length; i++) {
      processedCurve[i] = curve[curve.length - i - 1].add(translation);
    }


    this.normals.add(0, this.computeCurveNormals(processedCurve));
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
        layer.circle(pos.x, pos.y, this.ribonWid / 10);
        layer.vertex(pos.x, pos.y);
      }
    }
    layer.endShape();
  }

  void displayNormals(PGraphics layer, int len) {
    int normalsLen = this.normals.size();
    Vec2D start, end;
    Vec2D[] currentNormals, currentCurve;

    for (int index = 0; index < normalsLen; index++) {
      currentNormals = this.normals.get(index);
      currentCurve = this.curves.get(index);
      for (int i = 0; i < currentNormals.length; i++) {
        start = currentCurve[i];
        end = start.add(currentNormals[i].getNormalizedTo(len));
        layer.line(start.x, start.y, end.x, end.y);
        layer.push();
        layer.fill(255, 0, 0);
        layer.noStroke();
        layer.circle(end.x, end.y, 3);
        layer.pop();
      }
    }
  }

  Ribon createLeftRibon(float linearDensity) {
    Ribon newRibon = null;
    for (int i = 0; i < this.curves.size(); i++) {
      Vec2D[] currentCurve = this.curves.get(i);
      Vec2D[] currentNormals = this.normals.get(i);
      Vec2D[] newCurve = new Vec2D[currentCurve.length];
      for (int index = 0; index < newCurve.length; index++) {
        newCurve[index] = currentCurve[index].copy().add(currentNormals[index].getNormalizedTo(this.ribonWid));
      }
      newCurve = densityResample(newCurve, linearDensity);

      if (newRibon == null) {
        newRibon = new Ribon(newCurve);
      } else {
        newRibon.addToBack(newCurve);
      }
    }

    return newRibon;
  }

  Ribon createRightRibon(float linearDensity) {
    Ribon newRibon = null;
    for (int i = 0; i < this.curves.size(); i++) {
      Vec2D[] currentCurve = this.curves.get(i);
      Vec2D[] currentNormals = this.normals.get(i);
      Vec2D[] newCurve = new Vec2D[currentCurve.length];
      for (int index = 0; index < newCurve.length; index++) {
        newCurve[index] = currentCurve[index].copy().sub(currentNormals[index].getNormalizedTo(this.ribonWid));
      }
      newCurve = densityResample(newCurve, linearDensity);

      if (newRibon == null) {
        newRibon = new Ribon(newCurve);
      } else {
        newRibon.addToBack(newCurve);
      }
    }

    return newRibon;
  }

  private Vec2D[] computeCurveNormals(Vec2D[] curve) {
    Vec2D[] curveNormals = new Vec2D[curve.length];
    curveNormals[0] = curve[0].sub(curve[1]).getRotated(HALF_PI).getNormalized();
    curveNormals[curve.length - 1] = curve[curve.length - 2].sub(curve[curve.length - 1]).getRotated(HALF_PI).getNormalized();
    for (int i = 1; i < curve.length - 1; i++) {
      curveNormals[i] = curve[i - 1].sub(curve[i + 1]).getRotated(HALF_PI).getNormalized();
    }

    return curveNormals;
  }

  void computeEndButtons() {
    int len = this.curves.size();
    Vec2D[] firstCurve = this.curves.get(0);
    Vec2D[] lastCurve = this.curves.get(len - 1);

    this.frontButtons = new RibonEndButtons();
    this.backButtons = new RibonEndButtons();

    this.frontButtons.center = firstCurve[0];
    this.frontButtons.leftBank = firstCurve[0].add(firstCurve[1].sub(firstCurve[0]).getRotated(-HALF_PI).getNormalizedTo(this.ribonWid / 2));
    this.frontButtons.rightBank = firstCurve[0].add(firstCurve[1].sub(firstCurve[0]).getRotated(HALF_PI).getNormalizedTo(this.ribonWid / 2));
    this.backButtons.rightBank = lastCurve[lastCurve.length - 1].add(lastCurve[lastCurve.length - 2].sub(lastCurve[lastCurve.length - 1]).getRotated(-HALF_PI).getNormalizedTo(this.ribonWid / 2));
    this.backButtons.leftBank = lastCurve[lastCurve.length - 1].add(lastCurve[lastCurve.length - 2].sub(lastCurve[lastCurve.length - 1]).getRotated(HALF_PI).getNormalizedTo(this.ribonWid / 2));
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
    if (index < 0) return;
    if (this.ribons[index] == null) {
      this.ribons[index] = new ArrayList<Ribon>();
    }
    this.ribons[index].add(ribon);
  }

  ArrayList<Ribon> getRibonsAt(int mX, int mY) {
    int index = this.positionIndex(new Vec2D(mX, mY));
    if (index < 0) return null;
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
    currentRibon.displayNormals(ribonsLayer, 10);
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

void addNewRibon(Ribon newRibon) {
  newRibon.computeEndButtons();
  ribons.add(newRibon);
  ribonEndPositions = new RibonEndPositions(width, height);
  ribonEndPositions.addRibons(ribons);
}

void mouseReleased() {
  float linearDensity = 1.0 / 20;
  Ribon newRibon;

  boolean drewCurve = curve.size() > 1;
  boolean emptyResample = false;
  if (drewCurve) {
    resampledCurve = densityResample(curve, linearDensity);
    emptyResample = resampledCurve.length <= 1;
  }

  if (!drewCurve || emptyResample) {
    ArrayList<Ribon> ribonsHere = ribonEndPositions.getRibonsAt(mouseX, mouseY);
    Ribon current;
    for (int i = 0; i < ribonsHere.size(); i++) {
      current = ribonsHere.get(i);
      if (current.frontButtons.isHoverLeftBank(mouseX, mouseY) || current.backButtons.isHoverLeftBank(mouseX, mouseY)) {
        println("clicked left button");
        newRibon = current.createLeftRibon(linearDensity);
        println(newRibon);
        addNewRibon(newRibon);
      }
      if (current.frontButtons.isHoverRightBank(mouseX, mouseY) || current.backButtons.isHoverRightBank(mouseX, mouseY)) {
        // return;
      };
    }
  }

  else if (!emptyResample) {
    newRibon = new Ribon(resampledCurve);
    addNewRibon(newRibon);

    // Ribon leftRibon = newRibon.createLeftRibon(linearDensity);
    // leftRibon.computeEndButtons();
    // ribons.add(leftRibon);

    // ribonEndPositions = new RibonEndPositions(width, height);
    // ribonEndPositions.addRibons(ribons);
  }

  printRibons();
  printRibonButtons();
}

void keyPressed() {
  if (key == ' ') {
    int date = (year() % 100) * 10000 + month() * 100 + day();
    int time = hour() * 10000 + minute() * 100 + second();
    saveFrame("out/date-"+ date + "_time-"+ time);
  }
}