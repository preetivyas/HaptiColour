import java.util.ArrayList;
import processing.core.PGraphics;
import processing.core.PImage;
import processing.core.PApplet;
import static java.lang.Math.*;

public class Brush extends PApplet{
  public final int NUM_BRUSH_TYPES = 6;
  private float paintAmount;
  private int[] paintColor = new int[3];
  private ArrayList<Bristle> bristles = new ArrayList<Bristle>();
  private float scaleFactor;
  private int brushType;

  //PV added these variables
  private float angle;
  private float prevX = 0;
  private float prevY = 0;
  String[] button_img = {"../img/brush1.png", "../img/brush2.png", "../img/brush3.png", 
  "../img/brush4.png", "../img/brush5.png", "../img/brush6.png", 
  "../img/brush7.png", "../img/brush8.png", "../img/brush9.png", 
  "../img/brush10.png"};
  PImage brush;


  public Brush(PImage brush) {
    this(new int[] {0, 0, 0}, brush);
  }

  public Brush(int[] c, PImage brush) {
    this.paintColor = c;
    this.paintAmount = 0.0f;
    this.scaleFactor = 30f;
    this.brushType = 0;
    this.brush = brush;
  }

  public void changeColor(int[] c) {
    this.paintColor = c;
  }

  public int[] getColor() {
    return this.paintColor;
  }
  
  public int getBrushType(){
    return this.brushType;
  }
  
  public void setBrushType(int bt){
    if(bt >= 0 && bt <= NUM_BRUSH_TYPES){
      this.brushType = bt;
    }
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

  public void larger(float amount) {
    scaleFactor += amount;
  }

  public void smaller(float amount) {
    scaleFactor -= amount;
    if (scaleFactor < 1f) {
      scaleFactor = 1f;
    }
  }

  public void paint(PGraphics layer, float x, float y) {

    switch(brushType) {
      case(1):
      paint_1(layer, x, y);
      break;
      case(2):
      paint_2(layer, x, y);
      break;
      case(3):
      paint_3(layer, x, y);
      break;
      case(4):
      paint_4(layer, x, y);
      break;
      case(5):
      paint_5(layer, x, y);
      break;
      case(6):
      paint_6(layer, x, y);
      break;
    default:
      layer.ellipse(x, y, scaleFactor, scaleFactor);
      break;
    }
  }

  //brush 1: pulsing ellipse
  private void paint_1(PGraphics layer, float x, float y) {
    if (true) {
      angle += 5;
      double val = Math.cos(Math.toRadians(angle)) * 12.0;
      for (int a = 0; a < 360; a += 75) {
        double xoff = Math.cos(Math.toRadians(a)) * val;
        double yoff = Math.sin(Math.toRadians(a)) * val;
        //layer.fill(0);
        layer.ellipse((float)(x + xoff), (float)(y + yoff), (float)(val), (float)(val));
      }
      layer.fill(175, 175, 255, 1);
      layer.ellipse(x, y, scaleFactor, scaleFactor);
    }
  }

  //brush 2: faster larger, slower small
  private void paint_2(PGraphics layer, float x, float y) {
    //TODO: might leak out of wall or give a padding experience
    float distX;
    float distY;
    float avgdist;
    distX = abs(x - prevX);
    distY = abs(y - prevY);
    avgdist = (distX+distY)/2; 
    if (avgdist > scaleFactor) {
      layer.ellipse(x, y, scaleFactor, scaleFactor);
    } else {
      layer.ellipse(x, y, avgdist*5, avgdist*5);
    }
    prevX = x;
    prevY = y;
  }

  //brush 3: different image brushes; we can give user an option to update their tooltip
  private void paint_3(PGraphics layer, float x, float y) {
    layer.pushMatrix();
    layer.translate(x-scaleFactor/2, y-scaleFactor/2);
    brush.resize((int)scaleFactor, (int)scaleFactor);
    layer.image(brush, 0, 0);
    layer.popMatrix();
  }

  //brush 4: modified image brushes; grass like effect
  private void paint_4(PGraphics layer, float x, float y) {
    float brushAngle = (float)atan2(x-prevX, y-prevY);
    layer.pushMatrix();
    layer.translate(x, y);
    layer.rotate((float)(brushAngle+((3*PI)/2)));
    brush.resize((int)scaleFactor, 1); //can play with the thikness, currently 1
    layer.image(brush, 0, 0);
    layer.popMatrix();
    prevX = x;
    prevY = y;
  }

  //brush 5: jiggle modified image brushes; feels like a soft carpet
  private void paint_5(PGraphics layer, float x, float y) {
    float brushAngle = (float)atan2(x-prevX, y-prevY);
    for (int i=0; i<5; i++) {
      layer.pushMatrix();
      int max = 20;
      int min = -20;

      float jiggleColor = (int)Math.floor(Math.random()*(255-0+1)+0);
      layer.tint(100+jiggleColor, 0, 170+jiggleColor, 200); //can change color of the image using this

      float jiggle =  (int)Math.floor(Math.random()*(max-min+1)+min);
      layer.translate(x+jiggle, y+jiggle);

      float jiggleAngle =  (int)Math.floor(Math.random()*(max-min+1)+min);
      layer.rotate((float)(brushAngle+(Math.toRadians(90+jiggleAngle))));
      brush.resize((int)scaleFactor, 5); //can play with the thickness  

      float jiggleScale =  (int)Math.floor(Math.random()*(0.03-0.03+1)+0.03);
      layer.scale((float)(0.8+jiggleScale));
      layer.image(brush, 0, 0);
      layer.popMatrix();
      prevX = x;
      prevY = y;
    }
  }

  //brush 6: jiggle modified image brushes; feels like air spray paint
  private void paint_6(PGraphics layer, float x, float y) {
    float brushAngle = (float)atan2(x-prevX, y-prevY);
    for (int i=0; i<5; i++) {
      layer.pushMatrix();
      int max = 10;
      int min = -10;

      float jiggleColor = (int)Math.floor(Math.random()*(255-0+1)+0);
      layer.tint(100+jiggleColor, 0, 170+jiggleColor, 10); //can change color of the image using this

      float jiggle =  (int)Math.floor(Math.random()*(max-min+1)+min);
      layer.translate(x+jiggle, y+jiggle);

      float jiggleAngle =  (int)Math.floor(Math.random()*(max-min+1)+min);
      layer.rotate((float)(brushAngle+(Math.toRadians(90+jiggleAngle))));

      brush.resize((int)scaleFactor, (int)scaleFactor); //can play with the thickness  

      float jiggleScale =  (int)Math.floor(Math.random()*(0.03-0.03+1)+0.03);
      layer.scale((float)(0.8+jiggleScale));
      layer.image(brush, 0, 0);
      layer.popMatrix();
      prevX = x;
      prevY = y;
    }
  }
}
