import java.util.ArrayList;
import processing.core.PGraphics;

public class Brush {
  private float paintAmount;
  private int[] paintColor = new int[3];
  private ArrayList<Bristle> bristles = new ArrayList<Bristle>();
  private float scaleFactor;

  public Brush() {
    this(new int[] {0, 0, 0});
  }

  public Brush(int[] c) {
    this.paintColor = c;
    this.paintAmount = 0.0f;
    this.scaleFactor = 30f;
  }

  public void changeColor(int[] c) {
    this.paintColor = c;
  }

  public int[] getColor() {
    return this.paintColor;
  }

  public void setScale(float s) {
    this.scaleFactor = s;
  }
  
  public float getScale() {
    return this.scaleFactor;
  }

  public void addBristle(Bristle b) {
    this.bristles.add(b);
  }

  public int numBristles() {
    return this.bristles.size();
  }

  public ArrayList<Bristle> getBristles() {
    return this.bristles;
  }
  
  public void larger(float amount){
    scaleFactor += amount;
  }
  
  public void smaller(float amount){
    scaleFactor -= amount;
    if (scaleFactor < 1f) {
      scaleFactor = 1f;
    }
  }

  public void paint(PGraphics layer, float x, float y) {
    layer.ellipse(x, y, scaleFactor, scaleFactor);
  }
}
