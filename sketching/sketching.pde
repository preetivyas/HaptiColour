/* library imports *****************************************************************************************************/ 
import processing.serial.*                   ;
import static java.util.concurrent.TimeUnit.*;
import java.util.concurrent.*                ;
import controlP5.*                           ;
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
float             pixelsPerCentimeter                 = 40;

/* generic data for a 2DOF device */
/* joint space */
PVector           angles                              = new PVector(0, 0);
PVector           torques                             = new PVector(0, 0);

/* task space */
PVector           posEE                               = new PVector(0, 0);
PVector           fEE                                 = new PVector(0, 0); 


/* World boundaries in centimeters */
FWorld            world;
float             worldWidth                          = 30.0;  
float             worldHeight                         = 15.0; 
float             edgeTopLeftX                        = 0.0; 
float             edgeTopLeftY                        = 0.0; 
float             edgeBottomRightX                    = worldWidth; 
float             edgeBottomRightY                    = worldHeight;


/* Initialization of walls */
FBox              wall ;

FBox             damper;

FBox           dampers ;
FBox           damper1 ;
FBox           damper2 ;
FBox           damper3 ;
FCircle              C ;
FCircle          bumps ;
FCircle             var;

int m = 0 ;
int last = 0;

float x_pos = -50     ;
float y_pos = -50     ;
float x = 0           ;
float y = 0           ;
float temp = 0.0      ;
float min_dist = 0.0  ;
float x1, x2, x3, x4, y1, y2, y3, y4;

/* Initialization of virtual tool */
HVirtualCoupling s;
PImage            haplyAvatar;

/* end elements definition *********************************************************************************************/ 


String[]          button_label      =      {"b1", "b2", "b3", "b4", "b5", "b6"} ;


/* setup section *******************************************************************************************************/
void setup(){
  /* put setup code here, run once: */
  
  /* screen size definition */
  size(1200, 600);
  
    /* setup UI elements */
  smooth();
  cp5 = new ControlP5(this);
  
  cp5.addButton("Wallitself")
    .setValue(0)
    .setPosition(40,250)
    .setSize(150,30)
    .setColorValue((255))
    ;
  
  cp5.addButton("SingleDampingLayer")
    .setValue(0)
    .setPosition(40,300)
    .setSize(150,30)
    .setColorValue((255))
    ;
    
  cp5.addButton("GradualDampingLayers")
    .setValue(0)
    .setPosition(40,350)
    .setSize(150,30)
    .setColorValue((255))
    ;
    
  cp5.addButton("TranslucentCircle")
    .setValue(0)
    .setPosition(40,400)
    .setSize(150,30)
    .setColorValue((255))
    ;
    
  cp5.addButton("BumpyWall")
    .setValue(0)
    .setPosition(40,450)
    .setSize(150,30)
    .setColorValue((255))
    ;

  cp5.addButton("RESET")
    .setValue(0)
    .setPosition(40,500)
    .setSize(150,30)
    .setColorValue((255))
    ;
  
  noStroke()     ;
  
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
  haplyBoard          = new Board(this, "COM3", 0);
  widgetOne           = new Device(widgetOneID, haplyBoard);
  pantograph          = new Pantograph();
  
  widgetOne.set_mechanism(pantograph);
  
  widgetOne.add_actuator(1, CCW, 2);
  widgetOne.add_actuator(2, CW, 1) ;
  widgetOne.add_encoder(1, CCW, 241, 10752, 2);
  widgetOne.add_encoder(2, CW, -61, 10752, 1) ;
  widgetOne.device_set_parameters();
  
  /* 2D physics scaling and world creation */
  hAPI_Fisica.init(this); 
  hAPI_Fisica.setScale(pixelsPerCentimeter); 
  world               = new FWorld();
  
  /* creation of walls */
  wall                   = new FBox(10.0, 1.0)      ;
  wall.setPosition(worldWidth/2.0, worldHeight/2.0) ;
  wall.setDensity(100)                              ;
  wall.setSensor(false)                             ;
  wall.setStatic(true)                              ;
  wall.setFill(0,0,0)                               ;
  world.add(wall)                                   ;
  
  var = new FCircle(0.5)      ;
  var.setDensity(100)         ;
  var.setPosition(1500, 1500) ;
  var.setStatic(false)        ;
  var.setSensor(false)        ;
  var.setFill(255,0,0)        ;
  world.add(var)              ;
  
  x1 = (worldWidth/2.0 - 5.0) ;  // TOP left corner
  y1 = (worldHeight/2.0 - 0.5);  // TOP left corner
  x2 = (worldWidth/2.0 + 5.0) ;  // TOP right corner
  y2 = y1                        ;  // TOP right corner
  x3 = x1                        ;  // BOTTOM left corner
  y3 = (worldHeight/2.0 + 0.5);  // BOTTOM left corner
  x4 = x2                        ;  // BOTTOM right corner
  y4 = y3                        ;  // BOTTOM right corner
  
  
  /* Haptic Tool Initialization */
  s                   = new HVirtualCoupling((0.5)); 
  s.h_avatar.setDensity(4);
  s.h_avatar.setNoStroke();
  s.h_avatar.setFill(0,0,250);
  s.init(world, edgeTopLeftX+worldWidth/2, edgeTopLeftY+2);
  /* If you are developing on a Mac users must update the path below 
   * from "../img/Haply_avatar.png" to "./img/Haply_avatar.png" 
   */
  //haplyAvatar = loadImage("../img/Haply_avatar.png"); 
  //haplyAvatar.resize((int)(hAPI_Fisica.worldToScreen(1)), (int)(hAPI_Fisica.worldToScreen(1)));
  //s.h_avatar.attachImage(haplyAvatar);

  /* world conditions setup */
  world.setGravity((0.0), (1000.0)); //1000 cm/(s^2)
  world.setEdges((edgeTopLeftX), (edgeTopLeftY), (edgeBottomRightX), (edgeBottomRightY)); 
  world.setEdgesRestitution(.4);
  world.setEdgesFriction(0.5);
  
  world.draw();
  
  /* setup framerate speed */
  frameRate(baseFrameRate);
  
  /* setup simulation thread to run at 1kHz */ 
  SimulationThread st = new SimulationThread();
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);  
}
/* end setup section ***************************************************************************************************/



/* buttons action section **********************************************************************************************/

public void Wallitself(int theValue) {
  wall.setSensor(true)  ;
  world.remove(damper)  ;
  world.remove(damper1) ;
  world.remove(damper2) ;
  world.remove(damper3) ;
  world.remove(C)       ;
  var.setSensor(false)  ;
  world.remove(bumps)   ;
}

public void SingleDampingLayer(int theValue) {
  
  wall.setSensor(false);
  world.remove(C)      ;
  world.remove(damper1);
  world.remove(damper2);
  world.remove(damper3);
  var.setSensor(false) ;
  
  damper                 = new FBox(10.0, 1.0)          ;
  damper.setPosition(worldWidth/2.0, worldHeight/2.0-1) ;
  damper.setDensity(100)                                ;
  damper.setStatic(true)                                ;
  damper.setFill(0,0,255,10)                            ;
  damper.setNoStroke()                                  ;
  damper.setSensor(true)                                ;
  world.add(damper)                                     ;
  
}

public void GradualDampingLayers(int theValue) {
  
  wall.setSensor(false);
  world.remove(damper) ;
  world.remove(C)      ;
  var.setSensor(false) ;
  
  damper1                 = new FBox(10.0, 1.0)          ;
  damper1.setPosition(worldWidth/2.0, worldHeight/2.0-3) ;
  damper1.setDensity(100)                                ;
  damper1.setStatic(true)                                ;
  damper1.setFill(0,0,255,5)                             ;
  damper1.setNoStroke()                                  ;
  damper1.setSensor(true)                                ;
  world.add(damper1)                                     ;
  
  damper2                 = new FBox(10.0, 1.0)          ;
  damper2.setPosition(worldWidth/2.0, worldHeight/2.0-2) ;
  damper2.setDensity(100)                                ;
  damper2.setStatic(true)                                ;
  damper2.setFill(0,0,255,10)                            ;
  damper2.setNoStroke()                                  ;
  damper2.setSensor(true)                                ;
  world.add(damper2)                                     ;
  
  damper3                 = new FBox(10.0, 1.0)          ;
  damper3.setPosition(worldWidth/2.0, worldHeight/2.0-1) ;
  damper3.setDensity(100)                                ;
  damper3.setStatic(true)                                ;
  damper3.setFill(0,0,255,15)                            ;
  damper3.setNoStroke()                                  ;
  damper3.setSensor(true)                                ;
  world.add(damper3)                                     ;
  
}

public void TranslucentCircle(int theValue) {
  
  /* Collision bubble or circle */
  C                  = new FCircle(1.5);
  C.setDensity(0.01);
  C.setSensor(true) ;
  C.setNoFill()     ;
  C.setStroke(0,0,0);
  C.setPosition(3,3);
  world.add(C)      ;
  
  world.remove(damper1);
  world.remove(damper2);
  world.remove(damper3);
  wall.setSensor(false);
  var.setSensor(false) ;
  
}


public void BumpyWall(int theValue) {
  
  var.setSensor(true)  ;
  world.remove(damper) ;
  world.remove(damper1);
  world.remove(damper2);
  world.remove(damper3);
  wall.setSensor(false);
  world.remove(C)      ;
  
}


public void RESET(int theValue) {
  wall.setSensor(false) ;
  world.remove(damper)  ;
  world.remove(damper1) ;
  world.remove(damper2) ;
  world.remove(damper3) ;
  world.remove(C)       ;
  var.setSensor(false)  ;
}


/* draw section ********************************************************************************************************/
void draw(){
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */

  
  if(renderingForce == false){
   background(230) ;
   world.draw()    ;
  }
  
  /* For "dist" method to grab increase damping */
  //text("Haply X = " + s.h_avatar.getX(), 40, 60)  ;
  //text("Haply Y = " + s.h_avatar.getY(), 250, 60) ;
  //text("min dist = " + min_dist, 40, 90)          ;
  textSize(16)                                    ;
  fill(0, 0, 0)                                   ;

  
  if ( ((s.h_avatar.getX() <= x1) || (s.h_avatar.getX() >= x2)) && ((s.h_avatar.getY() <= y1) || (s.h_avatar.getY() >= y3))  ) {                                                 // if avatar is perfectly located at a corner
    min_dist = min(min(dist(x1,y1,s.h_avatar.getX(),s.h_avatar.getY()),dist(x2,y2,s.h_avatar.getX(),s.h_avatar.getY())), min(dist(x3,y3,s.h_avatar.getX(),s.h_avatar.getY()),dist(x4,y4,s.h_avatar.getX(),s.h_avatar.getY())));

  } else if( (s.h_avatar.getX() > x1)  && (s.h_avatar.getX() < x2) && ((s.h_avatar.getY() < y1) || (s.h_avatar.getY() > y3)) ) {                                                 // if avatar is outside the box, but closer to top/bottom
    min_dist = min(abs(s.h_avatar.getY() - y1), abs(s.h_avatar.getY() - y3));

  } else if( (s.h_avatar.getY() > y1) && (s.h_avatar.getY() < y3) && ((s.h_avatar.getX() < x1) || (s.h_avatar.getX() > x2)) ) {                                                  // if avatar is outside the box, but closer to left/right
   min_dist = min(abs(s.h_avatar.getX() - x1), abs(s.h_avatar.getX() - x2));
  }

}
/* end draw section ****************************************************************************************************/


/* simulation section **************************************************************************************************/
class SimulationThread implements Runnable{

  public void run(){
    /* put haptic simulation code here, runs repeatedly at 1kHz as defined in setup */
    
    renderingForce = true;
    
    if(haplyBoard.data_available()){
      /* GET END-EFFECTOR STATE (TASK SPACE) */
      widgetOne.device_read_data()                             ;
      angles.set(widgetOne.get_device_angles())                ;
      posEE.set(widgetOne.get_device_position(angles.array())) ;
      posEE.set(posEE.copy().mult(200))                        ;
    }
    
    s.setToolPosition(edgeTopLeftX+worldWidth/2-(posEE).x, edgeTopLeftY+(posEE).y-7);
    C.setPosition(s.h_avatar.getX(), s.h_avatar.getY());
    //joint_Formation();
    
    s.updateCouplingForce();
    fEE.set(-s.getVirtualCouplingForceX(), s.getVirtualCouplingForceY());
    fEE.div(100000); //dynes to newtons
    torques.set(widgetOne.set_device_torques(fEE.array()));
    widgetOne.device_write_torques();
    
    
    if (s.h_avatar.isTouchingBody(wall) && wall.isSensor()){
      s.h_avatar.setDamping(950);
    
    } else if (s.h_avatar.isTouchingBody(damper)){
      s.h_avatar.setDamping(950);
    
    } else if (s.h_avatar.isTouchingBody(damper1)){
      s.h_avatar.setDamping(900);
      
    } else if (s.h_avatar.isTouchingBody(damper2)){
      s.h_avatar.setDamping(925);
      
    } else if (s.h_avatar.isTouchingBody(damper3)){
      s.h_avatar.setDamping(950);
      
    } else if (C.isTouchingBody(wall)){
      s.h_avatar.setDamping(950);
    
    } else if (s.h_avatar.isTouchingBody(wall) && var.isSensor()){
      
      int bs = 2;
      
      for (int i = 0; i < bs; i++){
      
        bumps = new FCircle(0.5)                               ;
        bumps.setDensity(100)                                  ;
        bumps.setPosition(s.h_avatar.getX(), s.h_avatar.getY());
        bumps.setStatic(false)                                 ;
        bumps.setFill(255,0,0)                                 ;
        world.add(bumps)                                       ;
      }
      
    } else{
      s.h_avatar.setDamping(500);
    }
    
    //if (min_dist <=1 ){
    //  s.h_avatar.setDamping(980);
    //}
    //else{
    //  s.h_avatar.setDamping(500);
    //}

    world.step(1.0f/1000.0f);
    renderingForce = false  ;
    }
}


/* end simulation section **********************************************************************************************/


/* helper functions section, place helper functions here ***************************************************************/


/* end helper functions section ****************************************************************************************/
