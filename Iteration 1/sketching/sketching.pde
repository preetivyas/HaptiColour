
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


/* Initialization of wall */
FBox              wall;

float x_pos = -50     ;
float y_pos = -50     ;
float temp = 0.0      ;
float min_dist = 0.0  ;
float x1, x2, x3, x4, y1, y2, y3, y4;


/* Initialization of virtual tool */
HVirtualCoupling  s;
PImage            haplyAvatar;

/* end elements definition *********************************************************************************************/ 



/* setup section *******************************************************************************************************/
void setup(){
  /* put setup code here, run once: */
  
  /* screen size definition */
  size(1200, 600);
  
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
  widgetOne.add_actuator(2, CW, 1);
 
  widgetOne.add_encoder(1, CCW, 241, 10752, 2);
  widgetOne.add_encoder(2, CW, -61, 10752, 1);
  
  
  widgetOne.device_set_parameters();
  
  
  /* 2D physics scaling and world creation */
  hAPI_Fisica.init(this); 
  hAPI_Fisica.setScale(pixelsPerCentimeter); 
  world               = new FWorld();
  
  
  /* creation of wall */
  wall                   = new FBox(10.0, 1.0)     ;
  wall.setPosition(worldWidth/2.0, worldHeight/2.0);
  wall.setStatic(true)                             ;
  wall.setFill(0, 0, 0)                            ;
  world.add(wall)                                  ;
  
  x1 = 40*(worldWidth/2.0 - 5.0) ;  // TOP left corner
  y1 = 40*(worldHeight/2.0 - 0.5);  // TOP left corner
  x2 = 40*(worldWidth/2.0 + 5.0) ;  // TOP right corner
  y2 = y1                        ;  // TOP right corner
  x3 = x1                        ;  // BOTTOM left corner
  y3 = 40*(worldHeight/2.0 + 0.5);  // BOTTOM left corner
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


/* draw section ********************************************************************************************************/
void draw(){
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */
  
  if(renderingForce == false){
   background(230) ;
   world.draw()    ;
  }
  
  rect(x1, y1, 10, 10);
  
  //text(40*(posEE).x, 50, 80) ;
  //text(40*(posEE).y, 50, 100);
  //ellipse(40*(edgeTopLeftX+worldWidth/2-(posEE).x), 40*(edgeTopLeftY+(posEE).y-7), 10, 10);
  
  x_pos = 40*(edgeTopLeftX+worldWidth/2-(posEE).x);
  y_pos = 40*(edgeTopLeftY+(posEE).y-7)           ;
  text("x_pos = " + x_pos, 50, 80)                ;
  text("y_pos = " + y_pos, 50, 100)               ;
  text("min dist = " + min_dist, 50, 150)         ;
  textSize(18)                                    ;
  fill(0, 102, 153)                               ;
  
  
  if ( ((x_pos <= x1) || (x_pos >= x2)) && ((y_pos <= y1) || (y_pos >= y3))  ) {                                                 // if avatar is perfectly located at a corner
    min_dist = min(min(dist(x1,y1,x_pos,y_pos),dist(x2,y2,x_pos,y_pos)), min(dist(x3,y3,x_pos,y_pos),dist(x4,y4,x_pos,y_pos)));

  } else if( (x_pos > x1)  && (x_pos < x2) && ((y_pos < y1) || (y_pos > y3)) ) {                                                 // if avatar is outside the box, but closer to top/bottom
    min_dist = min(abs(y_pos - y1), abs(y_pos - y3));

  } else if( (y_pos > y1) && (y_pos < y3) && ((x_pos < x1) || (x_pos > x2)) ) {                                                  // if avatar is outside the box, but closer to left/right
   min_dist = min(abs(x_pos - x1), abs(x_pos - x2));
  }
  //} else {                                                                                                                       // if avatar is inside the box
  //  min_dist = min(min(abs(y_pos - y1), abs(y_pos - y3)),min(abs(x_pos - x1), abs(x_pos - x2)));                                 
  //}
  
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
    
    s.updateCouplingForce();
    fEE.set(-s.getVirtualCouplingForceX(), s.getVirtualCouplingForceY());
    fEE.div(100000); //dynes to newtons
    torques.set(widgetOne.set_device_torques(fEE.array()));
    widgetOne.device_write_torques();
    
    if (min_dist <=60 ){
      s.h_avatar.setDamping(980);
    }
    else{
      s.h_avatar.setDamping(500);
    }
    
    world.step(1.0f/1000.0f);
    renderingForce = false  ;
    }
}


/* end simulation section **********************************************************************************************/


/* helper functions section, place helper functions here ***************************************************************/


/* end helper functions section ****************************************************************************************/
