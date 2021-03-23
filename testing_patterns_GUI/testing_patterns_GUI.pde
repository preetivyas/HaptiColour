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
import controlP5.*;

/* end library imports *************************************************************************************************/



/* scheduler definition ************************************************************************************************/
private final ScheduledExecutorService scheduler      = Executors.newScheduledThreadPool(1);
/* end scheduler definition ********************************************************************************************/

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
long              baseFrameRate                       = 120;
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
PVector           fEE                                = new PVector(0, 0); 

/* World boundaries in centimeters */
FWorld            world;
float             worldWidth                          = 30.0;  
float             worldHeight                         = 15.0; 

float             edgeTopLeftX                        = 0.0; 
float             edgeTopLeftY                        = 0.0; 
float             edgeBottomRightX                    = worldWidth; 
float             edgeBottomRightY                    = worldHeight;

int damp = 500;
float spacing = 2;
float wallwidth = 0.25;

ArrayList<Wall> t_wallList;

/* Initialization of wall */
FBox              a1, a2, v1;
FBox            l;
//FCircle           c1; 

//working on making this more efficient
FBox   b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16, b17, b18, b19, b20; 
Slider damper, spacing_s, wallwidth_s;


/* Initialization of virtual tool */
HVirtualCoupling  s;
PImage            haplyAvatar;

/* end elements definition *********************************************************************************************/



/* setup section *******************************************************************************************************/
void setup() {
  /* put setup code here, run once: */

  /* screen size definition */
  size(1200, 680);


  /* GUI setup */
  smooth();
  cp5 = new ControlP5(this);

  PFont p = createFont("Verdana", 17); 
  ControlFont font = new ControlFont(p);

  // change the original colors
  cp5.setColorForeground(0xffaa0000);
  //cp5.setColorBackground(0xff660000);
  cp5.setFont(font);
  cp5.setColorActive(0xffff0000);

  damper = cp5.addSlider("damp")
    .setPosition(100, 465)
    .setSize(200, 30)
    .setRange(300, 2000) // values can range from big to small as well
    .setValue(500)
    //.setFont(createFont("Verdana", 17))
    ;

  //spacing_s = cp5.addSlider("spacing")
  //  .setPosition(100, 505)
  //  .setSize(200, 30)
  //  .setRange(0, 30) // values can range from big to small as well
  //  .setValue(2)
  //  //.setFont(createFont("Verdana", 17))
  //  ;

  //wallwidth_s = cp5.addSlider("wallwidth")
  //  .setPosition(100, 545)
  //  .setSize(200, 30)
  //  .setRange(0, 30) // values can range from big to small as well
  //  .setValue(0.25)
  //  //.setFont(createFont("Verdana", 17))
  //  ;


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


  /* creation of axis */
  //a1                   = new FBox(26.0, 0.1);
  //a1.setPosition(edgeTopLeftX+worldWidth/2, edgeTopLeftY+worldHeight/2);
  //a1.setStatic(true);
  //a1.setFill(0, 0, 0);
  //world.add(a1);

  //a2                   = new FBox(0.1, 11.5);
  //a2.setPosition(edgeTopLeftX+worldWidth/2.0, edgeTopLeftY+worldHeight/2);
  //a2.setStatic(true);
  //a2.setFill(0, 0, 0);
  //world.add(a2);

  /* Set viscous layer */
  v1                  = new FBox(13, 6);
  v1.setPosition(edgeTopLeftX+2*worldWidth/3+1.5, edgeTopLeftY+2*worldHeight/3+0.5); //uses the mid point
  //v1.setPosition(15, 7.5);
  //println(edgeTopLeftX+2*worldWidth/3+1.5, edgeTopLeftY+2*worldHeight/3+0.5);
  v1.setFill(150, 150, 255, 80);
  v1.setNoStroke();
  v1.setDensity(100);
  v1.setSensor(true);
  v1.setNoStroke();
  v1.setStatic(true);
  v1.setName("Water");
  world.add(v1);

  //  c1                  = new FCircle(2.0); // diameter is 2
  //  c1.setPosition(edgeTopLeftX+2, edgeTopLeftY+worldHeight/2.0-5.5);
  //  c1.setFill(0, 200, 50);
  //  v1.setDensity(100);
  //  c1.setNoStroke();
  //  c1.setStaticBody(true);
  //  world.add(c1);


  for (int i=0; i<1; i++) {
    //print("here");
    l                   = new FBox(26.0, 0.5);
    l.setPosition(edgeTopLeftX+worldWidth/2, edgeTopLeftY+worldHeight/2+(i*1));
    l.setFill(150, 150, 255, 80);
    l.setNoStroke();
    l.setDensity(100);
    l.setSensor(true);
    l.setNoStroke();
    l.setStatic(true);
    l.setName("Water");
    world.add(l); 
    //print("here");
  }

  /* Bumps */

  b1                  = new FBox(2, 2);
  b1.setPosition(worldWidth/2-10, worldHeight/2-4.5);
  b1.setFill(40, 62, 102);
  b1.setDensity(100);
  b1.setSensor(true);
  b1.setNoStroke()  ;
  b1.setStatic(true);
  world.add(b1);

  b2                  = new FBox(1.5, 2);
  b2.setPosition(worldWidth/2-8, worldHeight/2-4.5);
  b2.setFill(40, 62, 102);
  b2.setDensity(100);
  b2.setSensor(true);
  b2.setNoStroke()  ;
  b2.setStatic(true);
  world.add(b2)     ;

  b3                  = new FBox(1.5, 2);
  b3.setPosition(worldWidth/2-6, worldHeight/2-4.5);
  b3.setFill(40, 62, 102);
  b3.setDensity(100);
  b3.setSensor(true);
  b3.setNoStroke()  ;
  b3.setStatic(true);
  world.add(b3)     ;

  b4                  = new FBox(0.25, 2);
  b4.setPosition(worldWidth/2-4, worldHeight/2-4.5);
  b4.setFill(40, 62, 102);
  b4.setDensity(100);
  b4.setSensor(true);
  b4.setNoStroke()  ;
  b4.setStatic(true);
  world.add(b4)     ;

  b5                  = new FBox(0.25, 2);
  b5.setPosition(worldWidth/2-2, worldHeight/2-4.5);
  b5.setFill(40, 62, 102);
  b5.setDensity(100);
  b5.setSensor(true);
  b5.setNoStroke()  ;
  b5.setStatic(true);
  world.add(b5)     ;

  b6                  = new FBox(0.25, 2);
  b6.setPosition(worldWidth/2-10, worldHeight/2-2);
  b6.setFill(40, 62, 102);
  b6.setDensity(100);
  b6.setSensor(true);
  b6.setNoStroke()  ;
  b6.setStatic(true);
  world.add(b6)     ;

  b7                  = new FBox(0.25, 2);
  b7.setPosition(worldWidth/2-8, worldHeight/2-2);
  b7.setFill(40, 62, 102);
  b7.setDensity(100);
  b7.setSensor(true);
  b7.setNoStroke()  ;
  b7.setStatic(true);
  world.add(b7)     ;

  b8                  = new FBox(0.25, 2);
  b8.setPosition(worldWidth/2-6, worldHeight/2-2);
  b8.setFill(40, 62, 102);
  b8.setDensity(100);
  b8.setSensor(true);
  b8.setNoStroke()  ;
  b8.setStatic(true);
  world.add(b8)     ;

  b9                  = new FBox(0.25, 2);
  b9.setPosition(worldWidth/2-4, worldHeight/2-2);
  b9.setFill(40, 62, 102);
  b9.setDensity(100);
  b9.setSensor(true);
  b9.setNoStroke()  ;
  b9.setStatic(true);
  world.add(b9)     ;

  b10                  = new FBox(0.25, 2);
  b10.setPosition(worldWidth/2-2, worldHeight/2-2);
  b10.setFill(40, 62, 102);
  b10.setDensity(100);
  b10.setSensor(true);
  b10.setNoStroke()  ;
  b10.setStatic(true);
  world.add(b10)     ;

  b11                  = new FBox(2, 2);
  b11.setPosition(worldWidth/2+10, worldHeight/2-4.5);
  b11.setFill(40, 62, 102);
  b11.setDensity(100);
  b11.setSensor(true);
  b11.setNoStroke()  ;
  b11.setStatic(true);
  world.add(b11);

  b12                  = new FBox(1.5, 2);
  b12.setPosition(worldWidth/2+8, worldHeight/2-4.5);
  b12.setFill(40, 62, 102);
  b12.setDensity(100);
  b12.setSensor(true);
  b12.setNoStroke()  ;
  b12.setStatic(true);
  world.add(b12)     ;

  b13                  = new FBox(1, 2);
  b13.setPosition(worldWidth/2+6, worldHeight/2-4.5);
  b13.setFill(40, 62, 102);
  b13.setDensity(100);
  b13.setSensor(true);
  b13.setNoStroke()  ;
  b13.setStatic(true);
  world.add(b13)     ;

  b14                  = new FBox(1.5, 2);
  b14.setPosition(worldWidth/2+4, worldHeight/2-4.5);
  b14.setFill(40, 62, 102);
  b14.setDensity(100);
  b14.setSensor(true);
  b14.setNoStroke()  ;
  b14.setStatic(true);
  world.add(b14)     ;

  b15                  = new FBox(2, 2);
  b15.setPosition(worldWidth/2+2, worldHeight/2-4.5);
  b15.setFill(40, 62, 102);
  b15.setDensity(100);
  b15.setSensor(true);
  b15.setNoStroke()  ;
  b15.setStatic(true);
  world.add(b15)     ;

  b16                  = new FBox(.5, 2);
  b16.setPosition(worldWidth/2+10, worldHeight/2-2);
  b16.setFill(40, 62, 102);
  b16.setDensity(100);
  b16.setSensor(true);
  b16.setNoStroke()  ;
  b16.setStatic(true);
  world.add(b16)     ;

  b17                  = new FBox(1.5, 2);
  b17.setPosition(worldWidth/2+8, worldHeight/2-2);
  b17.setFill(40, 62, 102);
  b17.setDensity(100);
  b17.setSensor(true);
  b17.setNoStroke()  ;
  b17.setStatic(true);
  world.add(b17)     ;

  b18                  = new FBox(2, 2);
  b18.setPosition(worldWidth/2+6, worldHeight/2-2);
  b18.setFill(40, 62, 102);
  b18.setDensity(100);
  b18.setSensor(true);
  b18.setNoStroke()  ;
  b18.setStatic(true);
  world.add(b18)     ;

  b19                  = new FBox(1.5, 2);
  b19.setPosition(worldWidth/2+4, worldHeight/2-2);
  b19.setFill(40, 62, 102);
  b19.setDensity(100);
  b19.setSensor(true);
  b19.setNoStroke()  ;
  b19.setStatic(true);
  world.add(b19)     ;

  b20                  = new FBox(0.5, 2);
  b20.setPosition(worldWidth/2+2, worldHeight/2-2);
  b20.setFill(40, 62, 102);
  b20.setDensity(100);
  b20.setSensor(true);
  b20.setNoStroke()  ;
  b20.setStatic(true);
  world.add(b20)     ;


  //a1                   = new FBox(26.0, 0.1);
  //a1.setPosition(edgeTopLeftX+worldWidth/2, edgeTopLeftY+worldHeight/2);
  //a1.setStatic(true);
  //a1.setFill(0, 0, 0);
  //world.add(a1); 

  //a1                   = new FBox(26.0, 0.1);
  //a1.setPosition(edgeTopLeftX+worldWidth/2, edgeTopLeftY+worldHeight/2);
  //a1.setStatic(true);
  //a1.setFill(0, 0, 0);
  //world.add(a1);

  //a1                   = new FBox(26.0, 0.1);
  //a1.setPosition(edgeTopLeftX+worldWidth/2, edgeTopLeftY+worldHeight/2);
  //a1.setStatic(true);
  //a1.setFill(0, 0, 0);
  //world.add(a1);

  //a1                   = new FBox(26.0, 0.1);
  //a1.setPosition(edgeTopLeftX+worldWidth/2, edgeTopLeftY+worldHeight/2);
  //a1.setStatic(true);
  //a1.setFill(0, 0, 0);
  //world.add(a1);

  //a1                   = new FBox(26.0, 0.1);
  //a1.setPosition(edgeTopLeftX+worldWidth/2, edgeTopLeftY+worldHeight/2);
  //a1.setStatic(true);
  //a1.setFill(0, 0, 0);
  //world.add(a1);


  /* Haptic Tool Initialization */
  s                   = new HVirtualCoupling((1)); 
  s.h_avatar.setDensity(4);  
  s.init(world, edgeTopLeftX+worldWidth/2, edgeTopLeftY+2); 



  /* If you are developing on a Mac users must update the path below 
   * from "../img/Haply_avatar.png" to "./img/Haply_avatar.png" 
   // */
  //haplyAvatar = loadImage("../img/Haply_avatar.png"); 
  //haplyAvatar.resize((int)(hAPI_Fisica.worldToScreen(1)), (int)(hAPI_Fisica.worldToScreen(1)));
  //s.h_avatar.attachImage(haplyAvatar); 


  /* world conditions setup */
  world.setGravity((0.0), (300.0)); //1000 cm/(s^2)
  world.setEdges((edgeTopLeftX), (edgeTopLeftY), (edgeBottomRightX), (edgeBottomRightY)); 
  world.setEdgesRestitution(.5);
  world.setEdgesFriction(1);




  world.draw();


  /* setup framerate speed */
  frameRate(baseFrameRate);


  /* setup simulation thread to run at 1kHz */
  SimulationThread st = new SimulationThread();
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);
}
/* end setup section ***************************************************************************************************/



/* draw section ********************************************************************************************************/
void draw() {
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
  if (renderingForce == false) {
    background(255);
    world.draw();
  }

  //createTexture (0, 0, 30, 15, 1);
  //
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

    s.setToolPosition(edgeTopLeftX+worldWidth/2-(posEE).x, edgeTopLeftY+(posEE).y-7); 


    s.updateCouplingForce();
    fEE.set(-s.getVirtualCouplingForceX(), s.getVirtualCouplingForceY());
    fEE.div(100000); //dynes to newtons

    torques.set(widgetOne.set_device_torques(fEE.array()));
    widgetOne.device_write_torques();

    if (s.h_avatar.isTouchingBody(v1)||s.h_avatar.isTouchingBody(l)) {
      s.h_avatar.setDamping(damp);
    } else {
      s.h_avatar.setDamping(10);
    }



    /* Density layers */
    if (s.h_avatar.isTouchingBody(b1)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b2)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b3)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b4)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b5)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b6)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b7)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b8)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b9)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b10)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b11)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b12)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b13)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b14)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b15)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b16)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b17)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b18)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b19)) {
      s.h_avatar.setDamping(damp);
    } else if (s.h_avatar.isTouchingBody(b20)) {
      s.h_avatar.setDamping(damp);
    }




    world.step(1.0f/1000.0f);

    renderingForce = false;
  }
}
/* end simulation section **********************************************************************************************/


int code = 0; //vertical line (1), horizontal line (2), criss cross (3)


/* helper functions section, place helper functions here ***************************************************************/
void createTexture (float x, float y, float dim_x, float dim_y, int code) { //x,y are top left positions and dim_x/y are dimensions of texture box,

  t_wallList = new ArrayList<Wall>();

  //spacing = 2; //spacing measure from starting line of each wall 
  //wallwidth = 0.25;

  //TODO: can be added as separate function
  if (code==1) { //vertical line
    for (int i=0; i < (dim_x/spacing); i++) {
      t_wallList.add(new Wall(wallwidth, dim_y, x+wallwidth/2+i*spacing, y+dim_y/2, 0x000000)); //width, height, x and y position
    }
  }

  if (code==2) { //horizontal line
    for (int i=0; i < (dim_y/spacing); i++) {
      t_wallList.add(new Wall(dim_x, wallwidth, x+dim_x/2, y+wallwidth/2+i*spacing, 0x000000)); //width, height, x and y position
    }
  }

  if (code==3) {  //criss cross lines
    for (int i=0; i < (dim_y/spacing); i++) {
      t_wallList.add(new Wall(dim_x, wallwidth, x+dim_x/2, y+wallwidth/2+i*spacing, 0x000000)); //width, height, x and y position
    }
    for (int i=0; i < (dim_x/spacing); i++) {
      t_wallList.add(new Wall(wallwidth, dim_y, x+wallwidth/2+i*spacing, y+dim_y/2, 0x000000)); //width, height, x and y position
    }
  }

  //wallList.add(new Wall(2, 0.1, edgeTopLeftX+j+0.5, edgeTopLeftY+i-0.5, 0x000000));

  FBox wall;

  for (Wall item : t_wallList) {
    /* creation of wall */
    wall = new FBox(item.getW(), item.getH());
    wall.setPosition(item.getX(), item.getY());
    wall.setStatic(true);
    int c = item.getColor();
    wall.setFill(c);

    wall.setDensity(100);
    wall.setSensor(true);
    wall.setNoStroke();
    world.add(wall);
  }
}


/* end helper functions section ****************************************************************************************/
