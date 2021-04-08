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
  RibbonEndPositions ribbonEndPositions;
  PGraphics ribbonsLayer, buttonsLayer, interactiveLayer;
  final float LINEAR_DENSITY = 1.0 / 2; // 1 point every N pixels
  ArrayList<Ribbon> ribbons = new ArrayList<Ribbon>();

  void settings () {
    size(800, 800);
  }

  void setup() {
    noFill();
    this.surface.setLocation(100, 100);
    ribbonsLayer = createGraphics(width, height);
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

    image(ribbonsLayer, 0, 0);
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

  void printRibbons() {
    ribbonsLayer.beginDraw();
    ribbonsLayer.clear();
    ribbonsLayer.endDraw();
    Ribbon currentRibbon;
    for (int i = 0; i < ribbons.size(); i++) {
      currentRibbon = ribbons.get(i);
      ribbonsLayer.beginDraw();
      currentRibbon.displayCurve(ribbonsLayer);
      ribbonsLayer.endDraw();
    }
  }

  void printNewRibbon(Ribbon ribbon) {
    ribbonsLayer.beginDraw();
    ribbon.displayCurve(ribbonsLayer);
    ribbonsLayer.endDraw();
  }

  void printRibbonButtons() {
    Ribbon currentRibbon;
    buttonsLayer.beginDraw();
    buttonsLayer.clear();
    buttonsLayer.endDraw();
    for (int i = 0; i < ribbons.size(); i++) {
      currentRibbon = ribbons.get(i);
      buttonsLayer.beginDraw();
      currentRibbon.displayEndButtons(buttonsLayer);
      buttonsLayer.endDraw();
    }
  }

  void addNewRibbon(Ribbon newRibbon) {
    ribbons.add(newRibbon);
    ribbonEndPositions = new RibbonEndPositions(width, height);
    ribbonEndPositions.addRibbons(ribbons);
  }

  void mouseReleased() {
    float linearDensity = this.LINEAR_DENSITY;
    Ribbon newRibbon;

    boolean drewCurve = curve.size() > 1;
    boolean emptyResample = false;
    if (drewCurve) {
      resampledCurve = densityResample(curve, linearDensity);
      emptyResample = resampledCurve.length <= 1;
    }

    if (!drewCurve || emptyResample) {
      ArrayList<Ribbon> ribbonsHere = ribbonEndPositions.getRibbonsAt(mouseX, mouseY);
      Vec2D[] variationCurve = toolWindow.getYNormalizedCurve();
      Ribbon current;
      int nRibbonsHere = ribbonsHere != null ? ribbonsHere.size() : 0;
      for (int i = 0; i < nRibbonsHere; i++) {
        current = ribbonsHere.get(i);
        if (current.frontButtons.isHoverLeftBank(mouseX, mouseY) || current.backButtons.isHoverLeftBank(mouseX, mouseY)) {
          newRibbon = current.createLeftRibbon(linearDensity, variationCurve);
          current.assignLeftRibbon(newRibbon);
          newRibbon.assignRightRibbon(current);
          addNewRibbon(newRibbon);
          printNewRibbon(newRibbon);
        }
        if (current.frontButtons.isHoverRightBank(mouseX, mouseY) || current.backButtons.isHoverRightBank(mouseX, mouseY)) {
          newRibbon = current.createRightRibbon(linearDensity, variationCurve);
          current.assignRightRibbon(newRibbon);
          newRibbon.assignLeftRibbon(current);
          addNewRibbon(newRibbon);
          printNewRibbon(newRibbon);
        };
      }
    }

    else if (!emptyResample) {
      newRibbon = new Ribbon(resampledCurve);
      addNewRibbon(newRibbon);
      printNewRibbon(newRibbon);

      // Ribbon leftRibbon = newRibbon.createLeftRibbon(linearDensity);
      // leftRibbon.computeEndButtons();
      // ribbons.add(leftRibbon);

      // ribbonEndPositions = new RibbonEndPositions(width, height);
      // ribbonEndPositions.addRibbons(ribbons);
    }

    printRibbonButtons();
  }

  void keyPressed() {
    if (key == ' ') {
      int date = (year() % 100) * 10000 + month() * 100 + day();
      int time = hour() * 10000 + minute() * 100 + second();
      saveFrame("out/date-"+ date + "_time-"+ time);
    }
  }
}