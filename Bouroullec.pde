import toxi.geom.*;
import java.util.*;
import processing.svg.*;


ToolWindow toolWindow;
DisplayWindow displayWindow;
// PrintWindow printWindow;
boolean SECONDARY_MONITOR = false;
int[] CANVAS_SIZE = new int[]{2100 / 3, 2970 / 3};
int[] DISPLAY_WIN_SIZE = new int[]{2100 / 3, 2970 / 3};
int[] DISPLAY_WIN_XY = SECONDARY_MONITOR ? new int[]{600, -2000} : new int[]{50, 50};
int[] TOOL_WIN_SIZE = new int[]{200, 200};
int[] TOOL_WIN_XY = new int[]{DISPLAY_WIN_SIZE[0] + DISPLAY_WIN_XY[0], DISPLAY_WIN_XY[1]};
int[] PRINT_WIN_XY = new int[]{DISPLAY_WIN_SIZE[0] + DISPLAY_WIN_XY[0], DISPLAY_WIN_XY[1] + TOOL_WIN_SIZE[1] + 50};
int RIBON_WID = 1;
color WINDOW_BACKROUNG_COLOR = 0xffffffff;
color MOUSE_STROKE_COLOR = 0xff000000;
float RIBBON_GAP_FACTOR = 3.0;
float DISPLAY_WINDOW_LINEAR_DENSITY = 1.0 / 10.0; // 1 point every N pixels
color[] colors = new color[] {
  // red
  // 0xaaff0000,
  // orange
  // 0xaaffa500,
  // yellow
  // 0xaaffff00,
  // green
  // 0xaa008000,
  // blue
  // 0xaa0000ff,
  // indigo
  // 0xaa4b0082,
  // violet
  // 0xaaee82ee
  // white
  // 0xffffffff
  // black
  0xff000000
};
int lastRibbonColorIndex = 0;

enum Mode {
  DRAW, EXTEND
}

class CurrentMode {
  private Mode currentMode;

  CurrentMode () {
    this.reset();
  }

  void change() {
    if (this.currentMode == Mode.DRAW) {
      this.currentMode = Mode.EXTEND;
    } else {
      this.currentMode = Mode.DRAW;
    }
  }

  void reset() {
    this.currentMode = Mode.DRAW;
  }

  Mode current() {
    return this.currentMode;
  }
}

enum ControlKeys {
  COLOR('c'),
  PRINT_PNG('p'),
  PRINT_SVG('s'),
  ERASE('e');

  private char key;

  ControlKeys(char key) {
    this.key = key;
  }

  public char getKey() {
    return key;
  }
}

void setup() {
  // create the other windows
  pixelDensity(2);
  toolWindow = new ToolWindow();
  displayWindow = new DisplayWindow(this.sketchPath(""));
  // printWindow = new PrintWindow();
  // // give other windows the correct folder location
  // displayWindow.printWindow = printWindow;
  // printWindow.displayWindow = displayWindow;
  this.surface.setVisible(false);
}

void draw() {noLoop();}

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
  private float scale = 1.0;
  CurrentMode mode = new CurrentMode();

  // PrintWindow printWindow = null;
  private String path = "";
  ArrayList<Vec2D> curve = new ArrayList<Vec2D>();
  Vec2D[] resampledCurve = null;
  RibbonMemory ribbonMemory;
  PGraphics ribbonsLayer, buttonsLayer, interactiveLayer;
  final float LINEAR_DENSITY = DISPLAY_WINDOW_LINEAR_DENSITY;

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
    this.scale = 1.0 / xRatio;
    this.ribbonMemory = new RibbonMemory();
    this.buttonsLayer = createGraphics(ribbonsLayer.width, ribbonsLayer.height);
  }

  // void printComposition () {
  //   if (this.printWindow != null) {
  //     this.printWindow.setImage(this.ribbonsLayer.get());
  //   }
  // }

  void clearCanvas () {
    this.ribbonsLayer.beginDraw();
    this.ribbonsLayer.clear();
    this.ribbonsLayer.endDraw();
    this.buttonsLayer.beginDraw();
    this.buttonsLayer.clear();
    this.buttonsLayer.endDraw();
    this.ribbonMemory = new RibbonMemory();
    this.mode.reset();
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
    this.background(WINDOW_BACKROUNG_COLOR);

    Vec2D pos;
    if (mousePressed && !extending) {
      stroke(MOUSE_STROKE_COLOR);
      beginShape();
      for (int i = 0; i < curve.size(); i++) {
        pos = curve.get(i);
        circle(pos.x, pos.y, 5);
        vertex(pos.x, pos.y);
      }
      endShape();
    }
    // image(
    //   this.ribbonsLayer,
    //   - this.pos.x * this.ribbonsLayer.width,
    //   - this.pos.y * this.ribbonsLayer.height
    // );
    // image(
    //   this.buttonsLayer,
    //   - this.pos.x * this.buttonsLayer.width,
    //   - this.pos.y * this.buttonsLayer.height
    // );
    image(this.ribbonsLayer, 0, 0, width, height);
    if (this.mode.current() == Mode.EXTEND) {
      this.printRibbonButtons();
      image(this.buttonsLayer, 0, 0, width, height);
    }

    Vec2D currentTranslation = this.getCurrentTranslation();
    Vec2D mousePos = new Vec2D(mouseX + currentTranslation.x, mouseY + currentTranslation.y).scale(this.scale);
    // Draw red circle around mouse
    stroke(255, 0, 0);
    circle(mousePos.x, mousePos.y, 5);
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
    int date = (year() % 100) * 10000 + month() * 100 + day();
    int time = hour() * 10000 + minute() * 100 + second();
    PGraphics svg = createGraphics(this.ribbonsLayer.width, this.ribbonsLayer.height, SVG, this.path + "out/date-"+ date + "_time-"+ time + ".svg");
    Ribbon[] allRibbons = this.ribbonMemory.getAllRibbons();
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
    // ribbon.displayConnections(ribbonsLayer);
    ribbonsLayer.endDraw();
  }

  void printRibbonButtons() {
    Ribbon[] allRibbons = ribbonMemory.getAllRibbons();
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
    ribbonMemory.addRibbon(newRibbon);
  }

  Vec2D getCurrentTranslation() {
    return new Vec2D(this.pos.x * this.ribbonsLayer.width, this.pos.y * this.ribbonsLayer.height);
  }

  boolean isOverButton() {
    Vec2D currentTranslation = this.getCurrentTranslation();
    Vec2D mousePos = new Vec2D(mouseX + currentTranslation.x, mouseY + currentTranslation.y).scale(this.scale);
    return this.ribbonMemory.isOverButton(mousePos) != null;
  }

  void extend() {
    Vec2D currentTranslation = this.getCurrentTranslation();
    Vec2D mousePos = new Vec2D(mouseX + currentTranslation.x, mouseY + currentTranslation.y).scale(this.scale);
    Ribbon current = ribbonMemory.isOverButton(mousePos);
    if (current == null) {
      return;
    }

    Vec2D[] variationCurve = toolWindow.getYNormalizedCurve();
    float linearDensity = this.LINEAR_DENSITY;
    Ribbon newRibbon = current.extend(mousePos, variationCurve, linearDensity);
    if (newRibbon != null) {
      addNewRibbon(newRibbon);
      printNewRibbon(newRibbon);
    }
  }

  // Event methods

  boolean extending = false;

  void mouseDragged() {
    if (this.mode.current() == Mode.EXTEND) {
      if (this.isOverButton()) {
        this.extend();
      }
    } else if (this.mode.current() != Mode.EXTEND) {
      curve.add(new Vec2D(mouseX, mouseY));
    }
  }

  void mouseMoved() {
    if (this.mode.current() == Mode.EXTEND) {
      if (this.isOverButton()) {
        cursor(HAND);
      } else {
        cursor(ARROW);
      }
    }
  }

  void mousePressed() {
    curve = new ArrayList<Vec2D>();
    if (this.mode.current() != Mode.EXTEND) {
      curve.add(new Vec2D(mouseX, mouseY));
    }
  }

  Vec2D[] translateCurve(Vec2D[] curve, Vec2D translation) {
    Vec2D[] newCurve = new Vec2D[curve.length];
    for (int i = 0; i < curve.length; i++) {
      newCurve[i] = curve[i].add(translation);
    }
    return newCurve;
  }

  Vec2D[] rescaleCurve(Vec2D[] curve, float scale) {
    Vec2D[] newCurve = new Vec2D[curve.length];
    for (int i = 0; i < curve.length; i++) {
      newCurve[i] = curve[i].scale(scale);
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
      resampledCurve = rescaleCurve(resampledCurve, this.scale);
      emptyResample = resampledCurve.length <= 1;
    }

    if (!drewCurve || emptyResample) {
      this.extend();
    } else if (!emptyResample) {
      newRibbon = new Ribbon(resampledCurve);
      newRibbon.col = colors[lastRibbonColorIndex];
      lastRibbonColorIndex = (lastRibbonColorIndex + 1) % colors.length;
      addNewRibbon(newRibbon);
      printNewRibbon(newRibbon);
      this.printRibbonButtons();
    }
  }

  void keyPressed() {
    if (key == ControlKeys.ERASE.getKey()) {
      int date = (year() % 100) * 10000 + month() * 100 + day();
      int time = hour() * 10000 + minute() * 100 + second();
      ribbonsLayer.save(path + "out/autosave-date-"+ date + "_time-"+ time + ".png");
      this.clearCanvas();
    }
    if (key == ControlKeys.PRINT_PNG.getKey()) {
      int date = (year() % 100) * 10000 + month() * 100 + day();
      int time = hour() * 10000 + minute() * 100 + second();
      ribbonsLayer.save(path + "out/date-"+ date + "_time-"+ time + ".png");
    }
    // if (key == ControlKeys.SHOW_ON_PRINT_DISPLAY.getKey()) {
    //   this.printComposition();
    // }
    if (key == ControlKeys.PRINT_SVG.getKey()) {
      this.printAllRibbonsToSVG();
    }
    if(key == ControlKeys.COLOR.getKey()) {
      lastRibbonColorIndex = (lastRibbonColorIndex + 1) % colors.length;
    }

    if(keyCode == TAB) {
      println("tab");
      this.mode.change();
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
