import toxi.geom.*;
import java.util.*;


ToolWindow toolWindow;
DisplayWindow displayWindow;

boolean SECONDARY_MONITOR = true;
int[] DISPLAY_WIN_SIZE = new int[]{800, 800};
int[] TOOL_WIN_SIZE = new int[]{200, 200};
int[] DISPLAY_WIN_XY = SECONDARY_MONITOR ? new int[]{-400, -1200} : new int[]{100, 100};
int[] TOOL_WIN_XY = new int[]{DISPLAY_WIN_SIZE[0] + DISPLAY_WIN_XY[0] + 200, DISPLAY_WIN_XY[1] + 200};
int RIBON_WID = 4;

void setup() {
  // create the other windows
  toolWindow = new ToolWindow();
  displayWindow = new DisplayWindow();
  // give other windows the correct folder location
  displayWindow.path = this.sketchPath("");
  // hide main window
  this.surface.setVisible(false);
}

void draw() {noLoop();}

class DisplayWindow extends PApplet {
  DisplayWindow() {
    super();
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
  }

  public String path = "";
  ArrayList<Vec2D> curve = new ArrayList<Vec2D>();
  Vec2D[] resampledCurve = null;
  RibbonEndPositions ribbonEndPositions;
  PGraphics ribbonsLayer, buttonsLayer, interactiveLayer;
  final float LINEAR_DENSITY = 1.0 / 5; // 1 point every N pixels
  ArrayList<Ribbon> ribbons = new ArrayList<Ribbon>();

  // Processing methods

  void settings () {
    size(DISPLAY_WIN_SIZE[0], DISPLAY_WIN_SIZE[1]);
    smooth();
  }

  void setup() {
    noFill();
    this.surface.setLocation(DISPLAY_WIN_XY[0], DISPLAY_WIN_XY[1]);
    ribbonEndPositions = new RibbonEndPositions(width, height);
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

  void draw() {
    background(255);

    Vec2D pos;
    if (mousePressed && !extending) {
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

  // Sketch methods

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

  void printNewRibbon(Ribbon ribbon) {
    ribbonsLayer.beginDraw();
    ribbon.displayCurvePiecesSmoothBW(ribbonsLayer);
    ribbonsLayer.endDraw();
  }

  void printRibbonButtons() {
    Ribbon[] allRibbons = ribbonEndPositions.getAllRibbons();
    Ribbon currentRibbon;
    buttonsLayer.beginDraw();
    buttonsLayer.clear();
    for (int i = 0; i < allRibbons.length; i++) {
      currentRibbon = allRibbons[i];
      currentRibbon.displayEndButtons(buttonsLayer);
    }
    buttonsLayer.endDraw();
  }

  void addNewRibbon(Ribbon newRibbon) {
    ribbons.add(newRibbon);
    ribbonEndPositions.addRibbon(newRibbon);
  }

  boolean isOverButton() {
    ArrayList<Ribbon> ribbonsHere = ribbonEndPositions.getRibbonsAt(mouseX, mouseY);
    int nRibbonsHere = ribbonsHere != null ? ribbonsHere.size() : 0;
    Ribbon current;
    for (int i = 0; i < nRibbonsHere; i++) {
      current = ribbonsHere.get(i);
      if (current.isOverButton(mouseX, mouseY)) {
        return true;
      }
    }

    return false;
  }

  void extend() {
    ArrayList<Ribbon> ribbonsHere = ribbonEndPositions.getRibbonsAt(mouseX, mouseY);
    Vec2D[] variationCurve = toolWindow.getYNormalizedCurve();
    Ribbon current, newRibbon;
    int nRibbonsHere = ribbonsHere != null ? ribbonsHere.size() : 0;
    for (int i = 0; i < nRibbonsHere; i++) {
      current = ribbonsHere.get(i);
      if (current.frontButtons.isHoverLeftBank(mouseX, mouseY) || current.backButtons.isHoverLeftBank(mouseX, mouseY)) {
        newRibbon = current.createLeftRibbon(this.LINEAR_DENSITY, variationCurve);
        if (newRibbon != null) {
          current.assignLeftRibbon(newRibbon);
          newRibbon.assignRightRibbon(current);
          if (!current.hasRightBank()) {
            ribbonEndPositions.removeRibbon(current);
          }
          addNewRibbon(newRibbon);
          printNewRibbon(newRibbon);
        }
      }
      if (current.frontButtons.isHoverRightBank(mouseX, mouseY) || current.backButtons.isHoverRightBank(mouseX, mouseY)) {
        newRibbon = current.createRightRibbon(this.LINEAR_DENSITY, variationCurve);
        if (newRibbon != null) {
          current.assignRightRibbon(newRibbon);
          newRibbon.assignLeftRibbon(current);
          if (!current.hasLeftBank()) {
            ribbonEndPositions.removeRibbon(current);
          }
          addNewRibbon(newRibbon);
          printNewRibbon(newRibbon);
        }
      };
    }
  }

  // Event methods

  boolean extending = false;

  void mouseDragged() {
    if (extending) {
      this.extend();
      this.printRibbonButtons();
    } else {
      curve.add(new Vec2D(mouseX, mouseY));
    }
  }

  void mousePressed() {
    curve = new ArrayList<Vec2D>();
    extending = this.isOverButton();
    curve.add(new Vec2D(mouseX, mouseY));
  }

  void mouseReleased() {
    extending = false;

    Ribbon newRibbon;

    boolean drewCurve = curve.size() > 1;
    boolean emptyResample = false;
    if (drewCurve) {
      resampledCurve = densityResample(curve, this.LINEAR_DENSITY);
      emptyResample = resampledCurve.length <= 1;
    }

    if (!drewCurve || emptyResample) {
      this.extend();
    } else if (!emptyResample) {
      newRibbon = new Ribbon(resampledCurve);
      addNewRibbon(newRibbon);
      printNewRibbon(newRibbon);
    }

    printRibbonButtons();
  }

  void keyPressed() {
    if (key == ' ') {
      int date = (year() % 100) * 10000 + month() * 100 + day();
      int time = hour() * 10000 + minute() * 100 + second();
      ribbonsLayer.save(path + "out/date-"+ date + "_time-"+ time + ".png");
    }
  }
}