/**
 **********************************************************************************************************************
 * @file       lab2.pde
 * @author     Linnea Kirby, Preeti Vyas, Marco Moran
 * @date       01-March-2021
 * @brief      haptic maze loader based off of
 - "sketch_4_Wall_Physics.pde" by Steve Ding and Colin Gallacher
 - "sketch_6_Maze_Physics.pde" by Elie Hymowitz, Steve Ding, and Colin Gallacher
 **********************************************************************************************************************
 * @attention
 *
 *
 **********************************************************************************************************************
 */



/* library imports *****************************************************************************************************/
import processing.serial.*;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*;
import controlP5.*;
import java.util.ConcurrentModificationException;
/* end library imports *************************************************************************************************/



/* scheduler definition ************************************************************************************************/
private final ScheduledExecutorService scheduler      = Executors.newScheduledThreadPool(1);
/* end scheduler definition ********************************************************************************************/

/* DEFINE USER-SET PARAMETERS HERE! */
public final String WINDOWS = "COM4";
public final String MAC = "/dev/cu.usbmodem14201";
//public final String LINUX = "/dev/ttyUSB0";
public final String PORT = MAC; //<-- change the port name here!

public final String FILENAME = "maze.txt"; //<-- set the default lineart to color!
public final boolean PRINTMAZE = true; //<-- print the lineart in the System.out!
public final boolean DEBUG = false; //<-- print helpful print statements to System.out
public final int NUM_PALETTES = 2;
public final float PALETTE_SPACER = 1.25; //space between palette elements
public final float BUTTON_SPACER = 1.25*1.5; //space between GUI elements
public final float BRUSH_SIZE_JUMP = 2.0; //how much bigger/smaller to make the brush?
public final boolean BEGIN_IN_DRAWING_MODE = false;

ControlP5 cp5;

/* device block definitions ********************************************************************************************/
Board             haplyBoard;
Device            widgetOne;
Mechanisms        pantograph;

byte              widgetOneID                         = 5;
int               CW                                  = 0;
int               CCW                                 = 1;
boolean           renderingForce                      = false;
/* end device block definition *****************************************************************************************/



/* framerate definition ************************************************************************************************/
long              baseFrameRate                       = 150;
/* end framerate definition ********************************************************************************************/



/* elements definition *************************************************************************************************/

/* Screen and world setup parameters */
float             pixelsPerCentimeter                 = 40;

/* generic data for a 2DOF device */
/* joint space */
PVector           angles                              = new PVector(0, 0);
PVector           torques                             = new PVector(0, 0);

/* task space */
PVector           posEE                               = new PVector(0, 0);
PVector           fEE                                 = new PVector(0, 0);

/* outside circle parameters for Haply */
//float xH = 0;
//float yH = 0;


/* World boundaries in centimeters */
FWorld            world;
float             worldWidth                          = 30.0;
float             worldHeight                         = 15.0;

float             edgeTopLeftX                        = 0.0;
float             edgeTopLeftY                        = 0.0;
float             edgeBottomRightX                    = worldWidth;
float             edgeBottomRightY                    = worldHeight + 2;

PGraphics[] layers = new PGraphics[3];


/* Definition of wallList */
ArrayList<Wall> wallList;
//LK: hashmap is a workaround solution since I couldn't get fisica to import in the Wall.java file
HashMap<Wall, FBox> wallToWorldList;

/* Definition of maze end */
FCircle end;
FBox l1;

/* Translucent circle */
FCircle  C;

/* Initialization of player token */
HVirtualCoupling  playerToken;

/* text font */
PFont font;

/* end elements definition *********************************************************************************************/

/*colouring specific variables*/
boolean drawingModeEngaged;
int[] drawingColor = new int[3];
FBox[] colorSwatch = new FBox[8];
ArrayList<FBox> GUIButtons = new ArrayList<FBox>();
int shape; //what shape is the being drawn?
boolean           colour;
float             tooltipsize = 1; //PV: set tooltip size (0.5 to 1 seems to work the best)
PImage            haplyAvatar, bi;
String            tooltip;
Brush brush;
ArrayList<ColorPalette> palettes;
int paletteIndex;
int pageIndex = 0;

String[] button_img = {"../img/brush1.png", "../img/brush2.png", "../img/brush3.png", 
  "../img/brush4.png", "../img/brush5.png", "../img/brush6.png", 
  "../img/brush7.png", "../img/brush8.png", "../img/brush9.png", 
  "../img/brush10.png"};
String[] button_label = {"b1", "b2", "b3", "b4", "b5", "b6", "b7", "b8", "b9", "b10"};

/* texture variables**********************/
FBox[][] tgrid =  new FBox[100][200];
FBox[][] vgrid =  new FBox[100][200];
FBox[][] bgrid =  new FBox[100][200];

Slider damper;
int damp = 500;
float xdim = worldWidth;
float ydim = worldHeight;
float space = 1.5;
float wall_h = 2;
float wall_w = 0.1;
int iloop, jloop;
/*****************************************/

/* setup section *******************************************************************************************************/
void setup() {
  /* put setup code here, run once: */
  background(255);
  cp5 = new ControlP5(this);

  PFont p = createFont("Verdana", 17);
  ControlFont cfont = new ControlFont(p);

  // change the original colors
  cp5.setColorForeground(0xffaa0000);
  cp5.setFont(cfont);
  cp5.setColorActive(0xffff0000);

  //for testing only
  damper = cp5.addSlider("damp")
    .setPosition(100, 605)
    .setSize(200, 30)
    .setRange(100, 1000) // values can range from big to small as well
    .setValue(350)
    //.setFont(createFont("Verdana", 17))
    ;


  drawingModeEngaged = BEGIN_IN_DRAWING_MODE;
  shape = 0;

  createLayers();

  /* screen size definition */
  size(1200, 680);

  /* set font type and size */
  font = loadFont("SansSerif-28.vlw");
  textFont(font);

  /* set up the Haply */
  setUpDevice();
  createBrush();

  /* create the maze!!! */
  try {
    createMaze(parseTextFile());
  }
  catch(incorrectMazeDimensionsException e) {
    System.out.println(e);
  }

  /* world conditions setup */
  world.setGravity((0.0), (100.0)); //100 cm/(s^2)
  world.setEdges((edgeTopLeftX), (edgeTopLeftY), (edgeBottomRightX), (edgeBottomRightY));
  world.setEdgesRestitution(.4)   ;
  world.setEdgesFriction(0.5)     ;


  /*texture specific code*********************************************/
  space = 1.2;
  wall_h = 1.3;
  wall_w = 0.1;

  jloop = int(ydim/2);
  iloop = int(xdim/space);

  for (int j = 0; j<jloop; j++) {
    for (int i = 0; i<iloop; i++) {
      tgrid[j][i] = new FBox(wall_w, wall_h);
      tgrid[j][i].setPosition((i+1)*space, (j+0.8)*2);
      tgrid[j][i].setFill(40, 62, 102, 0);
      tgrid[j][i].setDensity(100);
      tgrid[j][i].setSensor(true);
      tgrid[j][i].setNoStroke()  ;
      tgrid[j][i].setStatic(true);
      world.add(tgrid[j][i]);
    }
  }

  /****************************************************************/

  //gui specific buttons


  //createBrushes();
  createGUI();

  world.draw();


  /* setup framerate speed */
  frameRate(baseFrameRate);


  /* setup simulation thread to run at 1kHz */
  SimulationThread st = new SimulationThread();
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);

  //PImage[] playImages = {loadImage("play.png"), loadImage("play.png"), loadImage("play.png")};
}
/* end setup section ***************************************************************************************************/

/* start button action section ****************************************************************************************************/
//PV: need to update this section; really bad (but working) code

void keyPressed() {
  if (key == ' ') { // pressing spacebar makes walls flexible
    if (isDrawingModeEngaged()) {
      disengageDrawingMode();
    } else if (checkDraw()) {
      if (!(isTouchingWall() instanceof FBox)) {
        engageDrawingMode();
      }
    }
  }
  if (key == 'c' || key == 'C') { // pressing c changes to the previous palette
    paletteIndex = (paletteIndex - 1 ) % (NUM_PALETTES);
    if (paletteIndex < 0) {
      paletteIndex = NUM_PALETTES - 1;
    }
    updateColorPicker(palettes.get(paletteIndex));
  }
  if (key == 'v' || key == 'V') { // pressing v changes to the next palette
    paletteIndex = (paletteIndex + 1) % (NUM_PALETTES);
    updateColorPicker(palettes.get(paletteIndex));
  }
}


/* end button action section ****************************************************************************************************/


/* draw section ********************************************************************************************************/
float x;
float y;
float pause = 0;
void draw() {
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */

  g.background(255);
  image(layers[1], 0, 0);
  g.fill(0);
  g.rect(0, height-2.5*pixelsPerCentimeter, width, 2.5*pixelsPerCentimeter);
  world.draw();

  if (isDrawingModeEngaged()) {
    layers[1].beginDraw();
    layers[1].noStroke();
    int[] c = getDrawingColor();
    layers[1].fill(color(c[0], c[1], c[2]));
    x = playerToken.getAvatarPositionX()*pixelsPerCentimeter;
    y = playerToken.getAvatarPositionY()*pixelsPerCentimeter;
    if (checkDraw()) {
      brush.paint(layers[1], x, y); //30
    }
    world.draw();
    layers[1].endDraw();
    image(layers[1], 0, 0);
  } //else if (millis() % 1000 > 500 && millis() % 1000 < 750 || millis() % 1000 < 250) {
  else if (pause % 5 == 0) {
    try {
      checkChangeColor();
    }
    catch(ConcurrentModificationException e) {
      //ignore these exceptions
    }
    if (pause % 6 == 0) {
      checkButtonActivation();
    }
  }
  pause += 1;
  layers[2].beginDraw();
  layers[2].clear();
  layers[2].background(0, 0);
  drawCursor(layers[2]);
  layers[2].endDraw();
  image(layers[2], 0, 0, width, height);
  world.draw();
}
/* end draw section ****************************************************************************************************/

/* simulation section **************************************************************************************************/
class SimulationThread implements Runnable {

  public void run() {
    /* put haptic simulation code here, runs repeatedly at 1kHz as defined in setup */

    renderingForce = true;

    if (haplyBoard.data_available()) {
      /* GET END-EFFECTOR STATE (TASK SPACE) */
      widgetOne.device_read_data();

      angles.set(widgetOne.get_device_angles());
      posEE.set(widgetOne.get_device_position(angles.array()));
      posEE.set(posEE.copy().mult(200));
    }

    playerToken.setToolPosition(edgeTopLeftX+worldWidth/2-(posEE).x, edgeTopLeftY+(posEE).y-7);
    C.setPosition(playerToken.h_avatar.getX(), playerToken.h_avatar.getY())                 ;
    //println(playerToken.h_avatar.getTouching())                                             ;


    playerToken.updateCouplingForce();
    fEE.set(-playerToken.getVirtualCouplingForceX(), playerToken.getVirtualCouplingForceY());
    fEE.div(100000); //dynes to newtons

    torques.set(widgetOne.set_device_torques(fEE.array()));
    widgetOne.device_write_torques();

    textureUpdate();

    playerToken.h_avatar.setDamping(damp);

    if (((playerToken.h_avatar.isTouchingBody(colorSwatch[0])) || (playerToken.h_avatar.isTouchingBody(colorSwatch[1])) || (playerToken.h_avatar.isTouchingBody(colorSwatch[2])) || (playerToken.h_avatar.isTouchingBody(colorSwatch[3])) || (playerToken.h_avatar.isTouchingBody(colorSwatch[4])) || (playerToken.h_avatar.isTouchingBody(colorSwatch[5])))) {
      playerToken.h_avatar.setDamping(850) ;
    }

    FBox touchWall ;
    for (Wall item : wallList) {
      touchWall = wallToWorldList.get(item);
      if (C.isTouchingBody(touchWall)) {
        playerToken.h_avatar.setDamping(900);
      }
    }


    world.step(1.0f/1000.0f);
    renderingForce = false  ;
  }
}
/* end simulation section **********************************************************************************************/



/* helper functions section, place helper functions here ***************************************************************/

private Boolean checkDraw() {
  if (playerToken.getAvatarPositionY()*pixelsPerCentimeter < height-2.5*pixelsPerCentimeter) {
    return true;
  }
  return false;
}

private FBox isTouchingWall() {
  FBox touchWall ;
  for (Wall item : wallList) {
    touchWall = wallToWorldList.get(item);
    if (playerToken.h_avatar.isTouchingBody(touchWall)) {
      return touchWall;
    }
  }
  return null;
}

ArrayList<Wall> parseTextFile() throws incorrectMazeDimensionsException {
  wallList = new ArrayList<Wall>()           ;
  wallToWorldList = new HashMap<Wall, FBox>();
  Wall w                                     ;

  String[] lines = loadStrings(FILENAME);

  if ( lines == null) {
    throw new NullPointerException("There is an error with your file!");
  }

  String line = lines[0]; // height and width of maze
  String[] mazeWH = line.split(" ");
  int mazeW = Integer.parseInt(mazeWH[0]);
  int mazeH = Integer.parseInt(mazeWH[1]);

  if (mazeW != worldWidth || mazeH != worldHeight) {
    throw new incorrectMazeDimensionsException(worldWidth, worldHeight, mazeW, mazeH);
  }

  Character c;

  for (int i = 1; i < mazeH+1; i++) { // walls of maze
    line = lines[i];
    for (int j = 0; j < mazeW-1; j++) {
      c = line.charAt(j);
      if (c == '-') {
        wallList.add(new Wall(2, 0.1, edgeTopLeftX+j+0.5, edgeTopLeftY+i-0.5, 0x000000));
      } else if (c == '|') {
        wallList.add(new Wall(0.1, 2, edgeTopLeftX+j+0.5, edgeTopLeftY+i-0.5, 0x000000));
      } else if (c == 'x') {
        createMazeEnd(edgeTopLeftX+j+0.5, edgeTopLeftY+i-0.5);
      } else if (c == '+') {
        createPlayerToken(edgeTopLeftX+j+0.5, edgeTopLeftY+i-0.5);
      }
    }
    if (PRINTMAZE) {
      System.out.println(line);
    }
  }

  return wallList;
}

void createMazeEnd(float x, float y) {
  /* Finish Button */
  end = new FCircle(1.0)  ;
  end.setPosition(x, y)   ;
  end.setFill(200, 0, 0)  ;
  end.setStaticBody(true) ;
  end.setSensor(true)     ;
  world.add(end)          ;
}

void createMaze(ArrayList<Wall> wallList) throws incorrectMazeDimensionsException {

  //println(wallList);
  FBox wall;
  for (Wall item : wallList) {
    /* creation of wall */
    wall = new FBox(item.getW(), item.getH()) ;
    wall.setPosition(item.getX(), item.getY());
    wall.setStatic(true);

    color c;
    if (BEGIN_IN_DRAWING_MODE) {
      c = color(0, 0, 0);
    } else {
      c = color(102, 205, 170);
      wall.setSensor(true);
    }
    wall.setFillColor(c);
    wall.setStrokeColor(c);

    //int c = item.getColor();
    //wall.setFill(255,0,0);

    wallToWorldList.put(item, wall); //associate wallList item to FBox representation
    world.add(wall);
  }

  //println(wallList);
}

void setWallFlexibility(boolean flexibility, int wallColor) {
  FBox wallInWorld;
  for (Wall item : wallList) {
    wallInWorld = wallToWorldList.get(item);
    wallInWorld.setSensor(flexibility);
    wallInWorld.setFillColor(wallColor);
    wallInWorld.setStrokeColor(wallColor);
  }
}

private void disengageDrawingMode() {
  setWallFlexibility(true, color(102, 205, 170));
  drawingModeEngaged = false ;
  world.remove(C)            ;
  //disable texture
  damp = 0;
}

private void engageDrawingMode() {
  setWallFlexibility(false, color(0, 0, 0));
  //setWallFlexibility(true, color(0, 0, 0)); // MARCO: If we uncomment this line and comment out the line above, the damping increase near the walls/borders is more useful
  drawingModeEngaged = true;
  world.add(C)             ;
  damp = 350               ;
}

public boolean isDrawingModeEngaged() {
  return drawingModeEngaged;
}

int[] getDrawingColor() {
  return drawingColor;
}

void setDrawingColor(int r, int g, int b) {
  drawingColor[0] = r;
  drawingColor[1] = g;
  drawingColor[2] = b;
  colorSwatch[7].setFillColor(color(r, g, b));
}

void setDrawingColor(int[] rgb) {
  setDrawingColor(rgb[0], rgb[1], rgb[2]);
}

void createPalettes() {
  palettes = new ArrayList<ColorPalette>();
  for (int i=0; i< NUM_PALETTES; i++) {
    palettes.add(createPalette(i)); //add all defined palettes
  }
}

ColorPalette createPalette(int index) {
  ColorSwatch[] palette = new ColorSwatch[6];
  switch(index) {
    case(0): //rainbow
    palette[5] = new ColorSwatch(255, 0, 0, 5); //red
    palette[4] = new ColorSwatch(255, 127, 0, 4); //orange
    palette[3] = new ColorSwatch(255, 255, 0, 3); //yellow
    palette[2] = new ColorSwatch(0, 255, 0, 2); //green
    palette[1] = new ColorSwatch(0, 0, 255, 1); //blue
    palette[0] = new ColorSwatch(127, 0, 255, 0); //purple
    break;
    case(1): //pastel rainbow
    palette[5] = new ColorSwatch(255, 175, 175, 5); //pink
    palette[4] = new ColorSwatch(255, 202, 175, 4); //sherbet
    palette[3] = new ColorSwatch(255, 255, 175, 3); //lemon
    palette[2] = new ColorSwatch(175, 255, 175, 2); //lime
    palette[1] = new ColorSwatch(175, 175, 255, 1); //periwinkle
    palette[0] = new ColorSwatch(202, 175, 255, 0); //lavender
    break;
  default: //rainbow
    palette[5] = new ColorSwatch(255, 0, 0, 5); //red
    palette[4] = new ColorSwatch(255, 127, 0, 4); //orange
    palette[3] = new ColorSwatch(255, 255, 0, 3); //yellow
    palette[2] = new ColorSwatch(0, 255, 0, 2); //green
    palette[1] = new ColorSwatch(0, 0, 255, 1); //blue
    palette[0] = new ColorSwatch(127, 0, 255, 0); //purple
    break;
  }

  return new ColorPalette(palette);
}

void createBrush() {
  brush = new Brush(drawingColor);
  int[] coords = {0, 0};
  Bristle b = new Bristle(1.0, brush, coords); //centered bristle
  brush.addBristle(b);
}

void drawBrush(PGraphics layer) {
  brush.paint(layer, playerToken.getAvatarPositionX()*40, playerToken.getAvatarPositionY()*40);
  world.draw();
}

void drawCursor(PGraphics layer) {
  float brushScale = brush.getScale();
  layer.fill(color(drawingColor[0], drawingColor[1], drawingColor[2]));
  layer.strokeWeight(1);  // Thicker
  layer.stroke(0, 0, 0);
  float x = playerToken.getAvatarPositionX()*pixelsPerCentimeter;
  float y = playerToken.getAvatarPositionY()*pixelsPerCentimeter;
  layer.ellipse(x, y, brushScale*28/30, brushScale*28/30);
  if (brushScale > 10) {
    layer.ellipse(x, y, brushScale*2/30, brushScale*2/30);
  }
  layer.noFill();
  layer.strokeWeight(1);  // Thicker
  layer.stroke(255, 255, 255);
  layer.ellipse(x, y, brushScale*30/30, brushScale*30/30);
  if (brushScale > 10) {
    layer.ellipse(x, y, brushScale*4/30, brushScale*4/30);
  }
  if (DEBUG) {
    System.out.println("Brush scale: "+brushScale);
  }
  world.draw();
}

void updateColorPicker(ColorPalette palette) {
  ColorSwatch swatch;
  for (int i=0; i<palette.getLength(); i++) {
    swatch = palette.getSwatch(i);
    colorSwatch[i].setFillColor(color(swatch.getRed(), swatch.getGreen(), swatch.getBlue()));
    world.draw();
  }
}

float createColorPicker(ColorPalette palette) {
  float x = edgeBottomRightX;
  float y = edgeBottomRightY - 1.8;
  ColorSwatch swatch;
  for (Integer i=0; i< 6; i++) {
    x = x - PALETTE_SPACER;
    colorSwatch[i] = new FBox(1, 1);
    colorSwatch[i].setPosition(x, y);
    colorSwatch[i].setStatic(true);
    colorSwatch[i].setSensor(true);
    colorSwatch[i].setName(i.toString());

    swatch = palette.getSwatch(i);
    colorSwatch[i].setFillColor(color(swatch.getRed(), swatch.getGreen(), swatch.getBlue()));
    world.add(colorSwatch[i]);

    world.draw();
  }

  //create "eraser" (white swatch)
  x = x - PALETTE_SPACER - .25;
  colorSwatch[6] = new FBox(1, 1);
  colorSwatch[6].setPosition(x, edgeBottomRightY - 1.5);
  colorSwatch[6].setStatic(true);
  colorSwatch[6].setSensor(true);
  colorSwatch[6].setName("6");
  colorSwatch[6].setFillColor(color(255, 255, 255));
  addLabel(colorSwatch[6], "./img/erase.png");
  world.add(colorSwatch[6]);

  //create color mixer swatch
  colorSwatch[7] = new FBox(7.25, .5);
  colorSwatch[7].setPosition(edgeBottomRightX - PALETTE_SPACER * 3.5, edgeBottomRightY - 1);
  colorSwatch[7].setStatic(true);
  swatch = palette.getSwatch(0);
  setDrawingColor(swatch.getRed(), swatch.getGreen(), swatch.getBlue());
  world.add(colorSwatch[7]);

  return x;
}

void createGUI() {
  createPalettes();
  paletteIndex = 0;
  float x = createColorPicker(palettes.get(paletteIndex)) - BUTTON_SPACER;
  float y = edgeBottomRightY - 1.5;

  //prev + next color palette
  GUIButtons.add(addButton("next", "./img/nextPalette.png", x, y));
  x = x - BUTTON_SPACER;
  GUIButtons.add(addButton("prev", "./img/prevPalette.png", x, y));
  x = x - BUTTON_SPACER;
  //larger + smaller brush
  GUIButtons.add(addButton("larger", "./img/largerBrush.png", x, y));
  x = x - BUTTON_SPACER;
  GUIButtons.add(addButton("smaller", "./img/smallerBrush.png", x, y));
  x = x - BUTTON_SPACER;
  //save + clear canvas
  GUIButtons.add(addButton("save", "./img/save.png", x, y));
  x = x - BUTTON_SPACER;
  GUIButtons.add(addButton("clear", "./img/clear.png", x, y));

  for (FBox item : GUIButtons) {
    world.add(item);
    world.draw();
  }
}

FBox addButton(String name, String path, float x, float y) {
  FBox button = new FBox(1.5, 1.5);
  button.setPosition(x, y);
  button.setStatic(true);
  button.setSensor(true);
  button.setName(name);
  button.setNoFill();
  addLabel(button, path);
  return button;
}

void addLabel(FBox button, String path) {
  /* If you are developing on a Mac users must update the path below
   * from "../img/Haply_avatar.png" to "./img/Haply_avatar.png"
   */
  PImage buttonImage = loadImage(path);
  buttonImage.resize((int)(hAPI_Fisica.worldToScreen(1.5)), (int)(hAPI_Fisica.worldToScreen(1.5)));
  button.attachImage(buttonImage);
}

void drawLabels() {
  g.fill(color(0, 0, 0));
  for (FBox item : GUIButtons) {
    g.text(item.getName(), item.getX(), item.getY());
    System.out.println(item.getName());
  }
}

void checkChangeColor() {
  ColorPalette palette = palettes.get(paletteIndex);
  for (int i=0; i<palette.getLength()+1; i++) {
    if (colorSwatch[i].isTouchingBody(playerToken.h_avatar)) {
      if (i == palette.getLength()) { //if "eraser" swatch
        setDrawingColor(255, 255, 255);
      } else {
        setDrawingColor(palette.getSwatch(i).getColor());
      }
    }
  }
}

void checkButtonActivation() {
  for (FBox item : GUIButtons) {
    if (playerToken.h_avatar.isTouchingBody(item)) {
      switch(item.getName()) {
      case("next"):
        paletteIndex = (paletteIndex + 1 ) % (NUM_PALETTES);
        updateColorPicker(palettes.get(paletteIndex));
        break;
      case("prev"):
        paletteIndex = (paletteIndex - 1 ) % (NUM_PALETTES);
        if (paletteIndex < 0) {
          paletteIndex = NUM_PALETTES - 1;
        }
        updateColorPicker(palettes.get(paletteIndex));
        break;
      case("larger"):
        brush.larger(BRUSH_SIZE_JUMP);
        tooltipsize += BRUSH_SIZE_JUMP/pixelsPerCentimeter;
        playerToken.h_avatar.setSize(brush.getScale()/pixelsPerCentimeter);
        C.setSize(brush.getScale()*1.5/30);
        break;
      case("smaller"):
        brush.smaller(BRUSH_SIZE_JUMP);
        tooltipsize -= BRUSH_SIZE_JUMP/pixelsPerCentimeter;
        playerToken.h_avatar.setSize(brush.getScale()/pixelsPerCentimeter);
        C.setSize(brush.getScale()*1.5/30);
        break;
      case("save"):
        layers[0].save("./saved/screen"+pageIndex+".png");
        layers[1].save("./saved/colors"+pageIndex+".png");
        pageIndex += 1;
        g.textAlign(CENTER, CENTER);
        g.textSize(150);
        g.fill(255);
        g.text("saved!", width/2, height/2);
        g.textSize(125);
        g.fill(0);
        g.text("saved!", width/2, height/2);
        break;
      case("clear"):
        g.background(255);
        createLayers();
        break;
      default:
        break;
      }
    }
  }
}

void createPlayerToken(float x, float y) {
  /* Player circle */
  /* Setup the Virtual Coupling Contact Rendering Technique */
  playerToken = new HVirtualCoupling(tooltipsize);
  playerToken.h_avatar.setDensity(4);

  playerToken.h_avatar.setNoFill();
  //playerToken.h_avatar.setFill(0);
  playerToken.h_avatar.setSize(brush.getScale()/pixelsPerCentimeter);
  playerToken.h_avatar.setNoStroke();//PV: no stroke makes uniform color

  playerToken.init(world, x, y);
  setUpPlayerTokenSensor(x, y);
}

void setUpPlayerTokenSensor(float x, float y) {
  /* Translucent circle */
  C = new FCircle(1.50) ;
  C.setDensity(1)       ;
  C.setSensor(true)     ;
  C.setNoFill()         ;
  C.setStroke(255, 0, 0, 5);
  C.setPosition(x, y)   ;
}

void setUpDevice() {
  /* device setup */

  /**
   * The board declaration needs to be changed depending on which USB serial port the Haply board is connected.
   * In the base example, a connection is setup to the first detected serial device, this parameter can be changed
   * to explicitly state the serial port will look like the following for different OS:
   *
   *      windows:      haplyBoard = new Board(this, "COM10", 0);
   *      linux:        haplyBoard = new Board(this, "/dev/ttyUSB0", 0);
   *      mac:          haplyBoard = new Board(this, "/dev/cu.usbmodem14201", 0);
   */

  //haplyBoard = new Board(this, "COM3", 0);
  haplyBoard = new Board(this, PORT, 0);

  widgetOne           = new Device(widgetOneID, haplyBoard);
  pantograph          = new Pantograph();

  widgetOne.set_mechanism(pantograph);

  widgetOne.add_actuator(1, CCW, 2);
  widgetOne.add_actuator(2, CW, 1);

  widgetOne.add_encoder(1, CCW, 241, 10752, 2);
  widgetOne.add_encoder(2, CW, -61, 10752, 1);


  widgetOne.device_set_parameters();


  /* 2D physics scaling and world creation */
  hAPI_Fisica.init(this);
  hAPI_Fisica.setScale(pixelsPerCentimeter);
  world = new FWorld();
}

void createBrushes() {
  for (int i = 0; i <button_img.length; i++) {
    bi = loadImage(button_img[i]);
    bi.resize(50, 50);
    cp5.addButton(button_label[i]).setImage(bi)
      .setPosition((50+80*i), 590)
      .setValue(0);
  }
}

void createLayers() {
  //for(int i = 0; i < layers.length; i++){
  //  layers[i] = createGraphics((int)worldWidth, (int)worldHeight + 2);
  //}
  layers[0] = g;
  layers[1] = createGraphics(1200, 680);
  layers[2] = createGraphics(1200, 680);
}

void textureUpdate() {

  if (drawingModeEngaged == true) {
    //tgrid damp 356
    for (int j=0; j<jloop; j++) {
      for (int i=0; i<iloop; i++) {
        if (playerToken.h_avatar.isTouchingBody(tgrid[i][j])) {
          playerToken.h_avatar.setDamping(damp);
        }
      }//println(s);
    }
  }
}
/* end helper functions section ****************************************************************************************/
