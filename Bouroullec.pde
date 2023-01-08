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
float RIBBON_GAP_FACTOR = 1.5;
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
  DRAW, EXTEND, SELECT_RIBBON
}

class CurrentMode {
  private Mode currentMode;

  CurrentMode () {
    this.reset();
  }

  void change() {
    if (this.currentMode == Mode.DRAW) {
      this.currentMode = Mode.EXTEND;
    } else if (this.currentMode == Mode.EXTEND) {
      this.currentMode = Mode.SELECT_RIBBON;
    } else if (this.currentMode == Mode.SELECT_RIBBON) {
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
  PGraphics ribbonsLayer, interactiveLayer;
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
    this.interactiveLayer = createGraphics(ribbonsLayer.width, ribbonsLayer.height);
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
    this.interactiveLayer.beginDraw();
    this.interactiveLayer.clear();
    this.interactiveLayer.endDraw();
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

    image(this.ribbonsLayer, 0, 0, width, height);

    if (this.mode.current() == Mode.EXTEND) {
      this.printRibbonButtons();
      image(this.interactiveLayer, 0, 0, width, height);
    }

    if (this.mode.current() == Mode.SELECT_RIBBON) {
      this.printSelectedRibbon();
      image(this.interactiveLayer, 0, 0, width, height);
    }

    Vec2D currentTranslation = this.getCurrentTranslation();
    Vec2D mousePos = new Vec2D(mouseX + currentTranslation.x, mouseY + currentTranslation.y).scale(this.scale);
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
    Ribbon[] allRibbons = this.ribbonMemory.getOrderedRibbonsForPlotter();
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
    interactiveLayer.beginDraw();
    interactiveLayer.clear();
    for (int i = 0; i < allRibbons.length; i++) {
      currentRibbon = allRibbons[i];
      currentRibbon.displayEndButtons(interactiveLayer);
    }
    interactiveLayer.endDraw();
  }

  void printSelectedRibbon() {
    Ribbon selectedRibbon = this.ribbonMemory.getSelectedRibbon();
    interactiveLayer.beginDraw();
    interactiveLayer.clear();
    if (selectedRibbon != null) {
      selectedRibbon.displayCurveSmooth(this.interactiveLayer);
    }
    // Draw red circle around mouse
    interactiveLayer.stroke(255, 0, 0);
    interactiveLayer.circle(mouseX, mouseY, 5);
    interactiveLayer.endDraw();
  }

  void addNewRibbon(Ribbon newRibbon) {
    ribbonMemory.addRibbon(newRibbon);
  }

  Vec2D getCurrentTranslation() {
    return new Vec2D(this.pos.x * this.ribbonsLayer.width, this.pos.y * this.ribbonsLayer.height);
  }

  Vec2D getMousePos() {
    Vec2D currentTranslation = this.getCurrentTranslation();
    return new Vec2D(mouseX + currentTranslation.x, mouseY + currentTranslation.y).scale(this.scale);
  }

  Ribbon isOverButton() {
    return this.isOverButton(this.getMousePos());
  }

  Ribbon isOverButton(Vec2D position) {
    return this.ribbonMemory.isOverButton(position);
  }

  void extend(Ribbon current) {
    Vec2D[] variationCurve = toolWindow.getYNormalizedCurve();
    float linearDensity = this.LINEAR_DENSITY;
    Ribbon newRibbon = current.extend(this.getMousePos(), variationCurve, linearDensity);
    if (newRibbon != null) {
      addNewRibbon(newRibbon);
      printNewRibbon(newRibbon);
    }
  }

  // Event methods

  boolean extending = false;

  void mouseDragged() {
    Mode currentMode = this.mode.current();
    if (currentMode == Mode.EXTEND) {
      Ribbon currentRibbon = this.isOverButton();
      if (currentRibbon != null) this.extend(currentRibbon);
    } else if (currentMode == Mode.DRAW) {
      curve.add(new Vec2D(mouseX, mouseY));
    }
  }

  void mouseMoved() {
    Mode currentMode = this.mode.current();
    if (currentMode == Mode.EXTEND) {
      if (this.isOverButton() != null) {
        cursor(HAND);
      } else {
        cursor(ARROW);
      }
    } else if (currentMode == Mode.SELECT_RIBBON) {
      Ribbon currentRibbon = this.ribbonMemory.isOverRibbon(this.getMousePos(), 10);
      this.ribbonMemory.selectRibbon(currentRibbon);
    }
  }

  void mousePressed() {
    curve = new ArrayList<Vec2D>();
    if (this.mode.current() == Mode.DRAW) {
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
    if (drewCurve) {
      resampledCurve = densityResample(curve, this.LINEAR_DENSITY);
      resampledCurve = translateCurve(resampledCurve, this.getCurrentTranslation());
      resampledCurve = rescaleCurve(resampledCurve, this.scale);
      if (resampledCurve.length > 1) {
        newRibbon = new Ribbon(resampledCurve);
        newRibbon.col = colors[lastRibbonColorIndex];
        lastRibbonColorIndex = (lastRibbonColorIndex + 1) % colors.length;
        addNewRibbon(newRibbon);
        printNewRibbon(newRibbon);
        this.printRibbonButtons();
      }
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
