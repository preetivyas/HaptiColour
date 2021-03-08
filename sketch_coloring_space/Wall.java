public class Wall {
  private float w; // wall width
  private float h; // wall height
  private float x; // x position of top left corner
  private float y; // y position of top left corner
  private int c;   // color
  
  public Wall(float w, float h, float x, float y, int c){
    this.w = w;
    this.h = h;
    this.x = x;
    this.y = y;
    this.c = c;
  }
  
  public float getW(){
    return this.w;
  }
  
  public float getH(){
    return this.h;
  }
  
  public float getX(){
    return this.x;
  }
  
  public float getY(){
    return this.y;
  }
  
  public int getColor(){
    return this.c;
  }
  
  public void setColor(int newColor){
    this.c = newColor;
  }
}
