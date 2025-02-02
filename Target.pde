class Target {
    float x, y, radius;
    int colour;
    
    Target(float x, float y, float radius) {
        this.x = x;
        this.y = y;
        this.radius = radius;
        this.colour = color(255); // Default white
    }
    
    void display() {
        fill(colour);
        stroke(0);
        ellipse(x, y, radius * 2, radius * 2);
    }
    
    void setColor(int colour) {
        this.colour = colour;
    }
    
    boolean isClicked(float px, float py) {
        return dist(px, py, x, y) <= radius;
    }
}