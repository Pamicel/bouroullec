class RibbonEndButtons {
  Vec2D rightBank, leftBank, center;
  float radius = 5;
  RibbonEndButtons () {}

  private boolean isHover(Vec2D position, int mX, int mY) {
    return position.distanceToSquared(new Vec2D(mX, mY)) < (this.radius * this.radius);
  }

  boolean isHoverLeftBank(int mX, int mY) {
    return this.leftBank != null && this.isHover(this.leftBank, mX, mY);
  }
  boolean isHoverRightBank(int mX, int mY) {
    return this.rightBank != null && this.isHover(this.rightBank, mX, mY);
  }
  boolean isHoverCenter(int mX, int mY) {
    return this.center != null && this.isHover(this.center, mX, mY);
  }

  void deleteLeftBank() {
    this.leftBank = null;
  }
  void deleteRightBank() {
    this.rightBank = null;
  }
  void deleteCenter() {
    this.center = null;
  }

  void display(PGraphics layer) {
    layer.noStroke();
    if (this.center != null) {
      layer.fill(255, 0, 0);
      layer.circle(this.center.x, this.center.y, this.radius);
    }
    if (this.rightBank != null) {
      layer.fill(0, 255, 0);
      layer.circle(this.rightBank.x, this.rightBank.y, this.radius);
    }
    if (this.leftBank != null) {
      layer.fill(0, 0, 255);
      layer.circle(this.leftBank.x, this.leftBank.y, this.radius);
    }
  }
}

class Ribbon {
  Vec2D[] curve = new Vec2D[0];
  Vec2D[] normals = new Vec2D[0];

  RibbonEndButtons frontButtons = null,
                  backButtons = null;

  Ribbon leftRibbon = null,
        rightRibbon = null;

  float ribbonWid = RIBON_WID;

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

  boolean isOverButton(int mX, int mY) {
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
    return this.backButtons.rightBank != null && this.frontButtons.rightBank != null;
  }
  boolean hasLeftBank() {
    return this.backButtons.leftBank != null && this.frontButtons.leftBank != null;
  }

  void assignLeftRibbon(Ribbon leftRibbon) {
    this.leftRibbon = leftRibbon;
    this.frontButtons.deleteLeftBank();
    this.backButtons.deleteLeftBank();
  }

  void assignRightRibbon(Ribbon rightRibbon) {
    this.rightRibbon = rightRibbon;
    this.frontButtons.deleteRightBank();
    this.backButtons.deleteRightBank();
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
    layer.strokeWeight(2);
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
    layer.stroke(0);
    layer.strokeWeight(1);
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
      newCurve[index] = this.curve[index].copy().add(this.normals[index].getNormalizedTo(this.ribbonWid));
    }

    newCurve = densityResample(newCurve, linearDensity);
    if (newCurve.length < 2) { return null; }
    return new Ribbon(newCurve, variationCurve);
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
      newCurve[index] = this.curve[index].copy().sub(this.normals[index].getNormalizedTo(this.ribbonWid));
    }
    newCurve = densityResample(newCurve, linearDensity);

    if (newCurve.length < 2) { return null; }
    return new Ribbon(newCurve, invertedVariationCurve);
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
      this.curve[j] = this.curve[j].add(this.normals[j].getNormalizedTo(this.ribbonWid * resampledVariations[j].y));
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

    this.frontButtons = new RibbonEndButtons();
    this.backButtons = new RibbonEndButtons();

    this.frontButtons.center = firstPoint;
    this.frontButtons.leftBank = firstPoint.add(secondPoint.sub(firstPoint).getRotated(-HALF_PI).getNormalizedTo(this.ribbonWid / 2));
    this.frontButtons.rightBank = firstPoint.add(secondPoint.sub(firstPoint).getRotated(HALF_PI).getNormalizedTo(this.ribbonWid / 2));
    this.backButtons.rightBank = lastPoint.add(beforeLastPoint.sub(lastPoint).getRotated(-HALF_PI).getNormalizedTo(this.ribbonWid / 2));
    this.backButtons.leftBank = lastPoint.add(beforeLastPoint.sub(lastPoint).getRotated(HALF_PI).getNormalizedTo(this.ribbonWid / 2));
    this.backButtons.center = lastPoint;
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

  ArrayList<Ribbon> getRibbonsAt(int mX, int mY) {
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
    indices.add(this.positionIndex(ribbon.frontButtons.center));
    indices.add(this.positionIndex(ribbon.frontButtons.leftBank));
    indices.add(this.positionIndex(ribbon.frontButtons.rightBank));
    indices.add(this.positionIndex(ribbon.backButtons.center));
    indices.add(this.positionIndex(ribbon.backButtons.leftBank));
    indices.add(this.positionIndex(ribbon.backButtons.rightBank));
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
    indices.add(this.positionIndex(ribbon.frontButtons.center));
    indices.add(this.positionIndex(ribbon.frontButtons.leftBank));
    indices.add(this.positionIndex(ribbon.frontButtons.rightBank));
    indices.add(this.positionIndex(ribbon.backButtons.center));
    indices.add(this.positionIndex(ribbon.backButtons.leftBank));
    indices.add(this.positionIndex(ribbon.backButtons.rightBank));

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