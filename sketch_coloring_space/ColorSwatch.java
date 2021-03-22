public class ColorSwatch{
  private int r;
  private int g;
  private int b;
  
  public ColorSwatch(int r, int g, int b){
    this.r = r;
    this.g = g;
    this.b = b;
  }
  
  public int getRed(){
    return this.r;
  }
  
  public int getGreen(){
    return this.g;
  }
  
  public int getBlue(){
    return this.b;
  }
  
  public int[] getColor(){
    int[] ret = {this.r, this.g, this.b};
    return ret;
  }
  
  public void setColor(int[] c){
    this.r = c[0];
    this.g = c[1];
    this.b = c[2];
  }
  
}
