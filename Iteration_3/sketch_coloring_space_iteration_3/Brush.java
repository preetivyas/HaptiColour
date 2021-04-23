import java.util.ArrayList;
import processing.core.PGraphics;
import processing.core.PImage;
import processing.core.PApplet;
import static java.lang.Math.*;

public class Brush extends PApplet{
  public final int NUM_BRUSH_TYPES = 12;
  private float paintAmount;
  private int[] paintColor = new int[3];
  private ArrayList<Bristle> bristles = new ArrayList<Bristle>();
  private float maxSize;
  private int brushType;
  private float minSize;

  //PV added these variables
  private float angle;
  private float prevX = 0;
  private float prevY = 0;
  String[] button_img = {"../img/brush1.png", "../img/brush2.png", "../img/brush3.png", 
  "../img/brush4.png", "../img/brush5.png", "../img/brush6.png", 
  "../img/brush7.png", "../img/brush8.png", "../img/brush9.png", 
  "../img/brush10.png"};
  PImage[] brushImages = new PImage[4];


  public Brush(PImage[] bi) {
    this(new int[] {0, 0, 0}, bi);
  }

  public Brush(int[] c, PImage[] bi) {
    this.paintColor = c;
    this.paintAmount = 0.0f;
    this.maxSize = 30f;
    this.brushType = 0;
    this.brushImages = bi;
    this.minSize = maxSize;
  }

  public void changeColor(int[] c) {
    if (this.brushType < 7){
    this.paintColor = c;
    }
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
    this.maxSize = s;
  }

  public float getScale() {
    return this.maxSize;
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
    maxSize += amount;
  }

  public void smaller(float amount) {
    maxSize -= amount;
    if (maxSize < 1f) {
      maxSize = 1f;
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
      case(7):
      paint_7(layer, x, y);
      break;
      case(8):
      paint_8(layer, x, y);
      break;
      case(9):
      paint_9(layer, x, y);
      break;
      case(10):
      paint_10(layer, x, y);
      break;
      case(11):
      paint_11(layer, x, y);
      break;
      case(12):
      paint_12(layer, x, y);
      break;
    default:
      layer.ellipse(x, y, maxSize, maxSize);
      break;
    }
  }

  ////brush 1: pulsing ellipse
  //private void paint_1(PGraphics layer, float x, float y) {
  //  layer.fill(color(paintColor[0], paintColor[1], paintColor[2]));
  //  if (true) {
  //    angle += 5;
  //    double val = Math.cos(Math.toRadians(angle)) * 12.0;
  //    for (int a = 0; a < 360; a += 75) {
  //      double xoff = Math.cos(Math.toRadians(a)) * val;
  //      double yoff = Math.sin(Math.toRadians(a)) * val;
  //      //layer.fill(0);
  //      layer.ellipse((float)(x + xoff), (float)(y + yoff), (float)(val), (float)(val));
  //    }
  //    layer.fill(175, 175, 255, 1);
  //    layer.ellipse(x, y, maxSize, maxSize);
  //  }
  //}
  
  //brush 1: soft round brush
  private void paint_1(PGraphics layer, float x, float y){
    layer.tint(paintColor[0], paintColor[1], paintColor[2], 200);
    layer.pushMatrix();
    layer.translate(x-maxSize/2, y-maxSize/2);
    this.brushImages[0].resize((int)maxSize, (int)maxSize);
    layer.image(this.brushImages[0], 0, 0);
    layer.popMatrix();
  }

  //brush 2: faster larger, slower small
  //private void paint_2(PGraphics layer, float x, float y) {
  //  //TODO: might leak out of wall or give a padding experience
  //  layer.fill(color(paintColor[0], paintColor[1], paintColor[2]));
  //  float distX;
  //  float distY;
  //  float avgdist;
  //  distX = abs(x - prevX);
  //  distY = abs(y - prevY);
  //  avgdist = (distX+distY)/2; 
  //  if (avgdist*5 > maxSize) {
  //    layer.ellipse(x, y, maxSize*30/30, maxSize*30/30);
  //  } else {
  //    layer.ellipse(x, y, avgdist*5, avgdist*5);
  //  }
  //  prevX = x;
  //  prevY = y;
  //}
  
  //dual tip
  private void paint_2(PGraphics layer, float x, float y){
    layer.tint(paintColor[0], paintColor[1], paintColor[2], 200);
    layer.pushMatrix();
    layer.translate(x-maxSize/2, y-maxSize/2);
    this.brushImages[3].resize((int)maxSize, (int)maxSize);
    layer.image(this.brushImages[3], 0, 0);
    layer.popMatrix();
  }

  //brush 3: different image brushes; we can give user an option to update their tooltip
  private void paint_3(PGraphics layer, float x, float y) {
    layer.tint(paintColor[0], paintColor[1], paintColor[2], 200);
    layer.pushMatrix();
    layer.translate(x-maxSize/2, y-maxSize/2);
    this.brushImages[2].resize((int)maxSize, (int)maxSize);
    layer.image(this.brushImages[2], 0, 0);
    layer.popMatrix();
  }

  //brush 4: modified image brushes; grass like effect
  private void paint_4(PGraphics layer, float x, float y) {
    layer.tint(paintColor[0], paintColor[1], paintColor[2], 200);
    float brushAngle = (float)atan2(x-prevX, y-prevY);
    layer.pushMatrix();
    layer.translate(x, y);
    layer.rotate((float)(brushAngle+((3*PI)/2)));
    this.brushImages[1].resize((int)maxSize, 5); //can play with the thikness, currently 1
    layer.image(this.brushImages[1], 0, 0);
    layer.popMatrix();
    prevX = x;
    prevY = y;
  }

  //brush 5: jiggle modified image brushes; feels like a soft carpet
  private void paint_5(PGraphics layer, float x, float y) {
    layer.tint(paintColor[0], paintColor[1], paintColor[2], 200);
    float brushAngle = (float)atan2(x-prevX, y-prevY);
    for (int i=0; i<5; i++) {
      layer.pushMatrix();
      int max = 20;
      int min = -20;

      float jiggleColor = (int)Math.floor(Math.random()*(255-0+1)+0);
      layer.tint(paintColor[0]+jiggleColor, paintColor[1], paintColor[2]+jiggleColor, 200); //can change color of the image using this

      float jiggle =  (int)Math.floor(Math.random()*(max-min+1)+min);
      layer.translate(x+jiggle, y+jiggle);

      float jiggleAngle =  (int)Math.floor(Math.random()*(max-min+1)+min);
      layer.rotate((float)(brushAngle+(Math.toRadians(90+jiggleAngle))));
      this.brushImages[1].resize((int)maxSize, 5); //can play with the thickness  

      float jiggleScale =  (int)Math.floor(Math.random()*(0.03-0.03+1)+0.03);
      layer.scale((float)(0.8+jiggleScale));
      layer.image(this.brushImages[1], 0, 0);
      layer.popMatrix();
      prevX = x;
      prevY = y;
    }
  }

  //brush 6: jiggle modified image brushes; feels like air spray paint
  private void paint_6(PGraphics layer, float x, float y) {
    layer.tint(paintColor[0], paintColor[1], paintColor[2], 200);
    float brushAngle = (float)atan2(x-prevX, y-prevY);
    for (int i=0; i<5; i++) {
      layer.pushMatrix();
      int max = 10;
      int min = -10;

      float jiggleColor = (int)Math.floor(Math.random()*(255-0+1)+0);
      layer.tint(paintColor[0]+jiggleColor, paintColor[1], paintColor[2]+jiggleColor, 10); //can change color of the image using this

      float jiggle =  (int)Math.floor(Math.random()*(max-min+1)+min);
      layer.translate(x+jiggle, y+jiggle);

      float jiggleAngle =  (int)Math.floor(Math.random()*(max-min+1)+min);
      layer.rotate((float)(brushAngle+(Math.toRadians(90+jiggleAngle))));

      this.brushImages[1].resize((int)maxSize, (int)maxSize); //can play with the thickness  

      float jiggleScale =  (int)Math.floor(Math.random()*(0.03-0.03+1)+0.03);
      layer.scale((float)(0.8+jiggleScale));
      layer.image(this.brushImages[1], 0, 0);
      layer.popMatrix();
      prevX = x;
      prevY = y;
    }
  }
  
  private void paint_7(PGraphics layer, float x, float y){//star
    layer.tint(255);
    layer.pushMatrix();
      int max = 0;
      int min = -40;
    //layer.translate(x-maxSize/2, y-maxSize/2);
    float jiggle =  (int)Math.floor(Math.random()*(max-min+1)+min);
    layer.translate(x+jiggle, y+jiggle);
    this.brushImages[4].resize((int)maxSize, (int)maxSize);
    layer.image(this.brushImages[4], 0, 0);
    layer.popMatrix();
  }
  
  private void paint_8(PGraphics layer, float x, float y){ //rainbow
    layer.tint(255);
    layer.pushMatrix();
     int max = 0;
      int min = -40;
    //layer.translate(x-maxSize/2, y-maxSize/2);
    float jiggle =  (int)Math.floor(Math.random()*(max-min+1)+min);
    layer.translate(x+jiggle, y+jiggle);
    this.brushImages[5].resize((int)maxSize, (int)maxSize);
    layer.image(this.brushImages[5], 0, 0);
    layer.popMatrix();
  }
  
  private void paint_9(PGraphics layer, float x, float y){ //umbrella   
    layer.tint(255);
    layer.pushMatrix();
     int max = 0;
      int min = -40;
    //layer.translate(x-maxSize/2, y-maxSize/2);
    float jiggle =  (int)Math.floor(Math.random()*(max-min+1)+min);
    layer.translate(x+jiggle, y+jiggle);
    this.brushImages[6].resize((int)maxSize, (int)maxSize);
    layer.image(this.brushImages[6], 0, 0);
    layer.popMatrix();
  }
  
   private void paint_10(PGraphics layer, float x, float y){ //flowers
    layer.tint(255);
    layer.pushMatrix();
     int max = 0;
      int min = -40;
    //layer.translate(x-maxSize/2, y-maxSize/2);
    float jiggle =  (int)Math.floor(Math.random()*(max-min+1)+min);
    layer.translate(x+jiggle, y+jiggle);
    this.brushImages[7].resize((int)maxSize*2, (int)maxSize*2);
    layer.image(this.brushImages[7], 0, 0);
    layer.popMatrix();
  }
  
   private void paint_11(PGraphics layer, float x, float y){//sunflower
    layer.tint(255);
    layer.pushMatrix();
     int max = 0;
      int min = -40;
    //layer.translate(x-maxSize/2, y-maxSize/2);
    float jiggle =  (int)Math.floor(Math.random()*(max-min+1)+min);
    layer.translate(x+jiggle, y+jiggle);
    this.brushImages[8].resize((int)maxSize*2, (int)maxSize*2);
    layer.image(this.brushImages[8], 0, 0);
    layer.popMatrix();
  }
  
   private void paint_12(PGraphics layer, float x, float y){ //pizza
    layer.tint(255);
    layer.pushMatrix();
     int max = 0;
      int min = -40;
    //layer.translate(x-maxSize/2, y-maxSize/2);
    float jiggle =  (int)Math.floor(Math.random()*(max-min+1)+min);
    layer.translate(x+jiggle, y+jiggle);
    this.brushImages[9].resize((int)maxSize*2, (int)maxSize*2);
    layer.image(this.brushImages[9], 0, 0);
    layer.popMatrix();
  }
  
}
