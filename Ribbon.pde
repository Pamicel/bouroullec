class Arrow {
  Vec2D start, midPoint;
  float arrowLength;
  float arrowWidth;
  float arrowHeading;
  boolean highlight = false;

  Arrow(Vec2D start, float length, float heading) {
    this.start = start;
    this.arrowLength = length;
    this.arrowWidth = this.arrowLength / 2;
    this.arrowHeading = heading;
    this.midPoint = this.start.add(new Vec2D(this.arrowLength / 2, 0).rotate(this.arrowHeading));
  }

  void display(PGraphics layer) {
    this.display(ArrowStyle.ARROW_OUT, layer);
  }

  void display(ArrowStyle style, PGraphics layer) {
    layer.push();
    // Highlight with a red circle
    if (this.highlight) {
      layer.fill(255, 0, 0);
      layer.noStroke();
      layer.circle(this.midPoint.x, this.midPoint.y, this.arrowLength);
    }
    layer.pop();
    if (style == ArrowStyle.LINE) {
      this.drawLine(layer);
    } else if (style == ArrowStyle.ARROW_OUT) {
      this.drawArrowOut(layer);
    }
  }

  void drawLine(PGraphics layer) {
    layer.push();
    layer.pushMatrix();
    layer.translate(this.start.x, this.start.y);
    layer.rotate(this.arrowHeading);
    layer.strokeWeight(1);
    layer.stroke(0);
    layer.line(0, 0, this.arrowLength, 0);
    layer.popMatrix();
    layer.pop();
  }

  void drawArrowOut(PGraphics layer) {
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
    // distance to midpoint < arrowLength / 2
    return this.midPoint.distanceTo(new Vec2D(mX, mY)) < this.arrowLength / 2;
  }

  void setHighlighted(boolean highlighted) {
    this.highlight = highlighted;
  }
}

enum ArrowStyle {
  LINE,
  ARROW_OUT;
}

class RibbonEndButtons {
  private Vec2D rightBank, leftBank, center, leftDirection;
  private Vec2D leftBankAnchorPoint, rightBankAnchorPoint;
  float radius = 12;
  float ribbonWid;
  Ribbon ribbon;
  float arrowLength = 20;
  float leftBankHeading, rightBankHeading;
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
    if (ribbon.leftRibbons != null) {
      this.leftBank = null;
      this.leftBankAnchorPoint = null;
    }
    return this.leftBank;
  }

  Vec2D getRight() {
    if (ribbon.rightRibbons != null) {
      this.rightBank = null;
      this.rightBankAnchorPoint = null;
    }
    return this.rightBank;
  }

  void setLeftHighlight(boolean highlight) {
    this.leftArrow.setHighlighted(highlight);
  }

  void setRightHighlight(boolean highlight) {
    this.rightArrow.setHighlighted(highlight);
  }

  void removeHighlights() {
    this.leftArrow.setHighlighted(false);
    this.rightArrow.setHighlighted(false);
  }

  private boolean isHover(Vec2D position, float mX, float mY, float radius) {
    return position.distanceToSquared(new Vec2D(mX, mY)) < (radius * radius);
  }

  boolean isHoverLeftBank(float mX, float mY) {
    Vec2D left = this.getLeft();
    return left != null && this.leftArrow.isHover(mX, mY);
  }
  boolean isHoverRightBank(float mX, float mY) {
    Vec2D right = this.getRight();
    return right != null && this.rightArrow.isHover(mX, mY);
  }
  boolean isHoverCenter(float mX, float mY) {
    return this.isHover(this.center, mX, mY, this.arrowLength);
  }

  void display(ArrowStyle arrowStyle, PGraphics layer) {
    Vec2D left = this.getLeft();
    Vec2D right = this.getRight();
    int lenFactor = 10;

    if (left != null) {
      this.leftArrow.display(arrowStyle, layer);
    }
    if (right != null) {
      this.rightArrow.display(arrowStyle, layer);
    }
  }
}

class RibbonButtons {
  Ribbon ribbon = null;
  RibbonButtons(Ribbon ribbon) {
    this.ribbon = ribbon;
  }
}

class Ribbon {
  Vec2D[] curve = new Vec2D[0];
  Vec2D[] normals = new Vec2D[0];
  color col = color(0);
  color highlightColor = color(255, 0, 0);
  boolean isHighlighted = false;
  /**
   * Some context on the graphDepth:
   * When cut, a ribbon is "replaced" with the two new ribbons that result from the cut,
   * ie the original ribbon continues to exist, but is not drawn by the plotter.
   *
   * In other words, graphically speaking, the `cut` function does not work like this:
   *
   * O——————————————— // O is the parent of A
   * A———————————————
   *       ↓ cut()
   * ///////////////// ↑ before, ↓ after
   * O———————————————
   * A——————————————— // A would remains
   * B————— C———————— // B and C would be extensions
   *
   * But like this:
   *
   * O———————————————
   * A———————————————
   *       ↓ cut()
   * /////////////////
   * O———————————————
   * B————— C———————— // B and C replace A
   *
   *
   * If you were to extend B and cut C ...
   *
   * O———————————————
   * B————— C————————
   * ↓ ext()
   * /////////////////
   * O———————————————
   * B————— C————————
   * D—————    ↓
   *           ↓ cut()
   * /////////////////
   * O———————————————
   * B————— E—— F————
   * D—————  ↓
   *         ↓ ext()
   * /////////////////
   * O———————————————
   * B————— E—— F————
   * D————— G——
   *         ↓ ext()
   * /////////////////
   * O———————————————
   * B————— E—— F————
   * D————— G——
   *        H——
   *
   * Here, if i want to be able to weave the ribbons, we need to know their depth
   * O——————————————— depth = 0
   * B————— E—— F———— depth = 1
   * D————— G——       depth = 2
   *        H——       depth = 3
   *
   * So that we can print 0 then the 2s then the 1s then 3
   * But because i decided to keep the original ribbon instances, the graph actually looks something like this
   * O———————————————
   * Axxxxxxxxxxxxxxx
   * B————— Cxxxxxxxx
   * D————— E—— F————
   *        G——
   *        H——
   *
   * The trick is that ribbons that result from an extension get the depth of their parent + 1
   * and ribbons that result from a cut get the depth of their parent. In the example above:
   * O.depth = 0,
   * A.depth = 1 = O.depth + 1
   * B.depth = 1 = A.depth
   * C.depth = 1 = A.depth
   * D.depth = 2 = B.depth + 1
   * E.depth = 1 = C.depth
   * F.depth = 1 = C.depth
   * G.depth = 2 = E.depth + 1
   * H.depth = 3 = G.depth + 1
   */
  int graphDepth = 0;

  RibbonEndButtons frontButtons = null,
                  backButtons = null;

  ArrayList<RibbonEndButtons> allButtons = new ArrayList<RibbonEndButtons>();

  ArrayList<Ribbon> leftRibbons = null,
                    rightRibbons = null;

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

  float getNextRibbonNominalDistance() {
    return this.ribbonWid * this.ribbonGapFactor;
  }

  float getTailToHeadDistanceWith(Ribbon ribbon) {
    // Distance between the last point of this ribbon's curve and the first point of the other ribbon's curve
    Vec2D tail = this.curve[this.curve.length - 1];
    Vec2D head = ribbon.curve[0];
    return tail.distanceTo(head);
  }

  boolean hasRightBank() {
    return this.rightRibbons != null;
  }
  boolean hasLeftBank() {
    return this.leftRibbons != null;
  }

  boolean isBorderRibbon() {
    return (!this.hasLeftBank()) || (!this.hasRightBank());
  }

  boolean isCutLeft() {
    return this.leftRibbons != null && this.leftRibbons.size() > 1;
  }

  boolean isCutRight() {
    return this.rightRibbons != null && this.rightRibbons.size() > 1;
  }

  boolean isCut() {
    return this.isCutLeft() || this.isCutRight();
  }

  boolean isExtendedLeft() {
    return this.leftRibbons != null && this.leftRibbons.size() == 1;
  }

  boolean isExtendedRight() {
    return this.rightRibbons != null && this.rightRibbons.size() == 1;
  }

  boolean isExtended() {
    return this.isExtendedLeft() || this.isExtendedRight();
  }

  void assignLeftRibbon(Ribbon ribbon) {
    if (this.leftRibbons != null) {
      this.leftRibbons.add(ribbon);
    } else {
      this.leftRibbons = new ArrayList<Ribbon>();
      this.leftRibbons.add(ribbon);
    }
  }

  void assignRightRibbon(Ribbon ribbon) {
    if (this.rightRibbons != null) {
      this.rightRibbons.add(ribbon);
    } else {
      this.rightRibbons = new ArrayList<Ribbon>();
      this.rightRibbons.add(ribbon);
    }
  }

  void highlight() {
    this.isHighlighted = true;
  }

  void removeHighlight() {
    this.isHighlighted = false;
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
    // For all ribbons in leftRibbons
    if (this.leftRibbons != null) {
      for (int i = 0; i < this.leftRibbons.size(); i++) {
        firstB = this.leftRibbons.get(i).curve[0];
        lastB = this.leftRibbons.get(i).curve[this.leftRibbons.get(i).curve.length - 1];
        layer.line(firstA.x, firstA.y, firstB.x, firstB.y);
        layer.line(lastA.x, lastA.y, lastB.x, lastB.y);
      }
    }
    // For all ribbons in rightRibbons
    if (this.rightRibbons != null) {
      for (int i = 0; i < this.rightRibbons.size(); i++) {
        firstB = this.rightRibbons.get(i).curve[0];
        lastB = this.rightRibbons.get(i).curve[this.rightRibbons.get(i).curve.length - 1];
        layer.line(firstA.x, firstA.y, firstB.x, firstB.y);
        layer.line(lastA.x, lastA.y, lastB.x, lastB.y);
      }
    }
    layer.pop();
  }

  void displayCurveSmooth(PGraphics layer) {
    layer.stroke(this.isHighlighted ? this.highlightColor : this.col);
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

  private Ribbon createLeftRibbon(float linearDensity, Vec2D[] variationCurve) {
    Vec2D[] newCurve = new Vec2D[this.curve.length];
    for (int index = 0; index < newCurve.length; index++) {
      newCurve[index] = this.curve[index].copy().add(this.normals[index].getNormalizedTo(this.ribbonWid * this.ribbonGapFactor));
    }

    newCurve = densityResample(newCurve, linearDensity);
    if (newCurve.length < 2) { return null; }
    Ribbon left = new Ribbon(newCurve, variationCurve);
    left.col = this.col;
    left.graphDepth = this.graphDepth + 1;
    return left;
  }

  private Ribbon createRightRibbon(float linearDensity, Vec2D[] variationCurve) {
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
    right.graphDepth = this.graphDepth + 1;
    return right;
  }

  private Ribbon createRightRibbon(float linearDensity) {
    return this.createRightRibbon(linearDensity, null);
  }

  private Ribbon createLeftRibbon(float linearDensity) {
    return this.createLeftRibbon(linearDensity, null);
  }

  private void applyVariationsToCurve(Vec2D[] variations) {
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
    // for each point on the curve, assign a pair of buttons and add them to the list
    for (int i = 0; i < this.curve.length; i++) {
      Vec2D point = this.curve[i];
      Vec2D normal = this.normals[i];
      RibbonEndButtons buttons = new RibbonEndButtons(point, this.ribbonWid, normal, this);
      this.allButtons.add(buttons);
    }
    this.frontButtons = this.allButtons.get(0);
    this.backButtons = this.allButtons.get(this.allButtons.size() - 1);
  }

  void displayEndButtons(ArrowStyle arrowStyle, PGraphics layer) {
    for (RibbonEndButtons buttons : this.allButtons) {
      buttons.display(arrowStyle, layer);
    }
  }

  Ribbon extendLeft(float linearDensity, Vec2D[] variationCurve) {
    Ribbon newRibbon = this.createLeftRibbon(linearDensity, variationCurve);
    if (newRibbon != null) {
      this.assignLeftRibbon(newRibbon);
      newRibbon.assignRightRibbon(this);
      // TODO: Remove left buttons
    }
    return newRibbon;
  }

  Ribbon extendRight(float linearDensity, Vec2D[] variationCurve) {
    Ribbon newRibbon = this.createRightRibbon(linearDensity, variationCurve);
    if (newRibbon != null) {
      this.assignRightRibbon(newRibbon);
      newRibbon.assignLeftRibbon(this);
      // TODO: Remove right buttons
    }
    return newRibbon;
  }

  boolean isOverLeft(Vec2D mousePos) {
    boolean isOver = false;
    for (RibbonEndButtons buttons : this.allButtons) {
      if (buttons.isHoverLeftBank(mousePos.x, mousePos.y)) {
        // Don't return here because we want to check all buttons to reset the state of the highlight (isHoverLeftBank is not a pure function)
        isOver = true;
      }
    }
    return isOver;
  }

  boolean isOverRight(Vec2D mousePos) {
    boolean isOver = false;
    for (RibbonEndButtons buttons : this.allButtons) {
      if (buttons.isHoverRightBank(mousePos.x, mousePos.y)) {
        // Don't return here because we want to check all buttons to reset the state of the highlight (isHoverRightBank is not a pure function)
        isOver = true;
      }
    }
    return isOver;
  }

  /**
   * Returns the distance of the closest point on the curve to the mouse position, or -1 if the closest point is further than tolerance
   */
  float isOverCurve(Vec2D mousePos, float tolerance) {
    // pre select points that are in the tolerance * tolerance square around the mouse (simpler than computing the distance to each point)
    ArrayList<Vec2D> candidates = new ArrayList<Vec2D>();
    for (int i = 0; i < this.curve.length; i++) {
      Vec2D point = this.curve[i];
      if (
        point.x - tolerance < mousePos.x &&
        mousePos.x < point.x + tolerance &&
        point.y - tolerance < mousePos.y &&
        mousePos.y < point.y + tolerance
      ) {
        candidates.add(point);
      }
    }
    // Return closest point to the mouse in the candidate points, simply ignore if closest distance is greater than tolerance
    if (candidates.size() > 0) {
      Vec2D closest = candidates.get(0);
      float minDist = closest.distanceTo(mousePos);
      for (int i = 1; i < candidates.size(); i++) {
        Vec2D candidate = candidates.get(i);
        float dist = candidate.distanceTo(mousePos);
        if (dist < minDist) {
          closest = candidate;
          minDist = dist;
        }
      }
      if (minDist < tolerance) {
        return minDist;
      }
    }
    // If the candidate list is empty, return -1
    return -1;
  }

  Ribbon extend(Vec2D mousePos, Vec2D[] variationCurve, float linearDensity) {
    if (this.isOverLeft(mousePos)) {
      return this.extendLeft(linearDensity, variationCurve);
    }
    if (this.isOverRight(mousePos)) {
      return this.extendRight(linearDensity, variationCurve);
    }
    return null;
  }

  Ribbon duplicate() {
    Vec2D[] newCurve = new Vec2D[this.curve.length];
    for (int i = 0; i < this.curve.length; i++) {
      newCurve[i] = this.curve[i].copy();
    }
    return new Ribbon(newCurve);
  }

  Ribbon getInverted() {
    Vec2D[] invertedCurve = new Vec2D[this.curve.length];
    for (int i = 0; i < this.curve.length; i++) {
      invertedCurve[i] = this.curve[this.curve.length - 1 - i];
    }
    return new Ribbon(invertedCurve);
  }

  ArrayList<Ribbon> cut(Vec2D mousePos, float tolerance) {
    // If is over a button, find the button and cut the ribbon at the center of the button
    for (RibbonEndButtons buttons : this.allButtons) {
      if (buttons.isHoverLeftBank(mousePos.x, mousePos.y) || buttons.isHoverRightBank(mousePos.x, mousePos.y)) {
        // The center is a point from the curve
        // if it is neither the first nor the last point of the curve, cut
        if (buttons.center != this.curve[0] && buttons.center != this.curve[this.curve.length - 1]) {
          return this.cutAtPoint(buttons.center);
        }
      }
    }
    return null;
  }

  ArrayList<Ribbon> createRibbonsFromCut(Vec2D curvePoint) {
    // Find the index of the point in the curve
    int index = -1;
    for (int i = 0; i < this.curve.length; i++) {
      if (this.curve[i] == curvePoint) {
        index = i;
        break;
      }
    }
    if (index == -1) {
      return null;
    }
    // Create the two new curves
    Vec2D[] firstCurve = new Vec2D[index + 1];
    Vec2D[] secondCurve = new Vec2D[this.curve.length - index];
    for (int i = 0; i < firstCurve.length; i++) {
      firstCurve[i] = this.curve[i];
    }
    for (int i = 0; i < secondCurve.length; i++) {
      secondCurve[i] = this.curve[index + i];
    }
    // Create the two new ribbons
    Ribbon firstRibbon = new Ribbon(firstCurve);
    Ribbon secondRibbon = new Ribbon(secondCurve);
    // Assign them a graphDepth
    firstRibbon.graphDepth = this.graphDepth;
    secondRibbon.graphDepth = this.graphDepth;
    // Return the two new ribbons
    ArrayList<Ribbon> newRibbons = new ArrayList<Ribbon>();
    newRibbons.add(firstRibbon);
    newRibbons.add(secondRibbon);
    return newRibbons;
  }

  ArrayList<Ribbon> cutAtPoint(Vec2D curvePoint) {
    // If the Ribbon has already been cut, return null
    if (this.isCut()) {
      return null;
    }

    // If the Ribbon has ribbons on both sides, return null
    if (this.leftRibbons != null && this.rightRibbons != null) {
      return null;
    }

    ArrayList<Ribbon> newRibbons = this.createRibbonsFromCut(curvePoint);

    // If the Ribbon has a exacly one left or right ribbon, attach the new ribbons to the Ribbon
    // And if the Ribbon has no left nor right ribbon, simply return the two new ribbons, do not attach them

    // If there is no left ribbon, attach the new ribbons by the left side
    if (this.leftRibbons == null) {
      this.leftRibbons = newRibbons;
      newRibbons.get(0).assignRightRibbon(this);
      newRibbons.get(1).assignRightRibbon(this);
    }
    // If there is no right ribbon, attach the new ribbons by the right side
    if (this.rightRibbons == null) {
      this.rightRibbons = newRibbons;
      newRibbons.get(0).assignLeftRibbon(this);
      newRibbons.get(1).assignLeftRibbon(this);
    }

    return newRibbons;
  }

  void unlink() {
    if (this.leftRibbons != null) {
      for (Ribbon ribbon : this.leftRibbons) {
        ribbon.rightRibbons = null;
      }
    }
    if (this.rightRibbons != null) {
      for (Ribbon ribbon : this.rightRibbons) {
        ribbon.leftRibbons = null;
      }
    }
    this.leftRibbons = null;
    this.rightRibbons = null;
  }
}

enum TraversalDirection {
  LEFT_TO_RIGHT,
  RIGHT_TO_LEFT
}

class RibbonMemory {
  HashSet<Ribbon> allRibbons = new HashSet<Ribbon>();
  ArrayList<RibbonEndButtons> allButtons = new ArrayList<RibbonEndButtons>();
  Ribbon selectedRibbon = null;
  Ribbon selectedBorderRibbon = null;
  ArrayList<Ribbon> borderRibbons = new ArrayList<Ribbon>();
  ArrayList<Ribbon> originRibbons = new ArrayList<Ribbon>();

  RibbonMemory() {}

  void addRibbon(Ribbon ribbon) {
    this.allRibbons.add(ribbon);
    this.borderRibbons.add(ribbon);
    this.selectedBorderRibbon = ribbon;
    if (!ribbon.hasLeftBank() && !ribbon.hasRightBank()) {
      this.originRibbons.add(ribbon);
    }
    this.refreshOrigins();
    this.refreshBorderRibbons();
    this.addRibbonButtons(ribbon);
  }

  void removeRibbon(Ribbon ribbon) {
    this.allRibbons.remove(ribbon);
    if (this.originRibbons.contains(ribbon)) {
      this.originRibbons.remove(ribbon);
    }
    if (this.borderRibbons.contains(ribbon)) {
      this.borderRibbons.remove(ribbon);
    }
    this.removeRibbonButtons(ribbon);
  }

  boolean isOrigin(Ribbon ribbon) {
    return this.originRibbons.contains(ribbon);
  }

  Ribbon[] getAllRibbons() {
    return this.allRibbons.toArray(new Ribbon[this.allRibbons.size()]);
  }

  void unselectRibbon() {
    if (this.selectedRibbon != null) {
      this.selectedRibbon.removeHighlight();
      this.selectedRibbon = null;
    }
  }

  void selectRibbon(Ribbon ribbon) {
    this.unselectRibbon();

    boolean isNull = ribbon == null;
    boolean isAlreadySelected = !isNull && this.selectedRibbon == ribbon;
    if (isNull || isAlreadySelected) {
      return;
    }

    ribbon.highlight();
    this.selectedRibbon = ribbon;
  }

  Ribbon getSelectedRibbon() {
    return this.selectedRibbon;
  }

  ArrayList<Ribbon> weaveRibbons(ArrayList<Ribbon> ribbons) {
    ArrayList<Ribbon> firstArray = new ArrayList<Ribbon>();
    ArrayList<Ribbon> secondArray = new ArrayList<Ribbon>();
    // For every ribbon in the list
    for (Ribbon ribbon: ribbons) {
      if (ribbon.graphDepth % 2 == 0) {
        firstArray.add(ribbon);
      } else {
        secondArray.add(ribbon);
      }
    }
    firstArray.addAll(secondArray);
    return firstArray;
  }

  ArrayList<Ribbon> orderByGraphDepthAndDistance(ArrayList<Ribbon> ribbons, boolean invert) {
    ArrayList<Ribbon> orderedRibbons = (ArrayList<Ribbon>)ribbons.clone();
    // sort by graphDepth
    Collections.sort(orderedRibbons, new Comparator<Ribbon>() {
      @Override
      public int compare(Ribbon a, Ribbon b) {
        // If the graphDepth is different, sort by graphDepth
        if (a.graphDepth != b.graphDepth) return (a.graphDepth - b.graphDepth) * (invert ? -1 : 1);
        // Otherwise, sort by distance between tail and head
        float distanceDiff = a.getTailToHeadDistanceWith(a) - b.getTailToHeadDistanceWith(b);
        if (distanceDiff == 0) return 0;
        return (distanceDiff > 0 ? 1 : -1) * (invert ? -1 : 1);
      }
    });
    return orderedRibbons;
  }

  /**
   * Take the starting point of a linked list of ribbons and traverse it by following the rightRibbon property
   * to create an array of ribbons
  */
  ArrayList<Ribbon> getRibbonsFromLeftToRight(Ribbon currentRibbon) {
    return ribbonsArrayFromLevelOrderTraversal(currentRibbon, TraversalDirection.LEFT_TO_RIGHT);
  }

  /**
   * Take the starting point of a linked list of ribbons and traverse it by following the leftRibbons property
   * to create an array of ribbons
  */
  ArrayList<Ribbon> getRibbonsFromRightToLeft(Ribbon currentRibbon) {
    return ribbonsArrayFromLevelOrderTraversal(currentRibbon, TraversalDirection.RIGHT_TO_LEFT);
  }

  ArrayList<Ribbon> alternateCurveDirections(ArrayList<Ribbon> ribbons) {
    ArrayList<Ribbon> altRibbons = new ArrayList<Ribbon>();
    // Invert all ribbons with an even graph depth
    for (Ribbon ribbon: ribbons) {
      if (ribbon.graphDepth % 2 == 0) {
        altRibbons.add(ribbon.getInverted());
      } else {
        altRibbons.add(ribbon);
      }
    }
    return altRibbons;
  }

  /**
   * There are six types of (legal) origin ribbons:
   *
   * | schematic | in plain english                      | ie                          |
   * |-----------|---------------------------------------|-----------------------------|
   * |     0     |  no left ribbon    no right ribbon    |                             |
   * |     0—    |  no left ribbon    one right ribbon   | extended right              |
   * |    —0     |  one left ribbon   no right ribbon    | extended left               |
   * |    =0—    |  two left ribbons  one right ribbons  | cut left and extended right |
   * |    —0=    |  one left ribbon   two right ribbons  | extended left and cut right |
   * |    —0—    |  one left ribbon   one right ribbon   | extended left and right     |
   *
   * And three types of (illegal) origin ribbons:
   *
   * | schematic | in plain english                      | ie                 | why illegal?                                                                               |
   * |-----------|---------------------------------------|--------------------|--------------------------------------------------------------------------------------------|
   * |    =0=    |  two left ribbons  two right ribbons  | cut left and right | a ribbon can only be cut once                                                              |
   * |    =0     |  two left ribbons  no right ribbon    | cut left           | when an origin ribbon that has not been extended is cut, it creates two new origin ribbons |
   * |     0=    |  no left ribbon    two right ribbons  | cut right          | same as above                                                                              |
   *
   * This function takes an origin ribbon and returns an array of ribbons in the order they should be drawn
   * it ignores ribbons with no left or right ribbon.
   *
   * If the ribbon has exactly one left ribbon, the method creates one array of ribbons by traversing from left
   * to right starting from this left ribbon, and an other array of ribbons by traversing from right to left
   * starting from the origin ribbon. It then orders the arrays by graph depth, reverses one of the arrays
   * and concatenates the arrays in this order: [...reversed, ...normal]. It then filters out ribbons that have
   * been cut, and returns the resulting array.
   *
   * If the ribbon has exactly one right ribbon, the method works symetrically.
   */
  ArrayList<Ribbon> originToRibbonArray(Ribbon originRibbon) {
    boolean hasRightRibbons = originRibbon.rightRibbons != null;
    boolean hasLeftRibbons = originRibbon.leftRibbons != null;
    int numberOfLeftRibbons = hasLeftRibbons ? originRibbon.leftRibbons.size() : 0;
    int numberOfRightRibbons = hasRightRibbons ? originRibbon.rightRibbons.size() : 0;
    // Throw error if origin ribbon is illegal
    if (
      numberOfLeftRibbons == 2 &&
      numberOfRightRibbons == 2
    ) {
      throw new RuntimeException("Illegal ribbon");
    }
    if (
      numberOfRightRibbons == 2 && !hasLeftRibbons ||
      numberOfLeftRibbons == 2 && !hasRightRibbons
    ) {
      throw new RuntimeException("Illegal origin ribbon");
    }

    // If the origin ribbon has no left or right ribbon, return an empty array
    if (!hasLeftRibbons && !hasRightRibbons) {
      return new ArrayList<Ribbon>();
    }

    Ribbon leftStart = null, rightStart = null;
    // cases 0—, —0— and =0-
    if (numberOfRightRibbons == 1) {
      leftStart = originRibbon;
      rightStart = originRibbon.rightRibbons.get(0);
    }
    // cases —0 and —0=
    else if (numberOfLeftRibbons == 1) {
      leftStart = originRibbon.leftRibbons.get(0);
      rightStart = originRibbon;
    }

    ArrayList<Ribbon> leftRibbons = leftStart != null ? orderByGraphDepthAndDistance(alternateCurveDirections(getRibbonsFromRightToLeft(leftStart)), false) : new ArrayList<Ribbon>();
    ArrayList<Ribbon> rightRibbons = rightStart != null ? orderByGraphDepthAndDistance(alternateCurveDirections(getRibbonsFromLeftToRight(rightStart)), true) : new ArrayList<Ribbon>();

    // Concatenate the arrays
    ArrayList<Ribbon> ribbons = new ArrayList<Ribbon>();
    // Inverted first
    ribbons.addAll(rightRibbons);
    // Normal second
    ribbons.addAll(leftRibbons);

    // Filter out cut ribbons
    ArrayList<Ribbon> filteredRibbons = new ArrayList<Ribbon>();
    for (Ribbon ribbon : ribbons) {
      if (!ribbon.isCut()) {
        filteredRibbons.add(ribbon);
      }
    }

    return filteredRibbons;
  }

  ArrayList<Ribbon> ribbonsArrayFromLevelOrderTraversal(Ribbon origin, TraversalDirection direction) {
    ArrayList<Ribbon> ribbons = new ArrayList<Ribbon>();
    Queue<Ribbon> queue = new LinkedList<Ribbon>();
    queue.add(origin);
    while (!queue.isEmpty()) {
      Ribbon current = queue.poll();
      // Add to array
      ribbons.add(current);
      if (direction == TraversalDirection.RIGHT_TO_LEFT) {
        if (current.leftRibbons != null) {
          queue.addAll(current.leftRibbons);
        }
      } else {
        if (current.rightRibbons != null) {
          queue.addAll(current.rightRibbons);
        }
      }
    }
    return ribbons;
  }

  Ribbon[] getOrderedRibbonsForPlotter(boolean weave) {
    ArrayList<Ribbon> orderedRibbons = this.getRibbonsFromOrigins();
    if (weave) {
      orderedRibbons = this.weaveRibbons(orderedRibbons);
    }
    return orderedRibbons.toArray(new Ribbon[orderedRibbons.size()]);
  }

  ArrayList<Ribbon> getRibbonsFromOrigins() {
    ArrayList<Ribbon> ribbons = new ArrayList<Ribbon>();
    for (Ribbon ribbon : this.originRibbons) {
      ribbons.addAll(this.originToRibbonArray(ribbon));
    }
    return ribbons;
  }

  private void addRibbonButtons(Ribbon ribbon) {
    for (RibbonEndButtons button : ribbon.allButtons) {
      this.allButtons.add(button);
    }
  }

  private void removeRibbonButtons(Ribbon ribbon) {
    for (RibbonEndButtons button : ribbon.allButtons) {
      this.allButtons.remove(button);
    }
  }

  void resetButtonHightlights() {
    for (RibbonEndButtons button : this.allButtons) {
      button.removeHighlights();
    }
  }

  Ribbon isOverButton(Vec2D mousePos) {
    this.resetButtonHightlights();
    ArrayList<RibbonEndButtons> allButtons = this.selectedBorderRibbon == null ? this.allButtons : this.selectedBorderRibbon.allButtons;
    for (RibbonEndButtons button : allButtons) {
      boolean isOverLeft = button.isHoverLeftBank(mousePos.x, mousePos.y);
      boolean isOverRight = button.isHoverRightBank(mousePos.x, mousePos.y);
      if (isOverLeft) {
        button.setLeftHighlight(true);
      }
      if (isOverRight) {
        button.setRightHighlight(true);
      }
      if (isOverLeft || isOverRight) {
        return button.ribbon;
      }
    }
    return null;
  }

  Ribbon isOverRibbon(Vec2D mousePos, float tolerance) {
    float minDist = -1;
    Ribbon closest = null;

    for (Ribbon ribbon : this.allRibbons) {
      float distance = ribbon.isOverCurve(mousePos, tolerance);

      if (distance != -1 && (distance < minDist || minDist == -1)) {
        minDist = distance;
        closest = ribbon;
      }
    }
    // Return the closest ribbon
    return closest;
  }

  void addRibbons(ArrayList<Ribbon> ribbons) {
    Iterator<Ribbon> it = ribbons.iterator();
    while(it.hasNext()) {
      this.addRibbon(it.next());
    }
  }

  Ribbon getSelectedBorderRibbon() {
    return this.selectedBorderRibbon;
  }

  /**
   * Select the next border ribbon in this.borderRibbons
   * If there is no currently selected border ribbon, select the first border ribbon in this.borderRibbons
   */
  void changeSelectedBorderRibbon(int shift) {
    if (this.borderRibbons.size() == 0) {
      return;
    }
    // Find the currently selected border ribbon in this.borderRibbons
    // If there is no currently selected border ribbon, select the first border ribbon in this.borderRibbons
    if (this.selectedBorderRibbon == null) {
      this.selectedBorderRibbon = this.borderRibbons.get(shift > 0 ? 0 : this.borderRibbons.size() - 1);
      return;
    }
    int index = this.borderRibbons.indexOf(this.selectedBorderRibbon);
    int len = this.borderRibbons.size();
    int newIndex = index + shift;
    // if the new index is -1 or len, select null
    if (newIndex == -1 || newIndex == len) {
      this.selectedBorderRibbon = null;
      return;
    }
    this.selectedBorderRibbon = this.borderRibbons.get((newIndex % len) + (newIndex < 0 ? len : 0));
  }

  void selectNextBorderRibbon() {
    this.changeSelectedBorderRibbon(1);
  }

  void selectPreviousBorderRibbon() {
    this.changeSelectedBorderRibbon(-1);
  }

  void unSelectBorderRibbon() {
    this.selectedBorderRibbon = null;
  }

  void refreshOrigins() {
    // If an origin is cut but not extended, unlink it and delete it
    Iterator<Ribbon> origins = this.originRibbons.iterator();
    ArrayList<Ribbon> originsToRefresh = new ArrayList<Ribbon>();
    while(origins.hasNext()) {
      Ribbon ribbon = origins.next();
      if (ribbon.isCut() && !ribbon.isExtended()) {
        originsToRefresh.add(ribbon);
      }
    }
    for (Ribbon ribbon : originsToRefresh) {
      // Make the cut ribbons origin ribbons
      if (ribbon.leftRibbons != null) {
        this.originRibbons.addAll(ribbon.leftRibbons);
      }
      if (ribbon.rightRibbons != null) {
        this.originRibbons.addAll(ribbon.rightRibbons);
      }
      ribbon.unlink();
      this.removeRibbon(ribbon);
    }
  }

  void refreshBorderRibbons() {
    // Go through this.borderRibbons and remove all ribbons that are not border ribbons anymore from this.borderRibbons
    Iterator<Ribbon> it = this.borderRibbons.iterator();
    while(it.hasNext()) {
      Ribbon ribbon = it.next();
      if (!ribbon.isBorderRibbon()) {
        it.remove();
      }
    }
  }
}
