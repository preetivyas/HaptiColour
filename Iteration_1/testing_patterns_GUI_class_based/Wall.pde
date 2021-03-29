import processing.serial.*;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*;
import controlP5.*;


public class Wall {
  private float w; // wall width
  private float h; // wall height
  private float x; // x position of top left corner
  private float y; // y position of top left corner
  private int c;   // color
  private int density; //density
  
  public Wall(float w, float h, float x, float y, int c){
    this.w = w;
    this.h = h;
    this.x = x;
    this.y = y;
    this.c = c;
    this.density = 100;
  }
  
  public FBox getFBox(){
    FBox wall = new FBox(this.w, this.h);
    wall.setPosition(this.x, this.y);
    wall.setStatic(true);
    wall.setFill(this.c);
    wall.setDensity(this.density);
    wall.setSensor(true);
    wall.setNoStroke();
    return wall;
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
  
}
