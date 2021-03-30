import toxi.geom.*;

ArrayList<Vec2D> curve = new ArrayList<Vec2D>();

int RESAMPLE_SIZE = 200;

class Mesh {
  Vec2D[] startCurve = null,
          finishCurve = null,
          sideStartCurve = null,
          sideStopCurve = null;

  Vec2D[][] positions = null,
            rectangleMesh = null;

  float linearDensity;

  Mesh(float linearDensity) {
    this.linearDensity = linearDensity;
  }

  boolean allCurvesSet() {
    return (
      this.sideStartCurve != null &&
      this.sideStopCurve != null &&
      this.startCurve != null &&
      this.finishCurve != null
    );
  }

  boolean meshSet() {
    return this.positions != null;
  }

  void displayCurve(Vec2D[] curve) {
    Vec2D pos;
    push();
    stroke(0, 0, 255);
    beginShape();
    for (int i = 0; i < curve.length; i++) {
      pos = curve[i];
      vertex(pos.x, pos.y);
      circle(pos.x, pos.y, 5);
    }
    endShape();
    pop();
  }

  void displayMesh() {
    Vec2D pos;
    push();
    stroke(255, 0, 0);
    for (int i = 0; i < this.positions.length; i++) {
      for (int j = 0; j < this.positions[i].length; j++) {
        pos = this.positions[i][j];
        circle(pos.x, pos.y, 5);
      }
    }
    pop();
  }

  void display() {
    if (this.startCurve != null) {
      this.displayCurve(this.startCurve);
    }
    if (this.finishCurve != null) {
      this.displayCurve(this.finishCurve);
    }
    if (this.sideStartCurve != null) {
      this.displayCurve(this.sideStartCurve);
    }
    if (this.sideStopCurve != null) {
      this.displayCurve(this.sideStopCurve);
    }

    if (this.meshSet()) {
      this.displayMesh();
    }
  }

  private Vec2D[] regularCurveFromArrayList(ArrayList<Vec2D> curve) {
    float distSum = 0;
    int curveLen = curve.size();
    for (int i = 0; i < curveLen - 1; i++) {
      distSum += curve.get(i).distanceTo(curve.get(i + 1));
    }
    int resampleSize = floor(this.linearDensity * distSum);
    return regularResample(curve, resampleSize);
  }

  void addCurve(ArrayList<Vec2D> curve) {
    if (this.startCurve == null) {
      println("setStartCurve");
      this.setStartCurve(curve);
    } else if (this.sideStartCurve == null) {
      println("setSideStartCurve");
      this.setSideStartCurve(curve);
    } else if (this.finishCurve == null) {
      println("setFinishCurve");
      this.setFinishCurve(curve);
    } else if (this.sideStopCurve == null) {
      println("setSideStopCurve");
      this.setSideStopCurve(curve);
    }
  }

  void setFinishCurve(ArrayList<Vec2D> curve) {
    if (this.startCurve == null) {
      throw new Error("Cannot set finish curve before start curve");
    }
    // finish curve must have the same length as the start curve
    this.finishCurve = regularResample(curve, this.startCurve.length);
  }

  void setStartCurve(ArrayList<Vec2D> curve) {
    this.startCurve = this.regularCurveFromArrayList(curve);
  }

  void setSideStopCurve(ArrayList<Vec2D> curve) {
    if (this.sideStartCurve == null) {
      throw new Error("Cannot set side-stop curve before side-start curve");
    }
    // side-stop curve must have the same length as the side-start curve
    this.sideStopCurve = regularResample(curve, this.sideStartCurve.length);
  }

  void setSideStartCurve(ArrayList<Vec2D> curve) {
    this.sideStartCurve = this.regularCurveFromArrayList(curve);
  }

  void alignCurves() {
    if (!this.allCurvesSet()) {
      // throw new Error("Need all 4 curves to align curves");
      return;
    }
    this.sideStartCurve = remapCurve(this.sideStartCurve, this.startCurve[0], this.finishCurve[0]);
    this.sideStopCurve = remapCurve(this.sideStopCurve, this.startCurve[this.startCurve.length - 1], this.finishCurve[this.finishCurve.length - 1]);
  }

  void computeMesh() {
    if (!this.allCurvesSet()) {
      throw new Error("Need all 4 curves to compute the mesh");
    }

    int lsf = this.startCurve.length - 1; // num of segments in each start and finish
    int lside = this.sideStartCurve.length - 1; // num of segments in each sides


    this.positions = new Vec2D[this.sideStartCurve.length][this.startCurve.length];
    this.positions[0][0] = this.startCurve[0];

    Vec2D pointOnStart,
          pointOnFinish,
          pointOnSideStart,
          pointOnSideStop,
          startToFinish,
          sideToSide;

    // FIX
    for (int i = 0; i <= lside; i++) {
      for (int j = 0; j <= lsf; j++) {
        pointOnStart = this.startCurve[j];
        pointOnFinish = this.finishCurve[j];
        pointOnSideStart = this.sideStartCurve[i];
        pointOnSideStop = this.sideStopCurve[i];
        float sfRatio = (float)j/(float)(lsf + 1);
        float sideRatio = (float)i/(float)(lside + 1);

        startToFinish = pointOnFinish.sub(pointOnStart).scale(sideRatio);
        sideToSide = pointOnSideStop.sub(pointOnSideStart).scale(sfRatio);

        this.positions[i][j] = pointOnStart.add(startToFinish).add(pointOnSideStart).add(sideToSide).scale(.5);
      }
    }
  }
}

Mesh mesh = new Mesh(1.0 / 10.0);

void setup() {
  size(800, 800);
  for (int i = 0; i < newCurve.length; i++) {
    newCurve[i] = new Vec2D(0,0);
  }
  for (int i = 0; i < newRegularCurve.length; i++) {
    newRegularCurve[i] = new Vec2D(0,0);
  }
  for (int i = 0; i < newRemappedCurve.length; i++) {
    newRemappedCurve[i] = new Vec2D(0,0);
  }
  noFill();
}

float signedAngle(Vec2D pos) {
  Vec2D normalVector = new Vec2D(1,0);
  float angle = acos(pos.getNormalized().dot(normalVector));
  if (pos.sub(normalVector).y < 0) {
    angle = -angle;
  }
  return angle;
}

Vec2D pos = new Vec2D(0, 0);
void draw() {
  background(255);

  Vec2D pos;
  if (mousePressed) {
    stroke(0);
    beginShape();
    for (int i = 0; i < curve.size(); i++) {
      pos = curve.get(i);
      circle(pos.x, pos.y, 5);
      vertex(pos.x, pos.y);
    }
    endShape();
  }

  mesh.display();


  // stroke(255, 0, 0);
  // beginShape();
  // for (int i = 0; i < newCurve.length; i++) {
  //   pos = newCurve[i];
  //   vertex(pos.x, pos.y);
  //   circle(pos.x, pos.y, 5);
  // }
  // endShape();

  // stroke(0, 255, 0);
  // beginShape();
  // for (int i = 0; i < newRegularCurve.length; i++) {
  //   pos = newRegularCurve[i];
  //   vertex(pos.x, pos.y);
  //   circle(pos.x, pos.y, 5);
  // }
  // endShape();

  // stroke(0, 0, 255);
  // beginShape();
  // for (int i = 0; i < newRemappedCurve.length; i++) {
  //   pos = newRemappedCurve[i];
  //   vertex(pos.x, pos.y);
  //   circle(pos.x, pos.y, 5);
  // }
  // endShape();

}

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

void mouseDragged() {
  curve.add(new Vec2D(mouseX, mouseY));
}

void mousePressed() {
  curve = new ArrayList<Vec2D>();
}

void mouseReleased() {
  if (!mesh.allCurvesSet()) {
    mesh.addCurve(curve);
    if (mesh.allCurvesSet()) {
      mesh.alignCurves();
      mesh.computeMesh();
    }
  }
}