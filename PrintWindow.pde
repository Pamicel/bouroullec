class PrintWindow extends PApplet {
  public String path = "";
  public PImage image = null;
  boolean showPosition = true;
  DisplayWindow displayWindow = null;
  private float currentResRatio = 1.0;
  boolean initialized = false;

  PrintWindow() {
    super();
    PApplet.runSketch(new String[]{this.getClass().getName()}, this);
  }

  void settings() {
    size(600, 600);
  }

  void setup() {
    this.surface.setLocation(PRINT_WIN_XY[0], PRINT_WIN_XY[1]);
    this.surface.setResizable(true);
  }

  public void setImage(PImage img) {
    this.image = img;
    float resRatio = (float)this.image.width / this.image.height;
    if (this.currentResRatio != resRatio) {
      this.currentResRatio = resRatio;
      if (resRatio > 1) {
        this.surface.setSize(this.width, round(this.height / resRatio));
      } else {
        this.surface.setSize(round(this.width * resRatio), this.height);
      }
    }
    this.initialized = true;
    this.loop();
  }

  void draw() {
    if (!initialized) {
      push();
      textSize(30);
      textAlign(CENTER, CENTER);
      fill(0);
      text("Press space in display window", width / 2, height / 2);
      pop();
    }
    if (image != null) {
      this.image(this.image, 0, 0, this.width, this.height);
    }
    if (showPosition && this.displayWindow != null) {
      fill(0, 0, 0, 20);
      noStroke();
      rect(
        this.displayWindow.pos.x * this.width,
        this.displayWindow.pos.y * this.height,
        this.width * this.displayWindow.xRatio,
        this.height * this.displayWindow.yRatio
      );
    }
    this.noLoop();
  }

  void mouseMoved() {
    loop();
  }

  void keyPressed() {
    if (key == ' ') {
      this.showPosition = !this.showPosition;
    }
  }
}
