// Base class for a secondary window in Processing
class ChildApplet extends PApplet {
  public ChildApplet() {
    super();
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
  }

  ArrayList<Vec2D> curve = new ArrayList<Vec2D>();
  Vec2D[] finalCurve;
  PGraphics finalCurveLayer;

  int xmin, xmax, padding;

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

    this.finalCurve = densityResample(shavedCurve, 1.0 / 40);
  }

  void drawFinalCurve (PGraphics layer) {
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

  void settings() {
    this.size(200, 200);
  }

  void setup() {
    this.padding = 20;
    this.xmin = this.padding;
    this.xmax = this.width - this.padding;
    this.finalCurveLayer = this.createGraphics(this.width, this.height);
  }

  void draw() {
    this.background(255);
    this.noFill();
    Vec2D pos;
    this.line(this.padding, 0, this.padding, this.height);
    this.line(this.width - this.padding, 0, this.width - this.padding, this.height);
    this.line(this.padding, this.height / 2, this.width - this.padding, this.height / 2);
    if (mousePressed) {
      this.stroke(0);
      this.beginShape();
      for (int i = 0; i < this.curve.size(); i++) {
        pos = this.curve.get(i);
        circle(pos.x, pos.y, 5);
        vertex(pos.x, pos.y);
      }
      this.endShape();
    }
    this.drawFinalCurve(this.finalCurveLayer);
    this.image(this.finalCurveLayer, 0, 0);
  }

  void mouseDragged() {
    this.addPointToCurve(new Vec2D(mouseX, mouseY));
  }

  void mousePressed() {
    this.addPointToCurve(new Vec2D(mouseX, mouseY));
  }

  void mouseReleased() {
    this.saveFinalCurve();
    // Delete the current hand drawn curve
    this.resetCurve();
  }
}