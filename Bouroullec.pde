import toxi.geom.*;
import java.util.*;
import processing.svg.*;


ToolWindow toolWindow;
DisplayWindow displayWindow;
PrintWindow printWindow;
boolean SECONDARY_MONITOR = true;
int[] DISPLAY_WIN_SIZE = new int[]{1000, 1000};
int[] CANVAS_SIZE = new int[]{2100, 2970};
int[] DISPLAY_WIN_XY = SECONDARY_MONITOR ? new int[]{-400, -1200} : new int[]{100, 100};
int[] TOOL_WIN_SIZE = new int[]{200, 200};
int[] TOOL_WIN_XY = new int[]{DISPLAY_WIN_SIZE[0] + DISPLAY_WIN_XY[0] + 100, DISPLAY_WIN_XY[1]};
int[] PRINT_WIN_XY = new int[]{TOOL_WIN_SIZE[0] + TOOL_WIN_XY[0] + 100, DISPLAY_WIN_XY[1]};
int RIBON_WID = 5;

void setup() {
  // create the other windows
  toolWindow = new ToolWindow();
  displayWindow = new DisplayWindow(this.sketchPath(""));
  printWindow = new PrintWindow();
  // give other windows the correct folder location
  displayWindow.printWindow = printWindow;
  printWindow.displayWindow = displayWindow;
  this.surface.setVisible(false);
}

void draw() {noLoop();}

class PrintWindow extends PApplet {
  public String path = "";
  public PImage image = null;
  boolean showPosition = true;
  DisplayWindow displayWindow = null;
  private float currentResRatio = 1.0;
  boolean initialized = false;

  PrintWindow() {
    super();
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
  }

  void settings() {
    size(600, 600);
  }

  void setup() {
    this.surface.setLocation(PRINT_WIN_XY[0], PRINT_WIN_XY[1]);
    this.surface.setResizable(true);
  }

  public void setImage(PImage img) {
    this.image = img;
    float resRatio = (float)this.image.width / this.image.height;
    if (this.currentResRatio != resRatio) {
      this.currentResRatio = resRatio;
      if (resRatio > 1) {
        println("this.surface.setSize(this.width, round(this.height / resRatio));");
        this.surface.setSize(this.width, round(this.height / resRatio));
      } else {
        this.surface.setSize(round(this.width * resRatio), this.height);
      }
    }
    this.initialized = true;
    this.loop();
  }

  void draw() {
    this.background(255);
    if (!initialized) {
      push();
      textSize(30);
      textAlign(CENTER, CENTER);
      fill(0);
      text("Press P in display window", width / 2, height / 2);
      pop();
    }
    if (image != null) {
      this.image(this.image, 0, 0, this.width, this.height);
    }
    if (showPosition && this.displayWindow != null) {
      fill(0, 0, 0, 20);
      noStroke();
      rect(
        this.displayWindow.pos.x * this.width,
        this.displayWindow.pos.y * this.height,
        this.width * this.displayWindow.xRatio,
        this.height * this.displayWindow.yRatio
      );
    }
    this.noLoop();
  }

  void mouseMoved() {
    loop();
  }

  void keyPressed() {
    if (key == ' ') {
      this.showPosition = !this.showPosition;
    }
  }
}


class DisplayWindow extends PApplet {
  DisplayWindow(String path) {
    super();
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
    this.path = path;
  }

  Vec2D pos = new Vec2D(0, 0);
  float xRatio = 1.0;
  float yRatio = 1.0;
  int[] canvasSize = null;

  PrintWindow printWindow = null;
  private String path = "";
  ArrayList<Vec2D> curve = new ArrayList<Vec2D>();
  Vec2D[] resampledCurve = null;
  RibbonEndPositions ribbonEndPositions;
  PGraphics ribbonsLayer, buttonsLayer, interactiveLayer;
  final float LINEAR_DENSITY = 1.0 / 5; // 1 point every N pixels
  ArrayList<Ribbon> ribbons = new ArrayList<Ribbon>();

  // Processing methods

  void settings () {
    size(DISPLAY_WIN_SIZE[0], DISPLAY_WIN_SIZE[1]);
  }

  void setup() {
    noFill();
    this.surface.setLocation(DISPLAY_WIN_XY[0], DISPLAY_WIN_XY[1]);
    this.ribbonsLayer = createGraphics(CANVAS_SIZE[0], CANVAS_SIZE[1]);
    // initialize ribbonsLayer (hack)
    this.ribbonsLayer.beginDraw();
    this.ribbonsLayer.clear();
    this.ribbonsLayer.endDraw();
    //
    this.xRatio = (float)this.width / this.ribbonsLayer.width;
    this.yRatio = (float)this.height / this.ribbonsLayer.height;
    this.ribbonEndPositions = new RibbonEndPositions(ribbonsLayer.width, ribbonsLayer.height);
    this.buttonsLayer = createGraphics(ribbonsLayer.width, ribbonsLayer.height);
  }

  void printComposition () {
    this.printWindow.setImage(this.ribbonsLayer.get());
  }

  void clearCanvas () {
    this.ribbons = new ArrayList<Ribbon>();
    this.ribbonsLayer.beginDraw();
    this.ribbonsLayer.clear();
    this.ribbonsLayer.endDraw();
    this.buttonsLayer.beginDraw();
    this.buttonsLayer.clear();
    this.buttonsLayer.endDraw();
    this.ribbonEndPositions = new RibbonEndPositions(this.ribbonsLayer.width, this.ribbonsLayer.height);
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
    image(
      this.ribbonsLayer,
      - this.pos.x * this.ribbonsLayer.width,
      - this.pos.y * this.ribbonsLayer.height
    );
    image(
      this.buttonsLayer,
      - this.pos.x * this.buttonsLayer.width,
      - this.pos.y * this.buttonsLayer.height
    );
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

  void printAllRibbonsToSVG() {
    PGraphics svg = createGraphics(this.ribbonsLayer.width, this.ribbonsLayer.height, SVG, this.path + "output.svg");
    Ribbon[] allRibbons = this.ribbonEndPositions.getAllRibbons();
    svg.beginDraw();
    for (int i = 0; i < allRibbons.length; i++) {
      allRibbons[i].displayCurveSmooth(svg);
    }
    svg.dispose();
    svg.endDraw();
  }

  void printNewRibbon(Ribbon ribbon) {
    ribbonsLayer.beginDraw();
    ribbon.displayCurveSmooth(ribbonsLayer);
    ribbon.displayConnections(ribbonsLayer);
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

  Vec2D getCurrentTranslation() {
    return new Vec2D(this.pos.x * this.ribbonsLayer.width, this.pos.y * this.ribbonsLayer.height);
  }

  boolean isOverButton() {
    Vec2D currentTranslation = this.getCurrentTranslation();
    Vec2D mousePos = new Vec2D(mouseX + currentTranslation.x, mouseY + currentTranslation.y);
    ArrayList<Ribbon> ribbonsHere = ribbonEndPositions.getRibbonsAt(mousePos.x, mousePos.y);
    int nRibbonsHere = ribbonsHere != null ? ribbonsHere.size() : 0;
    Ribbon current;
    for (int i = 0; i < nRibbonsHere; i++) {
      current = ribbonsHere.get(i);
      if (current.isOverButton(mousePos.x, mousePos.y)) {
        return true;
      }
    }

    return false;
  }

  void extend() {
    Vec2D currentTranslation = this.getCurrentTranslation();
    Vec2D mousePos = new Vec2D(mouseX + currentTranslation.x, mouseY + currentTranslation.y);
    ArrayList<Ribbon> ribbonsHere = ribbonEndPositions.getRibbonsAt(mousePos.x, mousePos.y);
    Vec2D[] variationCurve = toolWindow.getYNormalizedCurve();
    Ribbon current, newRibbon;
    int nRibbonsHere = ribbonsHere != null ? ribbonsHere.size() : 0;
    for (int i = 0; i < nRibbonsHere; i++) {
      current = ribbonsHere.get(i);
      if (current.frontButtons.isHoverLeftBank(mousePos.x, mousePos.y) || current.backButtons.isHoverLeftBank(mousePos.x, mousePos.y)) {
        newRibbon = current.createLeftRibbon(this.LINEAR_DENSITY, variationCurve);
        if (newRibbon != null) {
          current.assignLeftRibbon(newRibbon);
          newRibbon.assignRightRibbon(current);
          if (current.hasRightBank()) {
            ribbonEndPositions.removeRibbon(current);
          }
          addNewRibbon(newRibbon);
          printNewRibbon(newRibbon);
          this.printRibbonButtons();
        }
      }
      if (current.frontButtons.isHoverRightBank(mousePos.x, mousePos.y) || current.backButtons.isHoverRightBank(mousePos.x, mousePos.y)) {
        newRibbon = current.createRightRibbon(this.LINEAR_DENSITY, variationCurve);
        if (newRibbon != null) {
          current.assignRightRibbon(newRibbon);
          newRibbon.assignLeftRibbon(current);
          if (current.hasLeftBank()) {
            ribbonEndPositions.removeRibbon(current);
          }
          addNewRibbon(newRibbon);
          printNewRibbon(newRibbon);
          this.printRibbonButtons();
        }
      };
    }
  }

  // Event methods

  boolean extending = false;

  void mouseDragged() {
    if (extending) {
      this.extend();
    } else {
      curve.add(new Vec2D(mouseX, mouseY));
    }
  }

  void mousePressed() {
    curve = new ArrayList<Vec2D>();
    extending = this.isOverButton();
    curve.add(new Vec2D(mouseX, mouseY));
  }

  Vec2D[] translateCurve(Vec2D[] curve, Vec2D translation) {
    Vec2D[] newCurve = new Vec2D[curve.length];
    for (int i = 0; i < curve.length; i++) {
      newCurve[i] = curve[i].add(translation);
    }
    return newCurve;
  }

  void mouseReleased() {
    extending = false;

    Ribbon newRibbon;

    boolean drewCurve = curve.size() > 1;
    boolean emptyResample = false;
    if (drewCurve) {
      resampledCurve = densityResample(curve, this.LINEAR_DENSITY);
      resampledCurve = translateCurve(resampledCurve, this.getCurrentTranslation());
      emptyResample = resampledCurve.length <= 1;
    }

    if (!drewCurve || emptyResample) {
      this.extend();
    } else if (!emptyResample) {
      newRibbon = new Ribbon(resampledCurve);
      addNewRibbon(newRibbon);
      printNewRibbon(newRibbon);
      this.printRibbonButtons();
    }
  }

  void keyPressed() {
    if (key == ' ') {
      int date = (year() % 100) * 10000 + month() * 100 + day();
      int time = hour() * 10000 + minute() * 100 + second();
      ribbonsLayer.save(path + "out/date-"+ date + "_time-"+ time + ".png");
    }
    if (key == 'e') {
      int date = (year() % 100) * 10000 + month() * 100 + day();
      int time = hour() * 10000 + minute() * 100 + second();
      ribbonsLayer.save(path + "out/autosave-date-"+ date + "_time-"+ time + ".png");
      this.clearCanvas();
    }
    if (key == 'p') {
      this.printComposition();
    }
    if (key == 's') {
      this.printAllRibbonsToSVG();
    }
    if(key == CODED) {
      if (keyCode == LEFT) {
        this.pos.x = this.pos.x - .1 >= 0 ? this.pos.x - .1 : 0;
      }
      if(keyCode == RIGHT) {
        this.pos.x = this.pos.x + .1 <= 1.0 - xRatio ? this.pos.x + .1 : 1.0 - xRatio;
      }
      if (keyCode == DOWN) {
        this.pos.y = this.pos.y - .1 >= 0 ? this.pos.y - .1 : 0;
      }
      if(keyCode == UP) {
        this.pos.y = this.pos.y + .1 <= 1.0 - yRatio ? this.pos.y + .1 : 1.0 - yRatio;
      }
    }
  }
}