class Target {
  float x, y, radius;
  int colour;

  Target(float x, float y, float radius) {
    this.x = x;
    this.y = y;
    this.radius = radius;
    this.colour = color(255);
  }

  void display() {
    fill(colour);
    stroke(0);
    ellipse(x, y, radius * 2, radius * 2);
  }

  float getX() {
    return x;
  }

  float getY() {
    return y;
  }

  float getRadius() {
    return radius;
  }

  void setColor(int colour) {
    this.colour = colour;
  }

  boolean isClicked(float px, float py) {
    return dist(px, py, x, y) <= radius;
  }

  float intersectionLength(float x1, float y1, float x2, float y2) {
    float dx = x2 - x1;
    float dy = y2 - y1;
    float fx = x1 - x;
    float fy = y1 - y;
    float a = dx * dx + dy * dy;
    float b = 2 * (fx * dx + fy * dy);
    float c = (fx * fx + fy * fy) - radius * radius;
    float discriminant = b * b - 4 * a * c;

    if (discriminant < 0) {
      return 0; // No intersection
    } else {
      discriminant = sqrt(discriminant);
      float t1 = (-b - discriminant) / (2 * a);
      float t2 = (-b + discriminant) / (2 * a);

      if ((t1 < 0 && t2 < 0) || (t1 > 1 && t2 > 1)) return 0;

      // Clamp the intersection points to the segment limits
      t1 = max(0, min(t1, 1));
      t2 = max(0, min(t2, 1));

      // Calculate the intersection points
      float inX1 = x1 + t1 * dx;
      float inY1 = y1 + t1 * dy;
      float inX2 = x1 + t2 * dx;
      float inY2 = y1 + t2 * dy;

      return dist(inX1, inY1, inX2, inY2);
    }
  }
}