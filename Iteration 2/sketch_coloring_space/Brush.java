import java.util.ArrayList;

public class Brush {
  private float paintAmount;
  private int[] paintColor = new int[3];
  private ArrayList<Bristle> bristles;
  private float scaleFactor;

  public Brush() {
    this(new int[] {0, 0, 0});
  }

  public Brush(int[] c){
    this.paintColor = c;
    this.paintAmount = 0.0f;
    this.scaleFactor = 1;
  }
  
  public void changeColor(int[] c){
    this.paintColor = c;
  }
  
  public int[] getColor(){
    return this.paintColor;
  }
  
  public void setScale(float s){
    this.scaleFactor = s;
  }
  
  public void addBristle(Bristle b){
    this.bristles.add(b);
  }
  
  public int size(){
    return this.bristles.size();
  }
  
  public ArrayList<Bristle> getBristles(){
    return this.bristles;
  }
}
