/**
 **********************************************************************************************************************
 * @file       sketch_4_Wall_Physics.pde
 * @author     Steve Ding, Colin Gallacher
 * @version    V4.1.0
 * @date       08-January-2021
 * @brief      wall haptic example using 2D physics engine 
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
/* end library imports *************************************************************************************************/



/* scheduler definition ************************************************************************************************/
private final ScheduledExecutorService scheduler      = Executors.newScheduledThreadPool(1);
/* end scheduler definition ********************************************************************************************/



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
long              baseFrameRate                       = 120; //PV 120 fps
/* end framerate definition ********************************************************************************************/



/* elements definition *************************************************************************************************/

/* Screen and world setup parameters */
float             pixelsPerCentimeter                 = 40.0;

/* generic data for a 2DOF device */
/* joint space */
PVector           angles                              = new PVector(0, 0);
PVector           torques                             = new PVector(0, 0);

/* task space */
PVector           posEE                               = new PVector(0, 0);
PVector           fEE                                 = new PVector(0, 0);

PVector           corr_posEE                          = new PVector(0, 0);
PVector           pre_posEE                          = new PVector(0, 0);

/* World boundaries in centimeters */
FWorld            world;
float             worldWidth                          = 30.0;  
float             worldHeight                         = 15.0; 

float             edgeTopLeftX                        = 0.0; 
float             edgeTopLeftY                        = 0.0; 
float             edgeBottomRightX                    = worldWidth; 
float             edgeBottomRightY                    = worldHeight;

float             gravityAcceleration                 = 980; //cm/s2



/* Initialization of wall */
FBox              wall, l1;


/* Initialization of virtual tool */
HVirtualCoupling  s;
 
PImage            haplyAvatar;

/* end elements definition *********************************************************************************************/


/*colouring specific variables*/
boolean colour;
PShape rectangle;
int angle = 0;
float tooltipsize = 0.5;


/* setup section *******************************************************************************************************/
void setup() {
  /* put setup code here, run once: */

  /* screen size definition */
  size(1200, 600, P2D);
  background(102);
  noStroke();
  fill(0, 102);
  
  
  /* device setup */

  /**  
   * The board declaration needs to be changed depending on which USB serial port the Haply board is connected.
   * In the base example, a connection is setup to the first detected serial device, this parameter can be changed
   * to explicitly state the serial port will look like the following for different OS:
   *
   *      windows:      haplyBoard = new Board(this, "COM10", 0);
   *      linux:        haplyBoard = new Board(this, "/dev/ttyUSB0", 0);
   *      mac:          haplyBoard = new Board(this, "/dev/cu.usbmodem1411", 0);
   */
  haplyBoard          = new Board(this, "COM4", 0);
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
    
  /* Haptic Tool Initialization */
  s                   = new HVirtualCoupling((tooltipsize)); 
  s.h_avatar.setDensity(4);  
  s.init(world, edgeTopLeftX+worldWidth/2, edgeTopLeftY+2); 

  pushMatrix();
  /* Set viscous layer */
  l1                  = new FBox(10, 1);
  l1.setPosition(edgeTopLeftX+worldWidth/2, edgeTopLeftY+worldHeight/2);
  //l1.setFill(150,150,255,80);
  l1.setNoStroke();
  l1.setDensity(100);
  l1.setSensor(true);
  l1.setStatic(true);
  l1.setFill(160,160,160);
  l1.setName("Water");
  world.add(l1);
  
  /* creation of wall */
  wall                   = new FBox(10.0, 0.2);
  wall.setPosition(edgeTopLeftX+worldWidth/2.0, edgeTopLeftY+2*worldHeight/3.0+1);
  wall.setStatic(true);
  wall.setFill(0, 0, 0);
  world.add(wall);

  wall                   = new FBox(10.0, 0.2);
  wall.setPosition(edgeTopLeftX+worldWidth/2.0, edgeTopLeftY+2*worldHeight/3.0-5);
  wall.setStatic(true);
  wall.setFill(0, 0, 0);
  world.add(wall);

  /* creation of wall */
  wall                   = new FBox(0.2, 6);
  wall.setPosition(edgeTopLeftX+worldWidth/2.0+5, edgeTopLeftY+1*worldHeight/3.0+3);
  wall.setStatic(true);
  wall.setFill(0, 0, 0);
  world.add(wall);

  /* creation of wall */
  wall                   = new FBox(0.2, 4.5);
  wall.setPosition(edgeTopLeftX+worldWidth/2.0-5, edgeTopLeftY+1*worldHeight/3.0+2.25);
  wall.setStatic(true);
  wall.setFill(0, 0, 0);
  world.add(wall);
  popMatrix();



  /* If you are developing on a Mac users must update the path below 
   * from "../img/Haply_avatar.png" to "./img/Haply_avatar.png" 
   */
  haplyAvatar = loadImage("../img/Haply_avatar.png"); 
  //haplyAvatar.resize((int)(hAPI_Fisica.worldToScreen(1)), (int)(hAPI_Fisica.worldToScreen(1)));
  //s.h_avatar.attachImage(haplyAvatar); 
  //s.setSize(0.1);
  
  println(s.getSize()); 

  pre_posEE.x = edgeTopLeftX+worldWidth/2;
  pre_posEE.y = edgeTopLeftY+2;


  /* world conditions setup */
  world.setGravity((0.0), (1000.0)); //1000 cm/(s^2)
  world.setEdges((edgeTopLeftX), (edgeTopLeftY), (edgeBottomRightX), (edgeBottomRightY)); 
  world.setEdgesRestitution(.4); //pv what does this do?
  world.setEdgesFriction(0.5); //pv what does this do?


  world.draw();


  /* setup framerate speed */
  frameRate(baseFrameRate);


  /* setup simulation thread to run at 1kHz */
  SimulationThread st = new SimulationThread();
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);

  rectangle = createShape(RECT, (corr_posEE.x)*40, (corr_posEE.y)*40, 100, 50);
  background(255);
 
}
/* end setup section ***************************************************************************************************/



/* draw section ********************************************************************************************************/
void draw() {
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
  if (renderingForce == false) {
    background(255);
    world.draw();
  }

  //background(51);
  //translate((corr_posEE.x)*40, (corr_posEE.y)*40);
  //shape(rectangle);

  if (true) {
    angle += 5;
    float val = cos(radians(angle)) * 12.0;
    for (int a = 0; a < 360; a += 75) {
      float xoff = cos(radians(a)) * val;
      float yoff = sin(radians(a)) * val;
      fill(0);
      ellipse((corr_posEE.x)*40 + xoff, (corr_posEE.y)*40 + yoff, val, val);
    }
    fill(255);
    ellipse((corr_posEE.x)*40, (corr_posEE.y)*40, 2, 2);
  }

  //println (posEE);
  //println (pantograph.get_coordinate()); //PV: to get pantograph coordinates
  //println (posEE.x, posEE.y); 

  //text on screen
  //textAlign(CENTER);
  //text("Solve the maze while avoiding all the red blocks!!!", width/2, 60);

  //colour = true;

  //stroke(0); //basic 
  //line((corr_posEE.x)*40, (corr_posEE.y)*40, (pre_posEE.x)*40, (pre_posEE.y)*40); //store position value, record previous position
  //println ("pre_poss"+pre_posEE);
  //pre_posEE = corr_posEE;
  //println ("corr_poss"+corr_posEE);
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
      //println (posEE.x, posEE.y); 
      posEE.set(posEE.copy().mult(200)); 
      //println (posEE.x, posEE.y);
    }

    corr_posEE.x = edgeTopLeftX+worldWidth/2-(posEE).x;
    corr_posEE.y = edgeTopLeftY+(posEE).y-7;

    //s.setToolPosition(edgeTopLeftX+worldWidth/2-(posEE).x, edgeTopLeftY+(posEE).y-7); 
    s.setToolPosition(corr_posEE.x, corr_posEE.y); 
    s.updateCouplingForce();

    fEE.set(-s.getVirtualCouplingForceX(), s.getVirtualCouplingForceY());
    fEE.div(100000); //dynes to newtons

    torques.set(widgetOne.set_device_torques(fEE.array()));
    widgetOne.device_write_torques();

    /* Viscous layer codes */
    if (s.h_avatar.isTouchingBody(l1)) {
      s.h_avatar.setDamping(700);
    } else {
      s.h_avatar.setDamping(10);
    }

    world.step(1.0f/1000.0f);

    renderingForce = false;
  }
}
/* end simulation section **********************************************************************************************/



/* helper functions section, place helper functions here ***************************************************************/

/* end helper functions section ****************************************************************************************/
