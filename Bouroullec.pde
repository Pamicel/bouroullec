import toxi.geom.*;
import java.util.*;


ToolWindow toolWindow;
DisplayWindow displayWindow;

void setup() {
  toolWindow = new ToolWindow();
  displayWindow = new DisplayWindow();
  this.surface.setLocation(200, 200);
}

void draw() {noLoop();}

class DisplayWindow extends PApplet {
  DisplayWindow() {
    super();
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
  }

  ArrayList<Vec2D> curve = new ArrayList<Vec2D>();
  Vec2D[] resampledCurve = null;
  RibonEndPositions ribonEndPositions;
  PGraphics ribonsLayer, buttonsLayer, interactiveLayer;
  float LINEAR_DENSITY = 1.0 / 10; // 1 point every 10 pixels
  ArrayList<Ribon> ribons = new ArrayList<Ribon>();

  void settings () {
    size(800, 800);
  }

  void setup() {
    noFill();
    this.surface.setLocation(100, 100);
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
      Vec2D[] variationCurve = toolWindow.getYNormalizedCurve();
      Ribon current;
      int nRibonsHere = ribonsHere != null ? ribonsHere.size() : 0;
      for (int i = 0; i < nRibonsHere; i++) {
        current = ribonsHere.get(i);
        if (current.frontButtons.isHoverLeftBank(mouseX, mouseY) || current.backButtons.isHoverLeftBank(mouseX, mouseY)) {
          newRibon = current.createLeftRibon(linearDensity, variationCurve);
          addNewRibon(newRibon);
        }
        if (current.frontButtons.isHoverRightBank(mouseX, mouseY) || current.backButtons.isHoverRightBank(mouseX, mouseY)) {
          newRibon = current.createRightRibon(linearDensity, variationCurve);
          addNewRibon(newRibon);
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
}