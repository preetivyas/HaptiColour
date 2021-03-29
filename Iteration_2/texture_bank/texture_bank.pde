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


int[][] colors =  { { 0, 0, 255, 100 }, { 0, 255, 0, 100 }, {255, 0, 0, 100}, {255, 205, 0, 100}, {255, 105, 180, 100}, 
  {128, 0, 128, 100}, {139, 69, 19, 100}, {0, 0, 0, 100} };

FBox[] area = new FBox[8];
FBox[][] tgrid =  new FBox[100][200];
FBox[][] vgrid =  new FBox[100][200];
FBox[][] bgrid =  new FBox[100][200];

int tjloop, tiloop, viloop, vjloop, biloop, bjloop;

Slider damper;
int damp = 800;

/* setup section *******************************************************************************************************/
void setup() {
  /* put setup code here, run once: */

  /* screen size definition */
  size(1200, 600);

  /* setup UI elements */
  smooth();
  cp5 = new ControlP5(this);

  cp5.addButton("Wallitself")
    .setValue(0)
    .setPosition(0, 0)
    .setSize(0, 0)
    .setColorValue((255))
    ;

  cp5.addButton("TranslucentCircle")
    .setValue(0)
    .setPosition(0, 0)
    .setSize(0, 0)
    .setColorValue(0)
    ;

  cp5.addButton("BumpyWall")
    .setValue(0)
    .setPosition(0, 0)
    .setSize(0, 0)
    .setColorValue(0)
    ;

  cp5.addButton("Forces")
    .setValue(0)
    .setPosition(0, 0)
    .setSize(0, 0)
    .setColorValue(0)
    ;

  cp5.addButton("RESET")
    .setValue(0)
    .setPosition(0, 0)
    .setSize(0, 0)
    .setColorValue(0)
    ;

  noStroke()     ;

  ////for testing only
  //damper = cp5.addSlider("damp")
  //  .setPosition(100, 605)
  //  .setSize(200, 30)
  //  .setRange(100, 1000) // values can range from big to small as well
  //  .setValue(500)
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
  widgetOne.add_actuator(2, CW, 1) ;
  widgetOne.add_encoder(1, CCW, 241, 10752, 2);
  widgetOne.add_encoder(2, CW, -61, 10752, 1) ;
  widgetOne.device_set_parameters();

  /* 2D physics scaling and world creation */
  hAPI_Fisica.init(this); 
  hAPI_Fisica.setScale(pixelsPerCentimeter); 
  world               = new FWorld();


  for (int i = 0; i<8; i++) {
    area[i]  = new FBox(6.5, 6.5)           ;
    area[i].setPosition((i%4+1)*worldWidth/5-1.5+(i%4)*1, (i/4*2+1)*worldHeight/4+0.3-(i/4*.6));
    area[i].setDensity(0)                                   ;
    area[i].setSensor(true)                                 ;
    area[i].setStatic(true)                                 ;
    area[i].setNoStroke()                                   ;
    area[i].setFill(colors[i][0], colors[i][1], colors[i][2], colors[i][3]);
    world.add(area[i])                                      ;
  }

  float space = 1.2;
  float wall_h = 1.3;
  float wall_w = 0.1;

  bjloop = int(6.5/2);
  biloop = int(6.5/space);

  for (int j = 0; j<bjloop; j++) {
    for (int i = 0; i<biloop; i++) {
      bgrid[j][i] = new FBox(wall_w+0.9, wall_h+.5);
      bgrid[j][i].setPosition((i+1)*space+8, (j+0.8)*2+7.5);
      bgrid[j][i].setFill(0,0,0,0);
      bgrid[j][i].setDensity(100); 
      bgrid[j][i].setSensor(true);
      bgrid[j][i].setNoStroke()  ;
      bgrid[j][i].setStatic(true);
      world.add(bgrid[j][i]);
    }
  }


  tjloop = int(6.5/2);
  tiloop = int(6.5/space);

  for (int j = 0; j<tjloop; j++) {
    for (int i = 0; i<tiloop; i++) {
      tgrid[j][i] = new FBox(wall_w, wall_h);
      tgrid[j][i].setPosition((i+1)*space+15, (j+0.8)*2+7.5);
      tgrid[j][i].setFill(0,0,0,0);
      tgrid[j][i].setDensity(100); 
      tgrid[j][i].setSensor(true);
      tgrid[j][i].setNoStroke()  ;
      tgrid[j][i].setStatic(true);
      world.add(tgrid[j][i]);
    }
  }

  
  vjloop = int(6.5/2);
  viloop = int(6.5/space);

  for (int j = 0; j<vjloop; j++) {
    for (int i = 0; i<viloop; i++) {
      vgrid[j][i] = new FBox(wall_h, wall_w);
      vgrid[j][i].setPosition((j+0.8)*2+22, (i+1)*space+7.5);
      vgrid[j][i].setFill(0,0,0,0);
      vgrid[j][i].setDensity(100); 
      vgrid[j][i].setSensor(true);
      vgrid[j][i].setNoStroke()  ;
      vgrid[j][i].setStatic(true);
      world.add(vgrid[j][i]);
    }
  }




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
  s.h_avatar.setFill(255, 0, 0)     ;
  s.init(world, edgeTopLeftX+worldWidth/2, edgeTopLeftY+2);
  /* If you are developing on a Mac users must update the path below 
   * from "../img/Haply_avatar.png" to "./img/Haply_avatar.png" 
   */
  //haplyAvatar = loadImage("../img/Haply_avatar.png"); 
  //haplyAvatar.resize((int)(hAPI_Fisica.worldToScreen(1)), (int)(hAPI_Fisica.worldToScreen(1)));
  //s.h_avatar.attachImage(haplyAvatar);

  /* world conditions setup */
  world.setGravity((0.0), (1000.0)); //1000 cm/(s^2) //PV is 100
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
  C.setStroke(0, 0, 0)  ;
  C.setPosition(3, 3)  ;
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
  F.setStroke(0, 0, 0, 30);
  F.setPosition(3, 3)   ;
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
void draw() {
  /* put graphical code here, runs repeatedly at defined framerate in setup, else default at 60fps: */


  if (renderingForce == false) {
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
class SimulationThread implements Runnable {

  public void run() {
    /* put haptic simulation code here, runs repeatedly at 1kHz as defined in setup */

    t = 0  ;
    t1 = 0 ;
    t2 = 0 ;

    renderingForce = true;

    if (haplyBoard.data_available()) {
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



    if (F.isTouchingBody(wall)) {
      s.h_avatar.setDamping(900) ;
      fEE.x = random(-1.25, 1.25) ;
      fEE.y = random(-1.25, 1.25) ;
    }

    if (s.h_avatar.isTouchingBody(area[0])) {

      float a = 0.0          ;
      float inc = TWO_PI/25.0;

      for (int i = 0; i < 100; i=i+4) {
        fEE.x = random((7*sin(a)), (-7*sin(a)));
        a = a + inc                           ;
      }
    }


    if (s.h_avatar.isTouchingBody(area[2])) {

      fEE.x = r * sin(theta);
      fEE.y = r * cos(theta);

      theta = theta+theta_diff;

      if (theta == 360) {
        theta = 0 ;
      }
    }

    if (s.h_avatar.isTouchingBody(area[4])) {

      t2 = millis() - lasttimecheck2;

      if (millis() > lasttimecheck2 + timeinterval2) {
        lasttimecheck2 = millis()   ;
      }

      if ((t2 >= 0) && (t2 < 500)) {

        fEE.x = 2*m * t2;
        fEE.y = 2*m * t2;
      } else {

        fEE.x = -m * t2;
        fEE.y = -m * t2;
      }
    }


    torques.set(widgetOne.set_device_torques(fEE.array()));
    widgetOne.device_write_torques();


    if (s.h_avatar.isTouchingBody(area[1])) {

      t = millis() - lasttimecheck;

      if (millis() > lasttimecheck + timeinterval) {
        lasttimecheck = millis()  ;
      }

      if ((t >= 400) && (t < 500)) {
        s.h_avatar.setDamping(random(975, 995)) ;
        //s.h_avatar.setVelocity(random(80,100),random(-80,-100)) ;
      } else {
        s.h_avatar.setDamping(500) ;
      }
    } else if (s.h_avatar.isTouchingBody(area[3])) {

      t1 = millis() - lasttimecheck1 ;

      if (millis() > lasttimecheck1 + timeinterval1) {
        lasttimecheck1 = millis() ;

        bumps = new FCircle(1)    ;
        bumps.setPosition(s.h_avatar.getX(), s.h_avatar.getY()-0.2);
        bumps.setNoFill()         ;
        bumps.setDensity(100)     ;
        bumps.setStroke(0, 0, 0, 10) ;
        bumps.setSensor(false)    ;
        bumps.setStatic(false)    ;
        world.add(bumps)          ;
      }

      if ((bumps.isTouchingBody(area[0])) || (bumps.isTouchingBody(area[1])) || (bumps.isTouchingBody(area[2])) || (bumps.isTouchingBody(area[3]))) {
        world.remove(bumps);
      }
    } else {
      s.h_avatar.setDamping(500);
      lasttimecheck = millis()  ;
    }

    for (int j=0; j<tjloop; j++) {
      for (int i=0; i<tiloop; i++) {
        if (s.h_avatar.isTouchingBody(tgrid[i][j])) {
          s.h_avatar.setDamping(800);
        }
      }
    }

    for (int j=0; j<bjloop; j++) {
      for (int i=0; i<biloop; i++) {
        if (s.h_avatar.isTouchingBody(bgrid[i][j])) {
          s.h_avatar.setDamping(800);
        }
      }
    }

    for (int j=0; j<vjloop; j++) {
      for (int i=0; i<viloop; i++) {
        if (s.h_avatar.isTouchingBody(vgrid[i][j])) {
          s.h_avatar.setDamping(800);
        }
      }
    }


    //println(s.h_avatar.getTouching());

    world.step(1.0f/1000.0f);
    renderingForce = false  ;
  }
}


/* end simulation section **********************************************************************************************/


/* helper functions section, place helper functions here ***************************************************************/


/* end helper functions section ****************************************************************************************/
