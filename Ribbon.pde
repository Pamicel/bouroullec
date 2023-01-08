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
    layer.push();
    // Highlight with a red circle
    if (this.highlight) {
      layer.fill(255, 0, 0);
      layer.noStroke();
      layer.circle(this.midPoint.x, this.midPoint.y, this.arrowLength);
    }
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

  RibbonEndButtons frontButtons = null,
                  backButtons = null;

  ArrayList<RibbonEndButtons> allButtons = new ArrayList<RibbonEndButtons>();

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

  void displayEndButtons(PGraphics layer) {
    for (RibbonEndButtons buttons : this.allButtons) {
      buttons.display(layer);
    }
    // if (this.frontButtons != null && this.backButtons != null) {
    //   this.frontButtons.display(layer);
    //   this.backButtons.display(layer);
    // }
  }

  Ribbon createAndAssignLeftRibbon(float linearDensity, Vec2D[] variationCurve) {
    Ribbon newRibbon = this.createLeftRibbon(linearDensity, variationCurve);
    if (newRibbon != null) {
      this.assignLeftRibbon(newRibbon);
      newRibbon.assignRightRibbon(this);
      // TODO: Remove left buttons
    }
    return newRibbon;
  }

  Ribbon createAndAssignRightRibbon(float linearDensity, Vec2D[] variationCurve) {
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
      return this.createAndAssignLeftRibbon(linearDensity, variationCurve);
    }
    if (this.isOverRight(mousePos)) {
      return this.createAndAssignRightRibbon(linearDensity, variationCurve);
    }
    return null;
  }

  Ribbon getInverted() {
    Vec2D[] invertedCurve = new Vec2D[this.curve.length];
    for (int i = 0; i < this.curve.length; i++) {
      invertedCurve[i] = this.curve[this.curve.length - 1 - i];
    }
    return new Ribbon(invertedCurve);
  }
}

class RibbonMemory {
  HashSet<Ribbon> allRibbons = new HashSet<Ribbon>();
  ArrayList<RibbonEndButtons> allButtons = new ArrayList<RibbonEndButtons>();
  Ribbon selectedRibbon = null;

  RibbonMemory() {}

  void addRibbon(Ribbon ribbon) {
    this.allRibbons.add(ribbon);
    this.addRibbonButtons(ribbon);
  }

  void removeRibbon(Ribbon ribbon) {
    this.allRibbons.remove(ribbon);
    this.removeRibbonButtons(ribbon);
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

  /**
   * Take a list of ribbons eg [ R1, R2, R3, R4, R5, R6, R7, R8, R9, R10 ]
   * and return a list of ribbons in the order they should be drawn
   * ie [ R1, R3, R5, R7, R9, R2, R4, R6, R8, R10 ]
  */
  ArrayList<Ribbon> weaveRibbonsForPlotter(Ribbon currentRibbon) {
    return this.weaveRibbonsForPlotter(currentRibbon, new ArrayList<Ribbon>(), new ArrayList<Ribbon>());
  }
  ArrayList<Ribbon> weaveRibbonsForPlotter(Ribbon currentRibbon, ArrayList<Ribbon> firstArray, ArrayList<Ribbon> secondArray) {
    // Add current ribbon to first array
    firstArray.add(currentRibbon);

    // if current ribbon has right ribbon
    if (currentRibbon.rightRibbon != null) {
      // Call function with right ribbon and first and second array in reverse order
      return this.weaveRibbonsForPlotter(currentRibbon.rightRibbon, secondArray, firstArray);
    }
    // if not
    else {
      // Add second array to first array
      firstArray.addAll(secondArray);
      // Return first array
      return firstArray;
    }
  }

  Ribbon[] getOrderedRibbonsForPlotter() {
    ArrayList<Ribbon> orderedRibbons = new ArrayList<Ribbon>();
    ArrayList<Ribbon> ribbons = new ArrayList<Ribbon>(this.allRibbons);
    ArrayList<Ribbon> startingPoints = new ArrayList<Ribbon>();
    for (Ribbon ribbon : ribbons) {
      // Put all ribbons with no neighbors in the ordered list
      if (ribbon.leftRibbon == null && ribbon.rightRibbon == null) {
        orderedRibbons.add(ribbon);
      }
      // and all ribbons with a right ribbon but no left ribbon in the starting points list
      else if (ribbon.leftRibbon == null && ribbon.rightRibbon != null) {
        startingPoints.add(ribbon);
      }
    }
    // Follow from each starting point, weave them into a list and add them to the ordered list
    for (Ribbon startingPoint : startingPoints) {
      orderedRibbons.addAll(this.weaveRibbonsForPlotter(startingPoint));
    }
    // Invert all ribbons with an even index in both lists
    for (int i = 0; i < orderedRibbons.size(); i++) {
      if (i % 2 == 0) {
        orderedRibbons.set(i, orderedRibbons.get(i).getInverted());
      }
    }

    return orderedRibbons.toArray(new Ribbon[orderedRibbons.size()]);
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
    for (RibbonEndButtons button : this.allButtons) {
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
}
