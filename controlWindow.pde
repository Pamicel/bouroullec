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

  PGraphics pushLayer() {
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

  class Curve {
    ArrayList<Vec2D> points = new ArrayList<Vec2D>();
    Curve() {}

    void addPoint(Vec2D point) {
      if (this.canAddPoint(point)) {
        this.points.add(point);
      }
    }

    Vec2D get(int i) {
      return this.points.get(i);
    }

    int size() {
      return this.points.size();
    }

    boolean canAddPoint(Vec2D point) {
      int curveLen = this.points.size();

      // good if first point
      if (curveLen == 0) return true;

      Vec2D curveFirstPoint = this.points.get(0);

      // good if second point and different from first point
      if (curveLen == 1) return curveFirstPoint.x != point.x;

      Vec2D curveLastPoint = this.points.get(curveLen - 1);
      boolean pointOnRight = point.x > curveLastPoint.x;
      boolean curveGoesForward = this.direction() == 1;

      return (curveGoesForward && pointOnRight) // the curve goes forwards and the point is on the right
              || (!curveGoesForward && !pointOnRight); // the curve goes backwards and the point is on the left
    }

    void reset() {
      this.points = new ArrayList<Vec2D>();
    }

    int direction() {
      Vec2D curveFirstPoint = this.points.get(0);
      Vec2D curveLastPoint = this.points.get(this.points.size() - 1);
      return curveLastPoint.x > curveFirstPoint.x ? 1 : -1;
    }

    void reverse() {
      ArrayList<Vec2D> reversed = new ArrayList<Vec2D>();
      for (int i = 0; i < this.points.size(); i++) {
        reversed.add(this.points.get(this.points.size() - i - 1));
      }
      this.points = reversed;
    }

    void resample(float minX, float maxX, float linearDensity) {
      ArrayList<Vec2D> shavedCurve = new ArrayList<Vec2D>();
      Vec2D currentPoint, nextPoint;
      boolean ltZero;
      boolean gtOne;
      int curveLen = this.points.size();
      int curveDirection = this.direction();

      // Make the curve go forward
      if (curveDirection == -1) {
        this.reverse();
      }

      // remove unused points
      for (int i = 0; i < curveLen; i++) {
        currentPoint = this.points.get(i);
        nextPoint = i + 1 < curveLen ? this.points.get(i + 1) : null;
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
        ltZero = currentPoint.x < minX;
        gtOne = currentPoint.x > maxX;
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

      Vec2D[] resampled = densityResample(shavedCurve, linearDensity);
      this.points = new ArrayList<Vec2D>(Arrays.asList(resampled));
    }

    Vec2D[] yNormalizedPoints(int ymin, int ygap) {
      Vec2D[] yNormalizedCurve = new Vec2D[this.points.size()];
      for(int i = 0; i < this.points.size(); i++) {
        yNormalizedCurve[i] = new Vec2D(0, (- this.points.get(i).y + ymin) / (ygap / 2));
      }

      return yNormalizedCurve;
    }
  }

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
    this.backgroundLayer = this.pushLayer();
    this.guidesLayer = this.pushLayer();
    this.curveLayer = this.pushLayer();
    this.curve = new Curve();
  }

  Curve curve;
  // ArrayList<Vec2D> curve = new ArrayList<Vec2D>();
  Vec2D[] finalCurve = null;
  PGraphics curveLayer, backgroundLayer, guidesLayer;
  float linearDensity = 1.0 / 5;
  int xmin, xmax, padding;
  int ymin, ymax, ymid, ygap;
  boolean isDrawing = false;
  int width, height;

  private int curveDirection() {
    return this.curve.direction();
  }

  void addPointToCurve (Vec2D point) {
    this.curve.addPoint(point);
  }

  void saveFinalCurve() {
    float minX = this.padding;
    float maxX = this.width - this.padding;
    this.curve.resample(minX, maxX, this.linearDensity);
  }

  Vec2D[] getYNormalizedCurve() {
    return this.curve.yNormalizedPoints(this.ymin, this.ygap);
  }

  void printCurve(PGraphics layer) {
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
    this.printCurve(this.curveLayer);
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
      this.curve.reset();
      this.curve.addPoint(new Vec2D(mouseX, mouseY));
      this.isDrawing = true;
    }
  }

  void mouseReleased() {
    if (this.isDrawing) {
      this.saveFinalCurve();
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
