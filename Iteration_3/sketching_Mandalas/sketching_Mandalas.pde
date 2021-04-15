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
FBox    wall      ;
FCircle myCircle1 ;
FCircle myCircle2 ;
FCircle myCircle3 ;
FCircle myCircle4 ;
FLine line1       ;
FLine square      ;
FPoly myPoly      ;

/* Initialization of virtual tool */
HVirtualCoupling s;
PImage haplyAvatar;

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
  wall                   = new FBox(5.0, 1.0)            ;
  wall.setPosition(worldWidth/2.0-10, worldHeight/2.0-5) ;
  wall.setDensity(100)                              ;
  wall.setSensor(false)                             ;
  wall.setStatic(true)                              ;
  wall.setFill(0,0,0)                               ;
  world.add(wall)                                   ;

   
  // MANDALAS //
  
  float c = 5.75;
  float[] cornerx = {worldWidth/2-c, worldWidth/2+c, worldWidth/2+c, worldWidth/2-c, worldWidth/2-c}     ;
  float[] cornery = {worldHeight/2-c, worldHeight/2-c, worldHeight/2+c, worldHeight/2+c, worldHeight/2-c};
  
  for (int i = 0; i < 4; i++){
    FLine square = new FLine(cornerx[i], cornery[i], cornerx[i+1], cornery[i+1]);
    world.add(square);
  }
  
  

  float circles = 2 ;
  
  if (circles == 4){         // MANDALA 1
  
    float D = 2.5 ;
  
    for (int i = 0; i < circles; i++){
      FCircle myCircle1 = new FCircle(D)                 ;
      myCircle1.setPosition(worldWidth/2, worldHeight/2) ;
      myCircle1.setStatic(true)                          ;
      myCircle1.setNoFill()                              ;
      world.add(myCircle1)                               ;
      D = D + 3;
    }
    
    int n = 8   ;
    float d = 3 ;
    float xO  ;
    float yO  ;
  
    for (int i = 0; i < n; i++){
      xO = 4.25 * sin(i * TWO_PI/n) ;
      yO = 4.25 * cos(i * TWO_PI/n) ;
    
      FCircle myCircle1 = new FCircle(d) ;
      myCircle1.setPosition(xO+(worldWidth/2), yO+(worldHeight/2)) ;
      myCircle1.setStatic(true) ;
      myCircle1.setNoFill()     ;
      world.add(myCircle1)      ;
    }
  
  } else if (circles == 3) {  // MANDALA 2
    
    float D = 1.5 ;
    
    for (int i = 0; i < circles; i++){
      FCircle myCircle1 = new FCircle(D)                 ;
      myCircle1.setPosition(worldWidth/2, worldHeight/2) ;
      myCircle1.setStatic(true)                          ;
      myCircle1.setNoFill()                              ;
      world.add(myCircle1)                               ;
      D = D + 5                                          ;
    }
    
    int n = 8 ;
    float d = 2.5 ;
    float xO  ;
    float yO  ;
  
    for (int i = 0; i < n; i++){
      xO = 4.5 * sin(i * TWO_PI/n) ;
      yO = 4.5 * cos(i * TWO_PI/n) ;
    
      FCircle myCircle1 = new FCircle(d) ;
      myCircle1.setPosition(xO+(worldWidth/2), yO+(worldHeight/2)) ;
      myCircle1.setStatic(true) ;
      myCircle1.setNoFill()     ;
      world.add(myCircle1)      ;
    }
    
    int m = 2    ;
    float h = 2.3;
  
    for (int i = 0; i < m; i++){
      FLine line1 = new FLine(worldWidth/2, worldHeight/2-(3.25), worldWidth/2-h, worldHeight/2+(abs(h)));
      world.add(line1);
      h = -h;
    }
  
    for (int i = 0; i < m; i++){
      FLine line1 = new FLine(worldWidth/2, worldHeight/2+(3.25), worldWidth/2-h, worldHeight/2-(abs(h)));
      world.add(line1);
      h = -h;
    }
  
    for (int i = 0; i < m; i++){
      FLine line1 = new FLine(worldWidth/2-h, worldHeight/2+h, worldWidth/2+h, worldHeight/2+h);
      world.add(line1);
      h = -h;
    }
  
  } else if (circles == 2) {  // MANDALA 3
    
    float D = 2.5 ;
  
    for (int i = 0; i < circles; i++){
      FCircle myCircle1 = new FCircle(D)                 ;
      myCircle1.setPosition(worldWidth/2, worldHeight/2) ;
      myCircle1.setStatic(true)                          ;
      myCircle1.setNoFill()                              ;
      world.add(myCircle1)                               ;
      D = D + 3;
    }
    
    float l = 5.75;
    float[] verticesx = {worldWidth/2, worldWidth/2+l, worldWidth/2, worldWidth/2-l, worldWidth/2}       ;
    float[] verticesy = {worldHeight/2-l, worldHeight/2, worldHeight/2+l, worldHeight/2, worldHeight/2-l};

    for (int i = 0; i < 4; i++){
      FLine line1 = new FLine(verticesx[i], verticesy[i], verticesx[i+1], verticesy[i+1]);
      world.add(line1);
    }
    
   
  } else {
  
  
  }
  
  
  
  
  
  /* Haptic Tool Initialization */
  s = new HVirtualCoupling((0.5)); 
  s.h_avatar.setDensity(4)       ;
  s.h_avatar.setNoStroke()       ;
  s.h_avatar.setFill(0,0,250)    ;
  s.init(world, edgeTopLeftX+worldWidth/2, edgeTopLeftY+2);
  /* If you are developing on a Mac users must update the path below 
   * from "../img/Haply_avatar.png" to "./img/Haply_avatar.png" 
   */
  //haplyAvatar = loadImage("../img/Haply_avatar.png"); 
  //haplyAvatar.resize((int)(hAPI_Fisica.worldToScreen(1)), (int)(hAPI_Fisica.worldToScreen(1)));
  //s.h_avatar.attachImage(haplyAvatar);

  /* world conditions setup */
  world.setGravity((0.0), (0.0)); //1000 cm/(s^2)
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
  
  /* For "dist" method to grab increase damping */
  //text("Haply X = " + s.h_avatar.getX(), 40, 60)  ;
  //text("Haply Y = " + s.h_avatar.getY(), 250, 60) ;
  //text("min dist = " + min_dist, 40, 90)          ;
  //textSize(16)                                    ;
  //fill(0, 0, 0)                                   ;


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

    world.step(1.0f/1000.0f);
    renderingForce = false  ;
    }
}


/* end simulation section **********************************************************************************************/


/* helper functions section, place helper functions here ***************************************************************/


/* end helper functions section ****************************************************************************************/
