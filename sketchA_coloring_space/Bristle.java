public class Bristle {
  private float weight;
  private Brush brush;
  private int[] index = new int[2];
  private float opacity;
  private float scaleFactor;
  private Boolean middleEdge = false;
  
  public Bristle(float w, Brush b, int[] coords){
    this.weight = w;
    this.brush = b;
    this.index[0] = coords[0];
    this.index[1] = coords[1];
  }
  
  public void setMiddleEdge(Boolean b){
    this.middleEdge = b;
  }
  
  public Boolean isMiddleEdge(){
    return this.middleEdge;
  }
}
