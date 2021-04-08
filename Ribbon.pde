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
  ArrayList<Vec2D[]> curves = new ArrayList<Vec2D[]>();
  ArrayList<Vec2D[]> normals = new ArrayList<Vec2D[]>();
  RibbonEndButtons frontButtons = null,
                  backButtons = null;
  Ribbon leftRibbon = null,
        rightRibbon = null;

  float ribbonWid = 5.0;

  Ribbon(Vec2D[] curve) {
    this.addToBack(curve);
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

  void addToBack(Vec2D[] curve) {
    if (curve.length <= 1) {
      return;
    }

    Vec2D[] processedCurve;

    int curvesLen = this.curves.size();
    if (curvesLen != 0) {
      Vec2D[] endCurve = this.curves.get(curvesLen - 1);
      Vec2D referencePoint = endCurve[endCurve.length - 1];
      Vec2D translation = referencePoint.sub(curve[0]);
      // translate
      processedCurve = new Vec2D[curve.length];
      for (int i = 0; i < curve.length; i++) {
        processedCurve[i] = curve[i].add(translation);
      }
    } else {
      processedCurve = curve;
    }

    this.normals.add(this.computeCurveNormals(processedCurve));
    this.curves.add(processedCurve);
  }

  void addToFront(Vec2D[] curve) {
    if (curve.length <= 1) {
      return;
    }

    Vec2D translation = new Vec2D(0, 0);

    if (this.curves.size() != 0) {
      Vec2D[] frontCurve = this.curves.get(0);
      Vec2D referencePoint = frontCurve[0];
      translation = referencePoint.sub(curve[0]);
    }

    // translate
    Vec2D[] processedCurve = new Vec2D[curve.length];
    for (int i = 0; i < curve.length; i++) {
      processedCurve[i] = curve[curve.length - i - 1].add(translation);
    }


    this.normals.add(0, this.computeCurveNormals(processedCurve));
    this.curves.add(0, processedCurve);
  }

  void displayCurve(PGraphics layer) {
    int curveLen = this.curves.size();
    if (curveLen == 0) {
      return;
    }

    layer.stroke(0);
    layer.noFill();
    layer.beginShape();
    Vec2D pos;
    Vec2D[] currentCurve;
    for (int curveIndex = 0; curveIndex < curveLen; curveIndex++) {
      currentCurve = this.curves.get(curveIndex);
      for (int i = 0; i < currentCurve.length; i++) {
        pos = currentCurve[i];
        layer.circle(pos.x, pos.y, this.ribbonWid / 10);
        layer.vertex(pos.x, pos.y);
      }
    }
    layer.endShape();
  }

  void displayCurveSmooth(PGraphics layer) {
    int curveLen = this.curves.size();
    if (curveLen == 0) {
      return;
    }

    layer.stroke(0);
    layer.noFill();
    layer.beginShape();
    Vec2D pos;
    Vec2D[] currentCurve;
    for (int curveIndex = 0; curveIndex < curveLen; curveIndex++) {
      currentCurve = this.curves.get(curveIndex);
      for (int i = 0; i < currentCurve.length; i++) {
        pos = currentCurve[i];
        layer.curveVertex(pos.x, pos.y);
        // double first and last
        if (i == 0 || i == currentCurve.length - 1) {
          layer.curveVertex(pos.x, pos.y);
        }
      }
    }
    layer.endShape();
  }

  void displayNormals(PGraphics layer, int len) {
    int normalsLen = this.normals.size();
    Vec2D start, end;
    Vec2D[] currentNormals, currentCurve;

    for (int index = 0; index < normalsLen; index++) {
      currentNormals = this.normals.get(index);
      currentCurve = this.curves.get(index);
      for (int i = 0; i < currentNormals.length; i++) {
        start = currentCurve[i];
        end = start.add(currentNormals[i].getNormalizedTo(len));
        layer.line(start.x, start.y, end.x, end.y);
        layer.push();
        layer.fill(255, 0, 0);
        layer.noStroke();
        layer.circle(end.x, end.y, 3);
        layer.pop();
      }
    }
  }

  Ribbon createLeftRibbon(float linearDensity) {
    Ribbon newRibbon = null;
    for (int i = 0; i < this.curves.size(); i++) {
      Vec2D[] currentCurve = this.curves.get(i);
      Vec2D[] currentNormals = this.normals.get(i);
      Vec2D[] newCurve = new Vec2D[currentCurve.length];
      for (int index = 0; index < newCurve.length; index++) {
        newCurve[index] = currentCurve[index].copy().add(currentNormals[index].getNormalizedTo(this.ribbonWid));
      }
      newCurve = densityResample(newCurve, linearDensity);

      if (newRibbon == null) {
        newRibbon = new Ribbon(newCurve);
      } else {
        newRibbon.addToBack(newCurve);
      }
    }

    return newRibbon;
  }

  Ribbon createRightRibbon(float linearDensity) {
    Ribbon newRibbon = null;
    for (int i = 0; i < this.curves.size(); i++) {
      Vec2D[] currentCurve = this.curves.get(i);
      Vec2D[] currentNormals = this.normals.get(i);
      Vec2D[] newCurve = new Vec2D[currentCurve.length];
      for (int index = 0; index < newCurve.length; index++) {
        newCurve[index] = currentCurve[index].copy().sub(currentNormals[index].getNormalizedTo(this.ribbonWid));
      }
      newCurve = densityResample(newCurve, linearDensity);

      if (newRibbon == null) {
        newRibbon = new Ribbon(newCurve);
      } else {
        newRibbon.addToBack(newCurve);
      }
    }

    return newRibbon;
  }

  Ribbon createRightRibbon(float linearDensity, Vec2D[] variationCurve) {
    Ribbon newRibbon = this.createRightRibbon(linearDensity);
    if (variationCurve != null) {
      // invert the variationCurve
      for (int i = 0; i < variationCurve.length; i++) {
        variationCurve[i] = variationCurve[i].getInverted();
      }
      newRibbon.applyVariationCurve(variationCurve);
    }
    return newRibbon;
  }

  Ribbon createLeftRibbon(float linearDensity, Vec2D[] variationCurve) {
    Ribbon newRibbon = this.createLeftRibbon(linearDensity);
    if (variationCurve != null) {
      newRibbon.applyVariationCurve(variationCurve);
    }
    return newRibbon;
  }

  void applyVariationCurve(Vec2D[] variationCurve) {
    int totalSize = 0;
    for (int i = 0; i < this.curves.size(); i++) {
      totalSize += this.curves.get(i).length;
    }

    Vec2D[] resampledVariationCurve = regularResample(variationCurve, totalSize);

    int vcIndex = 0;
    Vec2D[] currentCurve, currentNormals;
    for (int i = 0; i < this.curves.size(); i++) {
      currentCurve = this.curves.get(i);
      currentNormals = this.normals.get(i);
      for (int j = 0; j < currentCurve.length; j++) {
        currentCurve[j] = currentCurve[j].add(currentNormals[j].getNormalizedTo(this.ribbonWid * resampledVariationCurve[vcIndex++].y));
      }
    }

    this.computeEndButtons();
  }

  private Vec2D[] computeCurveNormals(Vec2D[] curve) {
    Vec2D[] curveNormals = new Vec2D[curve.length];
    curveNormals[0] = curve[0].sub(curve[1]).getRotated(HALF_PI).getNormalized();
    curveNormals[curve.length - 1] = curve[curve.length - 2].sub(curve[curve.length - 1]).getRotated(HALF_PI).getNormalized();
    for (int i = 1; i < curve.length - 1; i++) {
      curveNormals[i] = curve[i - 1].sub(curve[i + 1]).getRotated(HALF_PI).getNormalized();
    }

    return curveNormals;
  }

  void computeEndButtons() {
    int len = this.curves.size();
    Vec2D[] firstCurve = this.curves.get(0);
    Vec2D[] lastCurve = this.curves.get(len - 1);

    this.frontButtons = new RibbonEndButtons();
    this.backButtons = new RibbonEndButtons();

    this.frontButtons.center = firstCurve[0];
    this.frontButtons.leftBank = firstCurve[0].add(firstCurve[1].sub(firstCurve[0]).getRotated(-HALF_PI).getNormalizedTo(this.ribbonWid / 2));
    this.frontButtons.rightBank = firstCurve[0].add(firstCurve[1].sub(firstCurve[0]).getRotated(HALF_PI).getNormalizedTo(this.ribbonWid / 2));
    this.backButtons.rightBank = lastCurve[lastCurve.length - 1].add(lastCurve[lastCurve.length - 2].sub(lastCurve[lastCurve.length - 1]).getRotated(-HALF_PI).getNormalizedTo(this.ribbonWid / 2));
    this.backButtons.leftBank = lastCurve[lastCurve.length - 1].add(lastCurve[lastCurve.length - 2].sub(lastCurve[lastCurve.length - 1]).getRotated(HALF_PI).getNormalizedTo(this.ribbonWid / 2));
    this.backButtons.center = lastCurve[lastCurve.length - 1];
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
  }

  ArrayList<Ribbon> getRibbonsAt(int mX, int mY) {
    int index = this.positionIndex(new Vec2D(mX, mY));
    if (index < 0) return null;
    if (this.ribbons[index] != null) {
      return this.ribbons[index];
    }
    return null;
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