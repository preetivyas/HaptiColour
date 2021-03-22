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
/* end library imports *************************************************************************************************/



/* scheduler definition ************************************************************************************************/
private final ScheduledExecutorService scheduler      = Executors.newScheduledThreadPool(1);
/* end scheduler definition ********************************************************************************************/

/* DEFINE USER-SET PARAMETERS HERE! */
public final String FILENAME = "maze.txt";
public final boolean PRINTMAZE = true;

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
float xH = 0;
float yH = 0;


/* World boundaries in centimeters */
FWorld            world;
float             worldWidth                          = 30.0;  
float             worldHeight                         = 15.0; 

float             edgeTopLeftX                        = 0.0; 
float             edgeTopLeftY                        = 0.0; 
float             edgeBottomRightX                    = worldWidth; 
float             edgeBottomRightY                    = worldHeight;


/* Definition of wallList */
ArrayList<Wall> wallList;
//LK: hashmap is a workaround solution since I couldn't get fisica to import in the Wall.java file
HashMap<Wall, FBox> wallToWorldList;

/* Definition of maze end */
FCircle end;
FBox l1; 

/* Initialization of player token */
HVirtualCoupling  playerToken;

/* text font */
PFont font;

/* end elements definition *********************************************************************************************/

/*colouring specific variables*/
boolean           colour;
float             tooltipsize       =      1; //PV: set tooltip size (0.5 to 1 seems to work the best)
PImage            haplyAvatar, bi;
String            tooltip;

String[]          button_img        =      {"../img/brush1.png", "../img/brush2.png", "../img/brush3.png", 
  "../img/brush4.png", "../img/brush5.png", "../img/brush6.png", 
  "../img/brush7.png", "../img/brush8.png", "../img/brush9.png", 
  "../img/brush10.png"};
String[]          button_label      =      {"b1", "b2", "b3", "b4", "b5", "b6", "b7", "b8", "b9", "b10"};

/* setup section *******************************************************************************************************/
void setup() {
  /* put setup code here, run once: */
  background(255);
  cp5 = new ControlP5(this);

  tooltip = button_img[0];

  /* screen size definition */
  size(1200, 680);

  /* set font type and size */
  font = loadFont("ComicSansMS-72.vlw");
  textFont(font);

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
  haplyBoard = new Board(this, "COM3", 0);

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
  world               = new FWorld();

  /* create the maze!!! */
  try {
    createMaze(parseTextFile());
  }
  catch(incorrectMazeDimensionsException e) {
    System.out.println(e);
  }

  /* world conditions setup */
  world.setGravity((0.0), (1000.0)); //1000 cm/(s^2)
  world.setEdges((edgeTopLeftX), (edgeTopLeftY), (edgeBottomRightX), (edgeBottomRightY)); 
  world.setEdgesRestitution(.4);
  world.setEdgesFriction(0.5);


  //gui specific buttons



  for (int i = 0; i <button_img.length; i++) {
    bi = loadImage(button_img[i]);
    bi.resize(50, 50);
    cp5.addButton(button_label[i]).setImage(bi)
      .setPosition((50+100*i), 600)
      .setValue(0);
  }

  //cp5.addButton("resetHaply").setImage(bi)
  //  .setPosition((50+100*i), 600)
  //  .setValue(0);

  //cp5.addButton("move").setImage(bi)
  //  .setPosition((50+100*i), 600)
  //  .setValue(0);


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

void keyPressed(){
  if (key == ' '){ // pressing spacebar makes walls flexible
    setWallFlexibility(true, color(255, 0, 0));
  }
}

void keyReleased(){
  if (key == ' '){
    setWallFlexibility(false, color(0, 0, 0));
  }
}

public void b1(int theValue) {
  tooltip = button_img[0];
  haplyAvatar = loadImage(tooltip); 
  haplyAvatar.resize((int)(hAPI_Fisica.worldToScreen(tooltipsize)), (int)(hAPI_Fisica.worldToScreen(tooltipsize)));
  playerToken.h_avatar.attachImage(haplyAvatar);
}
public void b2(int theValue) {
  tooltip = button_img[1];
  haplyAvatar = loadImage(tooltip); 
  haplyAvatar.resize((int)(hAPI_Fisica.worldToScreen(tooltipsize)), (int)(hAPI_Fisica.worldToScreen(tooltipsize)));
  playerToken.h_avatar.attachImage(haplyAvatar);
}
public void b3(int theValue) {
  tooltip = button_img[2];
  haplyAvatar = loadImage(tooltip); 
  haplyAvatar.resize((int)(hAPI_Fisica.worldToScreen(tooltipsize)), (int)(hAPI_Fisica.worldToScreen(tooltipsize)));
  playerToken.h_avatar.attachImage(haplyAvatar);
}
public void b4(int theValue) {
  tooltip = button_img[3];
  haplyAvatar = loadImage(tooltip); 
  haplyAvatar.resize((int)(hAPI_Fisica.worldToScreen(tooltipsize)), (int)(hAPI_Fisica.worldToScreen(tooltipsize)));
  playerToken.h_avatar.attachImage(haplyAvatar);
}
public void b5(int theValue) {
  tooltip = button_img[4];
  haplyAvatar = loadImage(tooltip); 
  haplyAvatar.resize((int)(hAPI_Fisica.worldToScreen(tooltipsize)), (int)(hAPI_Fisica.worldToScreen(tooltipsize)));
  playerToken.h_avatar.attachImage(haplyAvatar);
}
public void b6(int theValue) {
  tooltip = button_img[5];
  haplyAvatar = loadImage(tooltip); 
  haplyAvatar.resize((int)(hAPI_Fisica.worldToScreen(tooltipsize)), (int)(hAPI_Fisica.worldToScreen(tooltipsize)));
  playerToken.h_avatar.attachImage(haplyAvatar);
}
public void b7(int theValue) {
  tooltip = button_img[6];
  haplyAvatar = loadImage(tooltip); 
  haplyAvatar.resize((int)(hAPI_Fisica.worldToScreen(tooltipsize)), (int)(hAPI_Fisica.worldToScreen(tooltipsize)));
  playerToken.h_avatar.attachImage(haplyAvatar);
}
public void b8(int theValue) {
  tooltip = button_img[7];
  haplyAvatar = loadImage(tooltip); 
  haplyAvatar.resize((int)(hAPI_Fisica.worldToScreen(tooltipsize)), (int)(hAPI_Fisica.worldToScreen(tooltipsize)));
  playerToken.h_avatar.attachImage(haplyAvatar);
}
public void b9(int theValue) {
  tooltip = button_img[8];
  haplyAvatar = loadImage(tooltip); 
  haplyAvatar.resize((int)(hAPI_Fisica.worldToScreen(tooltipsize)), (int)(hAPI_Fisica.worldToScreen(tooltipsize)));
  playerToken.h_avatar.attachImage(haplyAvatar);
}
public void b10(int theValue) {
  tooltip = button_img[9];
  haplyAvatar = loadImage(tooltip); 
  haplyAvatar.resize((int)(hAPI_Fisica.worldToScreen(tooltipsize)), (int)(hAPI_Fisica.worldToScreen(tooltipsize)));
  playerToken.h_avatar.attachImage(haplyAvatar);
}
/* end button action section ****************************************************************************************************/



/* draw section ********************************************************************************************************/
void draw() {
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
  if (renderingForce == false) {
    //background(255);
    world.draw();
  }
  
  
  
  ellipse(xH,yH,20,20);
  
  xH = lerp(xH, 40*(edgeTopLeftX+worldWidth/2-(posEE).x), 0.1);
  yH = lerp(yH, 40*(edgeTopLeftY+(posEE).y-7), 0.1)           ;
  float d = dist(xH, yH, 40*(edgeTopLeftX+worldWidth/2-(posEE).x), 40*(edgeTopLeftY+(posEE).y-7));
  println(d);
  
  if (d<10){
    noFill();
    stroke(255,0,0);
    ellipse(xH, yH, 30, 30);
    noFill();
    noStroke();
  }
  
  
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


    playerToken.updateCouplingForce();
    fEE.set(-playerToken.getVirtualCouplingForceX(), playerToken.getVirtualCouplingForceY());
    fEE.div(100000); //dynes to newtons

    torques.set(widgetOne.set_device_torques(fEE.array()));
    widgetOne.device_write_torques();

    if (playerToken.h_avatar.isTouchingBody(end)) {
      fill(random(255), random(255), random(255));
      text("!!!!!!!!!!", 
        edgeTopLeftX+worldWidth/2, edgeTopLeftY+worldHeight/2);
    }

    world.step(1.0f/1000.0f);

    renderingForce = false;
  }
}
/* end simulation section **********************************************************************************************/



/* helper functions section, place helper functions here ***************************************************************/

ArrayList<Wall> parseTextFile() throws incorrectMazeDimensionsException {
  wallList = new ArrayList<Wall>();
  wallToWorldList = new HashMap<Wall, FBox>();
  Wall w;

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
  end = new FCircle(1.0);
  end.setPosition(x, y);
  end.setFill(200, 0, 0);
  end.setStaticBody(true);
  end.setSensor(true);
  world.add(end);
}

void createMaze(ArrayList<Wall> wallList) throws incorrectMazeDimensionsException {

  //println(wallList);
  FBox wall;
  for (Wall item : wallList) {
    /* creation of wall */
    wall = new FBox(item.getW(), item.getH());
    wall.setPosition(item.getX(), item.getY());
    wall.setStatic(true);
    int c = item.getColor();
    wall.setFill(c);
    wallToWorldList.put(item, wall); //associate wallList item to FBox representation
    world.add(wall);
  }
}

void createPlayerToken(float x, float y) {
  /* Player circle */
  /* Setup the Virtual Coupling Contact Rendering Technique */
  playerToken = new HVirtualCoupling((tooltipsize)); 
  playerToken.h_avatar.setDensity(4); 
  haplyAvatar = loadImage(tooltip); 
  haplyAvatar.resize((int)(hAPI_Fisica.worldToScreen(tooltipsize)), (int)(hAPI_Fisica.worldToScreen(tooltipsize)));
  playerToken.h_avatar.attachImage(haplyAvatar); 
  //playerToken.h_avatar.setFill(random(255),random(255),random(255)); 
  //playerToken.h_avatar.setNoStroke();//PV: no stroke makes uniform color
  playerToken.init(world, x, y);
}

void setWallFlexibility(boolean flexibility, int wallColor) {
  FBox wallInWorld;
  for (Wall item : wallList){
    wallInWorld = wallToWorldList.get(item);
    wallInWorld.setSensor(flexibility);
    wallInWorld.setFillColor(wallColor);
    wallInWorld.setStrokeColor(wallColor);
  }
}

/* end helper functions section ****************************************************************************************/
