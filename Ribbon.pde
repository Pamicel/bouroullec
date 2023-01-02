class Rectangle {
  Vec2D pointA, pointB, pointC, pointD;
  float area;

  Rectangle(Vec2D arrowStart, float arrowLength, float arrowWidth, float arrowHeading) {
    Vec2D pointA = arrowStart.add(new Vec2D(0, arrowWidth / 2).rotate(arrowHeading));
    Vec2D pointB = arrowStart.add(new Vec2D(arrowLength, arrowWidth / 2).rotate(arrowHeading));
    Vec2D pointC = arrowStart.add(new Vec2D(arrowLength, -arrowWidth / 2).rotate(arrowHeading));
    Vec2D pointD = arrowStart.add(new Vec2D(0, -arrowWidth / 2).rotate(arrowHeading));
    this.initialize(pointA, pointB, pointC, pointD);
  }

  private void initialize(Vec2D pointA, Vec2D pointB, Vec2D pointC, Vec2D pointD) {
    this.pointA = pointA;
    this.pointB = pointB;
    this.pointC = pointC;
    this.pointD = pointD;
    this.area = areaOfATriangle(this.pointA, this.pointB, this.pointC) +
                areaOfATriangle(this.pointA, this.pointC, this.pointD);
  }

  private float areaOfATriangle(Vec2D a, Vec2D b, Vec2D c) {
    return abs((a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y)) / 2.0f);
  }

  boolean isInside(Vec2D point, float epsilon) {
    // Calculate the sum of areas of △APD, △DPC, △CPB, △PBA.
    // If the sum is equal to the area of the rectangle, then the point lies inside the rectangle.
    float areaOfAPD = areaOfATriangle(this.pointA, point, this.pointD);
    float areaOfDPC = areaOfATriangle(this.pointD, point, this.pointC);
    float areaOfCPB = areaOfATriangle(this.pointC, point, this.pointB);
    float areaOfPBA = areaOfATriangle(this.pointB, point, this.pointA);
    float sumOfAreas = areaOfAPD + areaOfDPC + areaOfCPB + areaOfPBA;
    return Math.abs(sumOfAreas - this.area) < epsilon;
  }

  void display(PGraphics layer) {
    layer.push();
    layer.noFill();
    layer.stroke(0);
    layer.strokeWeight(1);
    layer.beginShape();
    layer.vertex(this.pointA.x, this.pointA.y);
    layer.vertex(this.pointB.x, this.pointB.y);
    layer.vertex(this.pointC.x, this.pointC.y);
    layer.vertex(this.pointD.x, this.pointD.y);
    layer.endShape(CLOSE);
    layer.pop();
  }
}

class Arrow {
  Vec2D start;
  float arrowLength;
  float arrowWidth;
  float arrowHeading;
  Rectangle rectangle;

  Arrow(Vec2D start, float length, float heading) {
    this.start = start;
    this.arrowLength = length;
    this.arrowWidth = this.arrowLength / 2;
    this.arrowHeading = heading;
    this.rectangle = new Rectangle(this.start, this.arrowLength * 1.2, this.arrowWidth * 1.2, this.arrowHeading);
  }

  void display(PGraphics layer) {
    this.rectangle.display(layer);
    layer.push();
    layer.pushMatrix();
    layer.translate(this.start.x, this.start.y);
    layer.rotate(this.arrowHeading);
    layer.strokeWeight(1);
    layer.stroke(0);
    layer.line(0, 0, this.arrowLength, 0);
    layer.translate(this.arrowLength, 0);
    layer.rotate(-HALF_PI / 2);
    layer.line(0, 0, -this.arrowWidth / 2, 0);
    layer.rotate(HALF_PI);
    layer.line(0, 0, -this.arrowWidth / 2, 0);
    layer.popMatrix();
    layer.pop();
  }

  boolean isHover(float mX, float mY) {
    return this.rectangle.isInside(new Vec2D(mX, mY), this.arrowWidth / 10);
  }
}

class RibbonEndButtons {
  private Vec2D rightBank, leftBank, center, leftDirection;
  private Vec2D leftBankAnchorPoint, rightBankAnchorPoint;
  float radius = 12;
  float ribbonWid;
  Ribbon ribbon;
  float arrowLength = 20;
  float leftBankHeading, rightBankHeading;
  boolean highlightLeftArrow = false,
          highlightRightArrow = false,
          highlightCenterArrow = false;
  Arrow leftArrow, rightArrow;

  RibbonEndButtons (
    Vec2D center,
    float ribbonWid,
    Vec2D leftDirection,
    Ribbon ribbon
  ) {
    this.center = center;
    this.leftDirection = leftDirection;
    this.ribbonWid = ribbonWid;
    this.ribbon = ribbon;

    Vec2D normalizedDir = this.leftDirection.getNormalizedTo(ribbonWid);
    this.leftBankAnchorPoint = this.center.add(normalizedDir);
    this.rightBankAnchorPoint = this.center.sub(normalizedDir);

    this.leftBank = this.leftBankAnchorPoint.add(normalizedDir.scale(2));
    this.rightBank = this.rightBankAnchorPoint.sub(normalizedDir.scale(2));

    this.leftBankHeading = this.leftBankAnchorPoint.sub(this.leftBank).heading() + PI;
    this.rightBankHeading = this.rightBankAnchorPoint.sub(this.rightBank).heading() + PI;

    this.leftArrow = new Arrow(this.leftBank, this.arrowLength, this.leftBankHeading);
    this.rightArrow = new Arrow(this.rightBank, this.arrowLength, this.rightBankHeading);
  }

  Vec2D getCenter() {
    return this.center;
  }

  Vec2D getLeft() {
    if (ribbon.leftRibbon != null) {
      this.leftBank = null;
      this.leftBankAnchorPoint = null;
    }
    return this.leftBank;
  }

  Vec2D getRight() {
    if (ribbon.rightRibbon != null) {
      this.rightBank = null;
      this.rightBankAnchorPoint = null;
    }
    return this.rightBank;
  }

  private boolean isHover(Vec2D position, float mX, float mY, float radius) {
    return position.distanceToSquared(new Vec2D(mX, mY)) < (radius * radius);
  }

  boolean isHoverLeftBank(float mX, float mY) {
    Vec2D left = this.getLeft();
    boolean isHoverLeftBank = left != null && this.leftArrow.isHover(mX, mY);
    this.highlightLeftArrow = isHoverLeftBank;
    if (isHoverLeftBank) {
      println("hover left bank");
    }
    return isHoverLeftBank;
  }
  boolean isHoverRightBank(float mX, float mY) {
    Vec2D right = this.getRight();
    boolean isHoverRightBank = right != null && this.rightArrow.isHover(mX, mY);
    this.highlightRightArrow = isHoverRightBank;
    if (isHoverRightBank) {
      println("hover right bank");
    }
    return isHoverRightBank;
  }
  boolean isHoverCenter(float mX, float mY) {
    return this.isHover(this.center, mX, mY, this.arrowLength);
  }

  void displayArrow(Vec2D position, float heading, PGraphics layer, boolean highlight) {
    layer.push();

    layer.noStroke();
    layer.fill(255, 0, 0);
    layer.beginShape();
    Vec2D pointA = position.add(new Vec2D(0, this.arrowLength / 4).rotate(heading));
    Vec2D pointB = position.add(new Vec2D(this.arrowLength, this.arrowLength / 4).rotate(heading));
    Vec2D pointC = position.add(new Vec2D(this.arrowLength, -this.arrowLength / 4).rotate(heading));
    Vec2D pointD = position.add(new Vec2D(0, -this.arrowLength / 4).rotate(heading));
    layer.vertex(pointA.x, pointA.y);
    layer.vertex(pointB.x, pointB.y);
    layer.vertex(pointC.x, pointC.y);
    layer.vertex(pointD.x, pointD.y);
    layer.endShape(CLOSE);

    layer.pushMatrix();
    layer.translate(position.x, position.y);
    layer.rotate(heading);
      // layer.noStroke();
      // layer.fill(255, 0, 0);
      // layer.circle(this.arrowLength / 2, 0, this.arrowLength);
    layer.strokeWeight(1);
    layer.stroke(0);
    layer.line(0, 0, this.arrowLength, 0);
    layer.translate(this.arrowLength, 0);
    layer.rotate(-HALF_PI / 2);
    layer.line(0, 0, -this.arrowLength / 4, 0);
    layer.rotate(HALF_PI);
    layer.line(0, 0, -this.arrowLength / 4, 0);
    layer.popMatrix();
    layer.pop();
  }

  void display(PGraphics layer) {
    Vec2D left = this.getLeft();
    Vec2D right = this.getRight();
    int lenFactor = 10;

    if (left != null) {
      this.leftArrow.display(layer);
    }
    if (right != null) {
      this.rightArrow.display(layer);
    }
    // if (this.center != null) {
    //   layer.push();
    //   layer.noStroke();
    //   layer.fill(255, 0, 0);
    //   layer.circle(this.center.x, this.center.y, this.radius);
    //   layer.pop();
    // }
  }
}

class Ribbon {
  Vec2D[] curve = new Vec2D[0];
  Vec2D[] normals = new Vec2D[0];
  color col = color(0);

  RibbonEndButtons frontButtons = null,
                  backButtons = null;

  Ribbon leftRibbon = null,
        rightRibbon = null;

  float ribbonWid = RIBON_WID;
  float ribbonGapFactor = RIBBON_GAP_FACTOR;

  Ribbon(Vec2D[] curve) {
    this.curve = curve;
    this.computeCurveNormals();
    this.computeEndButtons();
  }

  Ribbon(Vec2D[] curve, Vec2D[] variations) {
    this.curve = curve;
    this.computeCurveNormals();
    if (variations != null && variations.length > 0) {
      this.applyVariationsToCurve(variations);
      this.computeCurveNormals();
    }
    this.computeEndButtons();
  }

  boolean isOverButton(float mX, float mY) {
    boolean isOverBack = (
      this.backButtons != null &&
      (
        this.backButtons.isHoverLeftBank(mX, mY) ||
        this.backButtons.isHoverRightBank(mX, mY) ||
        this.backButtons.isHoverCenter(mX, mY)
      )
    );
    boolean isOverFront = (
      this.frontButtons != null &&
      (
        this.frontButtons.isHoverLeftBank(mX, mY) ||
        this.frontButtons.isHoverRightBank(mX, mY) ||
        this.frontButtons.isHoverCenter(mX, mY)
      )
    );
    return isOverBack || isOverFront;
  }

  boolean hasRightBank() {
    return this.rightRibbon != null;
  }
  boolean hasLeftBank() {
    return this.leftRibbon != null;
  }

  void assignLeftRibbon(Ribbon leftRibbon) {
    this.leftRibbon = leftRibbon;
  }

  void assignRightRibbon(Ribbon rightRibbon) {
    this.rightRibbon = rightRibbon;
  }

  void displayCurve(PGraphics layer) {
    layer.stroke(0);
    layer.noFill();
    layer.beginShape();
    Vec2D pos;
    for (int i = 0; i < this.curve.length; i++) {
      pos = this.curve[i];
      layer.circle(pos.x, pos.y, this.ribbonWid / 10);
      layer.vertex(pos.x, pos.y);
    }
    layer.endShape();
  }

  void displayCurvePieces(PGraphics layer) {
    if (curve.length < 2) return;
    layer.noStroke();
    Vec2D posA, posB, normA, normB;
    float wid = this.ribbonWid / 2;
    for (int i = 0; i < this.curve.length - 1; i++) {
      posA = this.curve[i];
      normA = this.normals[i];
      posB = this.curve[i + 1];
      normB = this.normals[i + 1];
      layer.fill(0,0,0,round(random(1)) * 255);
      layer.beginShape();
      layer.vertex(posA.x + normA.x * wid, posA.y + normA.y * wid);
      layer.vertex(posB.x + normB.x * wid, posB.y + normB.y * wid);
      layer.vertex(posB.x - normB.x * wid, posB.y - normB.y * wid);
      layer.vertex(posA.x - normA.x * wid, posA.y - normA.y * wid);
      layer.endShape(CLOSE);
    }
  }

  void displayCurvePiecesSmooth(PGraphics layer) {
    if (curve.length < 2) return;
    layer.strokeWeight(this.ribbonWid / 2);
    layer.noFill();
    layer.strokeCap(SQUARE);
    layer.stroke(0);
    Vec2D pos;
    boolean drawingBefore = false;
    boolean drawing = random(1) > .5;
    int nDrawn = 0;
    for (int i = 0; i < this.curve.length; i++) {
      pos = this.curve[i];
      if (drawing) {
        if (!drawingBefore) {
          layer.beginShape();
          // double first
          layer.curveVertex(pos.x, pos.y);
        }
        layer.curveVertex(pos.x, pos.y);
      }

      nDrawn += drawing ? 1 : 0;
      drawingBefore = drawing;
      boolean isLast = i == this.curve.length - 1;
      drawing = (random(1) < .6 || (nDrawn < 2)) && !isLast;
      nDrawn = drawing ? nDrawn : 0;

      if (drawingBefore && !drawing) {
        // double last
        layer.curveVertex(pos.x, pos.y);
        layer.endShape();
      }
    }
  }

  void displayCurvePiecesSmoothBW(PGraphics layer) {
    if (curve.length < 2) return;
    layer.strokeWeight(1);
    layer.noFill();
    layer.strokeCap(SQUARE);
    Vec2D pos;
    boolean inBlack = random(1) > .5;
    boolean inBlackBefore = inBlack;
    boolean switching = false;
    int nDrawn = 0;
    for (int i = 0; i < this.curve.length; i++) {
      pos = this.curve[i];

      if (i == 0) {
        layer.stroke(inBlack ? 0 : 200);
        layer.beginShape();
        // double first
        layer.curveVertex(pos.x, pos.y);
      } else if (switching) {
        layer.stroke(inBlack ? 0 : #f2f2f2);
        // double last
        layer.curveVertex(pos.x, pos.y);
        layer.curveVertex(pos.x, pos.y);
        layer.endShape();
        layer.beginShape();
        // double first
        layer.curveVertex(pos.x, pos.y);
      }

      layer.curveVertex(pos.x, pos.y);
      nDrawn++;

      switching = random(1) < .8 && (nDrawn > 2);;
      inBlackBefore = inBlack;
      inBlack = switching ? !inBlack : inBlack;
      nDrawn = switching ? 0 : nDrawn;

      if (i == this.curve.length - 1) {
        // double last
        layer.curveVertex(pos.x, pos.y);
        layer.endShape();
      }
    }
  }

  void displayConnections(PGraphics layer) {
    Vec2D firstA, lastA, firstB, lastB;
    firstA = this.curve[0];
    lastA = this.curve[this.curve.length - 1];
    layer.push();
    layer.noFill();
    layer.strokeWeight(4);
    layer.stroke(255, 0, 0);
    layer.strokeCap(PROJECT);
    if (this.leftRibbon != null) {
      firstB = this.leftRibbon.curve[0];
      lastB = this.leftRibbon.curve[this.leftRibbon.curve.length - 1];
      layer.line(firstA.x, firstA.y, firstB.x, firstB.y);
      layer.line(lastA.x, lastA.y, lastB.x, lastB.y);
    }
    if (this.rightRibbon != null) {
      firstB = this.rightRibbon.curve[0];
      lastB = this.rightRibbon.curve[this.rightRibbon.curve.length - 1];
      layer.line(firstA.x, firstA.y, firstB.x, firstB.y);
      layer.line(lastA.x, lastA.y, lastB.x, lastB.y);
    }
    layer.pop();
  }

  void displayCurveSmooth(PGraphics layer) {
    layer.stroke(this.col);
    layer.strokeCap(SQUARE);
    layer.strokeWeight(this.ribbonWid);
    layer.noFill();
    layer.beginShape();
    Vec2D pos;
    for (int i = 0; i < this.curve.length; i++) {
      pos = this.curve[i];
      layer.curveVertex(pos.x, pos.y);
      // double first and last
      if (i == 0 || i == this.curve.length - 1) {
        layer.curveVertex(pos.x, pos.y);
      }
    }
    layer.endShape();
  }


  void displayCurvePoints(PGraphics layer) {
    Vec2D pos;
    for (int i = 0; i < this.curve.length; i++) {
      layer.stroke(255, random(255));
      pos = this.curve[i];
      layer.point(pos.x, pos.y);
    }
  }

  void displayNormals(PGraphics layer, int len) {
    Vec2D start, end;

    for (int i = 0; i < this.normals.length; i++) {
      start = this.curve[i];
      end = start.add(this.normals[i].getNormalizedTo(len));
      layer.line(start.x, start.y, end.x, end.y);
      layer.push();
      layer.fill(255, 0, 0);
      layer.noStroke();
      layer.circle(end.x, end.y, 3);
      layer.pop();
    }
  }

  Ribbon createLeftRibbon(float linearDensity, Vec2D[] variationCurve) {
    Vec2D[] newCurve = new Vec2D[this.curve.length];
    for (int index = 0; index < newCurve.length; index++) {
      newCurve[index] = this.curve[index].copy().add(this.normals[index].getNormalizedTo(this.ribbonWid * this.ribbonGapFactor));
    }

    newCurve = densityResample(newCurve, linearDensity);
    if (newCurve.length < 2) { return null; }
    Ribbon left = new Ribbon(newCurve, variationCurve);
    left.col = this.col;
    return left;
  }

  Ribbon createRightRibbon(float linearDensity, Vec2D[] variationCurve) {
    Vec2D[] invertedVariationCurve = null;
    Vec2D[] newCurve = new Vec2D[this.curve.length];

    // invert the variationCurve
    if (variationCurve != null) {
      invertedVariationCurve = new Vec2D[variationCurve.length];
      for (int i = 0; i < variationCurve.length; i++) {
        invertedVariationCurve[i] = variationCurve[i].getInverted();
      }
    }

    for (int index = 0; index < newCurve.length; index++) {
      newCurve[index] = this.curve[index].copy().sub(this.normals[index].getNormalizedTo(this.ribbonWid * this.ribbonGapFactor));
    }
    newCurve = densityResample(newCurve, linearDensity);

    if (newCurve.length < 2) { return null; }
    Ribbon right = new Ribbon(newCurve, invertedVariationCurve);
    right.col = this.col;
    return right;
  }

  Ribbon createRightRibbon(float linearDensity) {
    return this.createRightRibbon(linearDensity, null);
  }

  Ribbon createLeftRibbon(float linearDensity) {
    return this.createLeftRibbon(linearDensity, null);
  }

  void applyVariationsToCurve(Vec2D[] variations) {
    Vec2D[] resampledVariations = regularResample(variations, this.curve.length);

    for (int j = 0; j < this.curve.length; j++) {
      this.curve[j] = this.curve[j].add(this.normals[j].getNormalizedTo(this.ribbonWid * this.ribbonGapFactor * resampledVariations[j].y));
    }
  }

  private void computeCurveNormals() {
    if (this.curve.length <= 1) { return; }
    Vec2D[] curve = this.curve;
    this.normals = new Vec2D[curve.length];
    this.normals[0] = curve[0].sub(curve[1]).getRotated(HALF_PI).getNormalized();
    this.normals[curve.length - 1] = curve[curve.length - 2].sub(curve[curve.length - 1]).getRotated(HALF_PI).getNormalized();
    for (int i = 1; i < curve.length - 1; i++) {
      this.normals[i] = curve[i - 1].sub(curve[i + 1]).getRotated(HALF_PI).getNormalized();
    }
  }

  void computeEndButtons() {
    if (this.curve.length <= 1) { return; }
    int len = this.curve.length;
    Vec2D firstPoint = this.curve[0];
    Vec2D secondPoint = this.curve[1];
    Vec2D beforeLastPoint = this.curve[len - 2];
    Vec2D lastPoint = this.curve[len - 1];

    this.frontButtons = new RibbonEndButtons(
      firstPoint,
      ribbonWid,
      firstPoint.sub(secondPoint).getRotated(HALF_PI).getNormalized(),
      this
    );
    this.backButtons = new RibbonEndButtons(
      lastPoint,
      ribbonWid,
      lastPoint.sub(beforeLastPoint).getRotated(-HALF_PI).getNormalized(),
      this
    );
  }

  void displayEndButtons(PGraphics layer) {
    if (this.frontButtons != null && this.backButtons != null) {
      this.frontButtons.display(layer);
      this.backButtons.display(layer);
    }
  }
}

class RibbonEndPositions {
  int nw = 20, nh = 20;
  ArrayList<Ribbon>[] ribbons;
  HashSet<Ribbon> allRibbons = new HashSet<Ribbon>();
  int areaW, areaH;

  RibbonEndPositions(int areaW, int areaH) {
    this.areaW = areaW;
    this.areaH = areaH;
    this.ribbons = new ArrayList[this.nw * this.nh];
    for (int i = 0; i < this.ribbons.length; i++) {
      this.ribbons[i] = null;
    }
  }

  private int positionIndex (Vec2D position) {
    if (position == null) {
      return -1;
    }
    float normXpos = position.x / this.areaW;
    int xindex = floor(normXpos * this.nw);
    float normYpos = position.y / this.areaH;
    int yindex = floor(normYpos * this.nh);
    return xindex + this.nw * yindex;
  }

  private void placeRibbonAt(int index, Ribbon ribbon) {
    if (index < 0) return;
    if (index >= nw * nh) return;
    if (this.ribbons[index] == null) {
      this.ribbons[index] = new ArrayList<Ribbon>();
    }
    this.ribbons[index].add(ribbon);
    this.allRibbons.add(ribbon);
  }

  ArrayList<Ribbon> getRibbonsAt(float mX, float mY) {
    int index = this.positionIndex(new Vec2D(mX, mY));
    if (index < 0) return null;
    if (index >= this.ribbons.length) return null;
    if (this.ribbons[index] != null) {
      return this.ribbons[index];
    }
    return null;
  }

  Ribbon[] getAllRibbons() {
    return this.allRibbons.toArray(new Ribbon[this.allRibbons.size()]);
  }

  void removeRibbon(Ribbon ribbon) {
    HashSet<Integer> indices = new HashSet<Integer>();
    indices.add(this.positionIndex(ribbon.frontButtons.getLeft()));
    indices.add(this.positionIndex(ribbon.frontButtons.getRight()));
    indices.add(this.positionIndex(ribbon.backButtons.getLeft()));
    indices.add(this.positionIndex(ribbon.backButtons.getRight()));
    Iterator<Integer> it = indices.iterator();
    while(it.hasNext()) {
      this.removeRibbonAt(it.next(), ribbon);
    }

  }

  private void removeRibbonAt(int index, Ribbon ribbon) {
    if (index >= 0 && index < this.ribbons.length) {
      this.ribbons[index].remove(Collections.singleton(ribbon));
      this.allRibbons.remove(ribbon);
    }
  }

  void addRibbon(Ribbon ribbon) {
    HashSet<Integer> indices = new HashSet<Integer>();
    indices.add(this.positionIndex(ribbon.frontButtons.getLeft()));
    indices.add(this.positionIndex(ribbon.frontButtons.getRight()));
    indices.add(this.positionIndex(ribbon.backButtons.getLeft()));
    indices.add(this.positionIndex(ribbon.backButtons.getRight()));

    Iterator<Integer> it = indices.iterator();
    while(it.hasNext()) {
      this.placeRibbonAt(it.next(), ribbon);
    }
  }

  void addRibbons(ArrayList<Ribbon> ribbons) {
    Iterator<Ribbon> it = ribbons.iterator();
    while(it.hasNext()) {
      this.addRibbon(it.next());
    }
  }
}
