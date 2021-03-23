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
float             worldWidth                          = 30.0        ;  
float             worldHeight                         = 15.0        ;
float             edgeTopLeftX                        = 0.0         ;
float             edgeTopLeftY                        = 0.0         ;
float             edgeBottomRightX                    = worldWidth  ;
float             edgeBottomRightY                    = worldHeight ;

/* Initialization of walls */
FBox              wall ;
FBox              rec1 ;
FBox              rec2 ;
FBox              rec3 ;
FBox              rec4 ;
FBox              area1;
FBox              area2;
FBox              area3;
FBox              area4;
FBox              area5;
FCircle              C ;
FCircle              F ;
FCircle          bumps ;
FCircle            var1;

float lasttimecheck ;
float timeinterval  ;
float t             ;
float lasttimecheck1;
float timeinterval1 ;
float t1            ;
float lasttimecheck2;
float timeinterval2 ;
float t2            ;
float r = 1             ;
float theta = 0         ;
float theta_diff = 0.005;
float m = 0.0013        ;


/* Initialization of virtual tool */
HVirtualCoupling s;
PImage haplyAvatar;

/* end elements definition *********************************************************************************************/ 


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
    .setPosition(40,300)
    .setSize(150,30)
    .setColorValue((255))
    ;
    
  cp5.addButton("TranslucentCircle")
    .setValue(0)
    .setPosition(40,350)
    .setSize(150,30)
    .setColorValue((255))
    ;
    
  cp5.addButton("BumpyWall")
    .setValue(0)
    .setPosition(40,400)
    .setSize(150,30)
    .setColorValue((255))
    ;
    
  cp5.addButton("Forces")
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
  
  /* creation of walls and areas */
  wall                   = new FBox(10.0, 0.50)        ;
  wall.setPosition(worldWidth/2.0-8, worldHeight/2.0-4);
  wall.setDensity(100)                                 ;
  wall.setSensor(false)                                ;
  wall.setStatic(true)                                 ;
  wall.setHaptic(true)                                 ;
  wall.setFill(0,0,0)                                  ;
  world.add(wall)                                      ;
  
  //rec1                   = new FBox(0.5, 5)               ;
  //rec1.setPosition(worldWidth/2.0+3, worldHeight/2.0-3.25);
  //rec1.setDensity(100)                                    ;
  //rec1.setSensor(false)                                   ;
  //rec1.setStatic(true)                                    ;
  //rec1.setHaptic(true)                                    ;
  //rec1.setFill(10,20,130)                                 ;
  //world.add(rec1)                                         ;
  
  //rec2                   = new FBox(9.5, 0.5)          ;
  //rec2.setPosition(worldWidth/2.0+8, worldHeight/2.0-1);
  //rec2.setDensity(100)                                 ;
  //rec2.setSensor(false)                                ;
  //rec2.setStatic(true)                                 ;
  //rec2.setHaptic(true)                                 ;
  //rec2.setFill(10,20,130)                              ;
  //world.add(rec2)                                      ;
  
  //rec3                   = new FBox(0.5, 5.0)              ;
  //rec3.setPosition(worldWidth/2.0+13, worldHeight/2.0-3.25);
  //rec3.setDensity(100)                                     ;
  //rec3.setSensor(false)                                    ;
  //rec3.setStatic(true)                                     ;
  //rec3.setHaptic(true)                                     ;
  //rec3.setFill(10,20,130)                                  ;
  //world.add(rec3)                                          ;
  
  //rec4                   = new FBox(8.75, 0.5)            ;
  //rec4.setPosition(worldWidth/2.0+8.125, worldHeight/2.0-6);
  //rec4.setDensity(100)                                    ;
  //rec4.setSensor(false)                                   ;
  //rec4.setStatic(true)                                    ;
  //rec4.setHaptic(true)                                    ;
  //rec4.setFill(10,20,130)                                 ;
  //world.add(rec4)                                         ;
  
  area1                  = new FBox(7.0, 6.0)           ;
  area1.setPosition(worldWidth/2.0-6, worldHeight/2.0+3.5);
  area1.setDensity(0)                                   ;
  area1.setSensor(true)                                 ;
  area1.setStatic(true)                                 ;
  area1.setNoStroke()                                   ;
  area1.setFill(0,0,255,30)                             ;
  world.add(area1)                                      ;
  
  area2                  = new FBox(7.0, 6.0)           ;
  area2.setPosition(worldWidth/2.0+2, worldHeight/2.0+3.5);
  area2.setDensity(0)                                   ;
  area2.setSensor(true)                                 ;
  area2.setStatic(true)                                 ;
  area2.setNoStroke()                                   ;
  area2.setFill(0,255,0,30)                             ;
  world.add(area2)                                      ;
  
  area3                  = new FBox(7.0, 6.0)            ;
  area3.setPosition(worldWidth/2.0+10, worldHeight/2.0+3.5);
  area3.setDensity(0)                                    ;
  area3.setSensor(true)                                  ;
  area3.setStatic(true)                                  ;
  area3.setNoStroke()                                    ;
  area3.setFill(255,0,0,30)                              ;
  world.add(area3)                                       ;
  
  area4                  = new FBox(7.0, 6.0)              ;
  area4.setPosition(worldWidth/2.0+10, worldHeight/2.0-3);
  area4.setDensity(0)                                      ;
  area4.setSensor(true)                                    ;
  area4.setStatic(true)                                    ;
  area4.setNoStroke()                                      ;
  area4.setFill(255,205,0,30)                              ;
  world.add(area4)                                         ;
  
  area5                  = new FBox(7.0, 6.0)             ;
  area5.setPosition(worldWidth/2.0+2, worldHeight/2.0-3);
  area5.setDensity(0)                                     ;
  area5.setSensor(true)                                   ;
  area5.setStatic(true)                                   ;
  area5.setNoStroke()                                     ;
  area5.setFill(230,0,126,30)                             ;
  world.add(area5)                                        ;
  
  var1 = new FCircle(0.5)      ;
  var1.setDensity(100)         ;
  var1.setPosition(1500, 1500) ;
  var1.setStatic(false)        ;
  var1.setSensor(false)        ;
  var1.setFill(255,0,0)        ;
  world.add(var1)              ;
  

  /* Ball pits area */
  
  //int beads = 50;
  
  //float size, x, y, r, g, b;
  
  //FCircle bead;
  
  //for(int i = 0; i < beads; i++){
  //  size = random(0.6, 0.65);
  //  r    = random(0, 256)   ;
  //  g    = random(0, 256)   ;
  //  b    = random(0, 256)   ;
  //  x    = random(1.5, 5)   ;
  //  y    = random(4, 9)     ;
    
  //  bead = new FCircle(size)           ;
  //  bead.setPosition(random(20,26),2.5);
  //  bead.setFill(r, g, b)              ;
  //  bead.setFriction(5)                ;
  //  bead.setDensity(5)                 ;
  //  bead.setHaptic(true)               ;
  //  bead.setStaticBody(false)          ;
  //  bead.setName("FCircle")            ;
  //  world.add(bead)                    ;
  //}
  



  /* Timers */
  lasttimecheck = millis() ;
  timeinterval = 500       ;
  
  lasttimecheck1 = millis();
  timeinterval1 = 200      ;
  
  lasttimecheck2 = millis();
  timeinterval2 = 1000     ;
  
  
  /* Haptic Tool Initialization */
  s = new HVirtualCoupling((0.5)) ; 
  s.h_avatar.setDensity(4)        ;
  s.h_avatar.setNoStroke()        ;
  s.h_avatar.setFill(255,0,0)     ;
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
  world.setEdgesFriction(0.5)  ;
  
  world.draw();
  
  /* setup framerate speed */
  frameRate(baseFrameRate);
  
  /* setup simulation thread to run at 1kHz */ 
  SimulationThread st = new SimulationThread()         ;
  scheduler.scheduleAtFixedRate(st, 1, 1, MILLISECONDS);  
}
/* end setup section ***************************************************************************************************/



/* buttons action section **********************************************************************************************/

public void Wallitself(int theValue) {
  wall.setSensor(true)  ;
  world.remove(C)       ;
  world.remove(F)       ;
  var1.setSensor(false) ;
  world.remove(bumps)   ;
}


public void TranslucentCircle(int theValue) {
  
  /* Collision bubble or circle */
  C = new FCircle(1.5);
  C.setDensity(0.01)  ;
  C.setSensor(true)   ;
  C.setNoFill()       ;
  C.setStroke(0,0,0)  ;
  C.setPosition(3,3)  ;
  world.add(C)        ;
  
  world.remove(F)      ;
  wall.setSensor(false);
  var1.setSensor(false);
  
}


public void BumpyWall(int theValue) {
  
  var1.setSensor(true) ;
  wall.setSensor(false);
  world.remove(C)      ;
  world.remove(F)      ;
  
}


public void Forces(int theValue) {
  
  F = new FCircle(1)   ;
  F.setDensity(0.01)   ;
  F.setSensor(true)    ;
  F.setNoFill()        ;
  F.setStroke(0,0,0,30);
  F.setPosition(3,3)   ;
  world.add(F)         ;
  
  var1.setSensor(false);
  wall.setSensor(false);
  world.remove(C)      ;
  
}


public void RESET(int theValue) {
  wall.setSensor(false) ;
  world.remove(C)       ;
  world.remove(F)       ;
  var1.setSensor(false) ;
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
  //text("timer2 = " + t2, 40, 90)   ;
  //text("fEEx = " + fEE.x, 40, 110);
  //text("fEEy = " + fEE.y, 40, 130);
  textSize(16)                 ;
  fill(0, 0, 0)                ;


}
/* end draw section ****************************************************************************************************/


/* simulation section **************************************************************************************************/
class SimulationThread implements Runnable{

  public void run(){
    /* put haptic simulation code here, runs repeatedly at 1kHz as defined in setup */
    
    t = 0  ;
    t1 = 0 ;
    t2 = 0 ;
    
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
    F.setPosition(s.h_avatar.getX(), s.h_avatar.getY());
    //joint_Formation();
    
    s.updateCouplingForce();
    fEE.set(-s.getVirtualCouplingForceX(), s.getVirtualCouplingForceY());
    fEE.div(100000); //dynes to newtons
    
    if (F.isTouchingBody(wall)){
      s.h_avatar.setDamping(900) ;
      fEE.x = random(-1.25,1.25) ;
      fEE.y = random(-1.25,1.25) ;
    }
    
    if (s.h_avatar.isTouchingBody(area1)) {
      
      float a = 0.0          ;
      float inc = TWO_PI/25.0;
      
        for (int i = 0; i < 100; i=i+4) {
          fEE.x = random((7*sin(a)),(-7*sin(a)));
          a = a + inc                           ;
        }
    }
   
    
    if (s.h_avatar.isTouchingBody(area3)) {
      
      fEE.x = r * sin(theta);
      fEE.y = r * cos(theta);
      
      theta = theta+theta_diff;
      
      if (theta == 360){
        theta = 0 ; 
      }
    }
    
    if (s.h_avatar.isTouchingBody(area5)) {
      
      t2 = millis() - lasttimecheck2;
        
      if (millis() > lasttimecheck2 + timeinterval2){
        lasttimecheck2 = millis()   ;
      }
      
      if ((t2 >= 0) && (t2 < 500)){
        
        fEE.x = 2*m * t2;
        fEE.y = 2*m * t2;
        
      } else {
        
        fEE.x = -m * t2;
        fEE.y = -m * t2;
        
      }
    }
    
    
    torques.set(widgetOne.set_device_torques(fEE.array()));
    widgetOne.device_write_torques();
    
    
    if (s.h_avatar.isTouchingBody(wall) && wall.isSensor()){
      s.h_avatar.setDamping(950) ;
      
    } else if (C.isTouchingBody(wall)){
      s.h_avatar.setDamping(950);
    
    } else if (s.h_avatar.isTouchingBody(wall) && var1.isSensor()){
      
      //int bs = 2;
      
      //for (int i = 0; i < bs; i++){
      
      //  bumps = new FCircle(0.5)                               ;
      //  bumps.setDensity(100)                                  ;
      //  bumps.setPosition(s.h_avatar.getX(), s.h_avatar.getY());
      //  bumps.setStatic(false)                                 ;
      //  bumps.setFill(255,0,0)                                 ;
      //  world.add(bumps)                                       ;
      //} 
      
      t1 = millis() - lasttimecheck1;
      
      if (millis() > lasttimecheck1 + timeinterval1){
        lasttimecheck1 = millis() ;
      
        bumps = new FCircle(0.5)  ;
        bumps.setPosition(s.h_avatar.getX(), s.h_avatar.getY()-0.2);
        bumps.setFill(100,100,100);
        bumps.setDensity(100)     ;
        bumps.setNoStroke()       ;
        bumps.setSensor(false)    ;
        bumps.setStatic(false)    ;
        world.add(bumps)          ;
      }
      
    } else if (s.h_avatar.isTouchingBody(area2)) {
      
        t = millis() - lasttimecheck;
        
        if (millis() > lasttimecheck + timeinterval){
          lasttimecheck = millis()  ;
        }
      
        if ((t >= 400) && (t < 500)){
          s.h_avatar.setDamping(random(975,995)) ;
          //s.h_avatar.setVelocity(random(80,100),random(-80,-100)) ;
        } else {
          s.h_avatar.setDamping(500) ;
        }
    
    } else if (s.h_avatar.isTouchingBody(area4)) {
      
      t1 = millis() - lasttimecheck1 ;
      
      if (millis() > lasttimecheck1 + timeinterval1){
        lasttimecheck1 = millis() ;
        
        bumps = new FCircle(1)    ;
        bumps.setPosition(s.h_avatar.getX(), s.h_avatar.getY()-0.2);
        bumps.setNoFill()         ;
        bumps.setDensity(100)     ;
        bumps.setStroke(0,0,0,10) ;
        bumps.setSensor(false)    ;
        bumps.setStatic(false)    ;
        world.add(bumps)          ;
      }
     
     if((bumps.isTouchingBody(area1)) || (bumps.isTouchingBody(area2)) || (bumps.isTouchingBody(area3)) || (bumps.isTouchingBody(area5))) {
      world.remove(bumps);
     }
    
    } else {
      s.h_avatar.setDamping(500);
      lasttimecheck = millis()  ;
    }
    
    //println(s.h_avatar.getTouching());

    world.step(1.0f/1000.0f);
    renderingForce = false  ;
    }
}


/* end simulation section **********************************************************************************************/


/* helper functions section, place helper functions here ***************************************************************/


/* end helper functions section ****************************************************************************************/
