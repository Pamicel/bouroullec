// Subwindow
class Subwindow {
  PGraphics swLayer;
  int x, y, w, h;
  PApplet window;
  HashMap<String, PGraphics> namedLayers = new HashMap<String, PGraphics>();
  ArrayList<PGraphics> layers = new ArrayList<PGraphics>();
  // constructor
  Subwindow(PApplet window, int x, int y, int w, int h) {
    this.window = window;
    this.setPositionInWindow(x, y);
    this.setSubwindowSize(w, h);
  }

  PGraphics pushLayer(String name, int w, int h) {
    PGraphics layer = this.window.createGraphics(this.w, this.h);
    // Add layer to the array of layers
    this.layers.add(layer);
    return layer;
  }

  void printLayers() {
    window.clear();
    // draw layers in the order they were added
    for (int i = 0; i < this.layers.size(); i++) {
      PGraphics layer = this.layers.get(i);
      // draw the layer to the subwindow
      window.image(layer, this.x, this.y);
    }
  }

  void setPositionInWindow(int x, int y) {
    this.x = x;
    this.y = y;
  }

  void setSubwindowSize(int w, int h) {
    this.w = w;
    this.h = h;
  }

  // Is x,y in subwindow?
  boolean contains(int x, int y) {
    return (x > this.x && x < this.x + this.w && y > this.y && y < this.y + this.h);
  }

  // Draw subwindow
  void draw() {
    this.printLayers();
  }
}

// Curve subwindow
class CurveSubwindow extends Subwindow {
  // constructor
  CurveSubwindow(PApplet window, int x, int y, int w, int h, int padding) {
    super(window, x, y, w, h);
    this.width = w;
    this.height = h;
    this.padding = padding;
    this.xmin = this.padding;
    this.xmax = this.width - this.padding;
    this.ymax = 3 * this.height / 4;
    this.ymin = this.height / 4;
    this.ygap = this.ymax - this.ymin;
    this.backgroundLayer = this.pushLayer("backgroundLayer", this.width, this.height);
    this.guidesLayer = this.pushLayer("guidesLayer", this.width, this.height);
    this.finalCurveLayer = this.pushLayer("finalCurveLayer", this.width, this.height);
    this.drawingLayer = this.pushLayer("drawingLayer", this.width, this.height);
  }

  ArrayList<Vec2D> curve = new ArrayList<Vec2D>();
  Vec2D[] finalCurve = null;
  PGraphics finalCurveLayer, drawingLayer, backgroundLayer, guidesLayer;
  float linearDensity = 1.0 / 5;
  int xmin, xmax, padding;
  int ymin, ymax, ymid, ygap;
  boolean isDrawing = false;
  int width, height;

  private int curveDirection(ArrayList<Vec2D> curve) {
    Vec2D curveFirstPoint = curve.get(0);
    Vec2D curveLastPoint = curve.get(curve.size() - 1);
    return curveLastPoint.x > curveFirstPoint.x ? 1 : -1;
  }

  boolean canAddPointToCurve(Vec2D point) {
    int curveLen = this.curve.size();

    // good if first point
    if (curveLen == 0) return true;

    Vec2D curveFirstPoint = this.curve.get(0);

    // good if second point and different from first point
    if (curveLen == 1) return curveFirstPoint.x != point.x;

    Vec2D curveLastPoint = this.curve.get(curveLen - 1);
    boolean pointOnRight = point.x > curveLastPoint.x;
    boolean curveGoesForward = this.curveDirection(this.curve) == 1;

    return (curveGoesForward && pointOnRight) // the curve goes forwards and the point is on the right
            || (!curveGoesForward && !pointOnRight); // the curve goes backwards and the point is on the left
  }

  void addPointToCurve (Vec2D point) {
    if (this.canAddPointToCurve(point)) {
      this.curve.add(point);
    }
  }

  void resetCurve () {
    this.curve = new ArrayList<Vec2D>();
  }

  void saveFinalCurve() {
    ArrayList<Vec2D> shavedCurve = new ArrayList<Vec2D>();
    Vec2D currentPoint, nextPoint;
    boolean ltZero;
    boolean gtOne;
    int curveLen = this.curve.size();
    int curveDirection = this.curveDirection(this.curve);

    // Make the curve go forward
    if (curveDirection == -1) {
      ArrayList<Vec2D> reversed = new ArrayList<Vec2D>();
      for (int i = 0; i < curveLen; i++) {
        reversed.add(this.curve.get(curveLen - i - 1));
      }
      this.curve = reversed;
    }

    // remove unused points
    float minX = this.padding;
    float maxX = this.width - this.padding;
    for (int i = 0; i < curveLen; i++) {
      currentPoint = this.curve.get(i);
      nextPoint = i + 1 < curveLen ? this.curve.get(i + 1) : null;
      if (nextPoint != null) {
        boolean crossingMin = currentPoint.x < minX && nextPoint.x > minX;
        boolean crossingMax = currentPoint.x < maxX && nextPoint.x > maxX;
        if (crossingMin || crossingMax) {
          float crossingX = crossingMin ? minX : maxX;
          float newPointY = (crossingX - currentPoint.x) / (nextPoint.x - currentPoint.x) * (nextPoint.y - nextPoint.y) + currentPoint.y;
          Vec2D newPoint = new Vec2D(crossingX, newPointY);
          currentPoint = newPoint;
        }
      }
      ltZero = currentPoint.x < this.padding;
      gtOne = currentPoint.x > this.width - this.padding;
      if (!ltZero && !gtOne) {
        shavedCurve.add(currentPoint);
      }
    }

    // if no point remains, nothing to do, return
    if (shavedCurve.size() <= 1) {
      return;
    }

    // make sure first and last points are at minX and maxX
    Vec2D firstPoint = shavedCurve.get(0);
    Vec2D lastPoint = shavedCurve.get(shavedCurve.size() - 1);
    if (firstPoint.x > minX) {
      shavedCurve.add(0, new Vec2D(minX, firstPoint.y));
    }
    if (lastPoint.x < maxX) {
      shavedCurve.add(new Vec2D(maxX, lastPoint.y));
    }

    this.finalCurve = densityResample(shavedCurve, this.linearDensity);
  }

  Vec2D[] getYNormalizedCurve() {
    if (this.finalCurve == null) {
      return null;
    }
    Vec2D[] yNormalizedCurve = new Vec2D[this.finalCurve.length];
    for(int i = 0; i < this.finalCurve.length; i++) {
      yNormalizedCurve[i] = new Vec2D(0, (- this.finalCurve[i].y + this.ymin) / (this.ygap / 2));
    }

    return yNormalizedCurve;
  }

  void printFinalCurve(PGraphics layer) {
    layer.beginDraw();
    layer.clear();
    layer.noFill();
    layer.stroke(0);
    layer.strokeWeight(1);
    if (this.finalCurve != null) {
      layer.beginShape();
      for (int i = 0; i < this.finalCurve.length; i++) {
        layer.vertex(this.finalCurve[i].x, this.finalCurve[i].y);
        layer.circle(this.finalCurve[i].x, this.finalCurve[i].y, 5);
      }
      layer.endShape();
    }
    layer.endDraw();
  }

  void printDrawing(PGraphics layer) {
    layer.beginDraw();
    layer.clear();
    layer.noFill();
    layer.stroke(0);
    layer.strokeWeight(1);
    if (this.curve.size() > 1) {
      layer.beginShape();
      for (int i = 0; i < this.curve.size(); i++) {
        layer.vertex(this.curve.get(i).x, this.curve.get(i).y);
        layer.circle(this.curve.get(i).x, this.curve.get(i).y, 5);
      }
      layer.endShape();
    }
    layer.endDraw();
  }

  void printGuides(PGraphics layer) {
    layer.beginDraw();
    layer.clear();
    layer.noFill();
    layer.stroke(0);
    layer.strokeWeight(1);
    layer.line(this.padding, 0, this.padding, this.height);
    layer.line(this.width - this.padding, 0, this.width - this.padding, this.height);
    layer.line(this.padding, this.height / 2, this.width - this.padding, this.height / 2);
    layer.line(this.padding, this.ymin, this.width - this.padding, this.ymin);
    layer.line(this.padding, this.ymax, this.width - this.padding, this.ymax);
    layer.endDraw();
  }

  void printBackground(PGraphics layer) {
    layer.beginDraw();
    layer.clear();
    layer.background(255);
    layer.endDraw();
  }

  void clearLayer(PGraphics layer) {
    layer.beginDraw();
    layer.clear();
    layer.endDraw();
  }

  void printAll() {
    // Draw background
    this.printBackground(this.backgroundLayer);
    // Draw guides
    this.printGuides(this.guidesLayer);
    // Draw the curve that is being drawn
    if (this.isDrawing) {
      this.printDrawing(this.drawingLayer);
    } else {
      this.printFinalCurve(this.finalCurveLayer);
    }
  }

  void draw() {
    this.printAll();
    super.draw();
  }

  void mouseDragged(
    int mouseX,
    int mouseY
  ) {
    if (this.isDrawing) {
      this.addPointToCurve(new Vec2D(mouseX, mouseY));
    }
  }

  void mousePressed(
    int mouseX,
    int mouseY
  ) {
    if (this.contains(mouseX, mouseY) && !this.isDrawing) {
      this.resetCurve();
      this.addPointToCurve(new Vec2D(mouseX, mouseY));
      this.isDrawing = true;
    }
  }

  void mouseReleased() {
    if (this.isDrawing) {
      this.saveFinalCurve();
      this.resetCurve();
      this.clearLayer(this.drawingLayer);
      this.isDrawing = false;
    }
  }
}

// Base class for a secondary window in Processing
class ToolWindow extends PApplet {
  CurveSubwindow curveWindow;

  public ToolWindow() {
    super();
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
  }

  void settings() {
    this.size(TOOL_WIN_SIZE[0], TOOL_WIN_SIZE[1]);
  }

  void setup() {
    this.surface.setLocation(TOOL_WIN_XY[0], TOOL_WIN_XY[1]);
    this.curveWindow = new CurveSubwindow(
      this,
      // x
      0,
      // y
      0,
      // width
      TOOL_WIN_SIZE[0],
      // height
      TOOL_WIN_SIZE[1],
      // padding
      20
    );
  }

  void draw() {
    this.curveWindow.draw();
  }

  void mouseDragged() {
    this.curveWindow.mouseDragged(mouseX, mouseY);
  }

  void mousePressed() {
    this.curveWindow.mousePressed(mouseX, mouseY);
  }

  void mouseReleased() {
    this.curveWindow.mouseReleased();
  }

  Vec2D[] getYNormalizedCurve() {
    return this.curveWindow.getYNormalizedCurve();
  }
}
