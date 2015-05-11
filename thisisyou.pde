/* --------------------------------------------------------------------------
 * This is You - a DMD Graduate Project 
 * Users control colour using left and right hands
 * Sounds are triggered in SuperCollider with OSC
 * --------------------------------------------------------------------------
 * Tom Tutaev
 * 13/06/2015 
 * --------------------------------------------------------------------------
 */

// import libraries 
import SimpleOpenNI.*;
import java.util.*;
import oscP5.*;
import netP5.*;

// establish Kinect, scene and OSC controls  
OscP5 oscP5;
NetAddress myRemoteLocation;
SimpleOpenNI kinect;
SimpleOpenNI context;

/* Pixelated image settings - adapted from http://www.openprocessing.org/sketch/186336 */
int blob_array[];
int userCurID;
int cont_length = 640*480;
PVector com = new PVector();                                  
PVector com2d = new PVector(); 
boolean tracking = false;
PImage backgroundImage;
PImage resultImage;
int userID; int[] userMap;
int framerate = 0;
int counter;
int spacing = 10;
int pixelSize = 20;

void setup(){
 // set screen size    
 size(1280, 800);
 // set color mode    
 colorMode(HSB, 100);

 // display this message if camera is not connected    
  kinect = new SimpleOpenNI(this);
  if(kinect.isInit() == false){
     println("Can't init SimpleOpenNI, maybe the camera is not connected!");
     exit();
     return; 
  }
  
   // mirror is by default enabled
  kinect.setMirror(true);
  
  // enables depth tracking for pixelated visualisation
  kinect.enableDepth();
  
  // enables colour tracking for pixelated visualisation
   kinect.enableRGB();
  
  // enables skeleton tracking 
  kinect.enableUser();
  
  // create a new 'context' or scene for skeleton tracking
  context = new SimpleOpenNI(this);
  
  // enable depth tracking for skeleton 
  context.enableDepth();

  // mirror is by default enabled
  context.setMirror(true);
  
  // enable skeleton generation for all joints
  context.enableUser();

  // convert output from Kinect 
  resultImage = new PImage(640, 480, HSB);

  blob_array = new int[cont_length];
   
  // Fast frame rate and improve quality of image 
  frameRate(6000);

  smooth();

  // start oscP5 and set the remote location to be the localhost on port 57120
  oscP5 = new OscP5(this,1200);
  myRemoteLocation = new NetAddress("127.0.0.1",57120);
   
}

// start full screen
 boolean sketchFullScreen() {
     return true ;
 }

void draw(){ 
/* Skeleton tracking settings - adapted from http://learning.codasign.com/index.php?title=Skeleton_Tracking_with_the_Kinect */
  
  // update the camera
  context.update();
  
 // get the depth array from the Kinect
  int[] depthValues = kinect.depthMap();
  
  // for all users from 1 to 10
  int i;
  for (i=1; i<=10; i++) 
  {
    // check if the skeleton is being tracked
    if(context.isTrackingSkeleton(i))
    {
   
   //draw the skeleton
   drawSkeleton(i); 
     float  ampstate = 1;
   sendOSCMessage("/amp/", new float[] {ampstate});
    }
  }
}

// draw the skeleton with the selected joints and send OSC hand messages to SuperCollider
void drawSkeleton(int userId)
{
  // map left hand position 
  PVector leftHand = new PVector();
  context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_LEFT_HAND, leftHand);
  float lhx = leftHand.x;
  float lhy = leftHand.y;
  float lhz = leftHand.z;

  // constrain left hand position to Kinect parameters 
  lhx = constrain(map(lhx, -600, 600, 0, 1), 0, 1);
  lhy = constrain(map(lhy, -600, 600, 0, 1), 0, 1);
  lhz = constrain(map(lhz, 1000, 1600, 0, 1), 0, 1); 
  //println(lhx, lhy, lhz);
  
  // send left hand position to SuperColllider to alter sound 
  sendOSCMessage("/lefthand/", new float[]{lhx, lhy, lhz});
    
   // map right hand position 
  PVector rightHand = new PVector();
  context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_RIGHT_HAND, rightHand);
  float rhx = rightHand.x;
  float rhy = rightHand.y;
  float rhz = rightHand.z;
  
  // constrain right hand position to Kinect parameters 
  rhx = constrain(map(rhx, -600, 600, 0, 1), 0, 1);
  rhy = constrain(map(rhy, -600, 600, 0, 1), 0, 1);
  rhz = constrain(map(rhz, 1000, 1600, 0, 1), 0, 1); 
  //println(rhx, rhy, rhz);
 
  // send right hand position to SuperColllider to alter sound 
  sendOSCMessage("/righthand/", new float[]{rhx, rhy, rhz});
  
  // update the camera
  kinect.update();
  
/* Pixelated image setup - adapted from http://www.openprocessing.org/sketch/186336 */
  
  // update the camera
  kinect.update();
  
  smooth();

 // set up Kinect depth
  int[] depthValues = kinect.depthMap();
  
   // meassure the number of users
  int[] userMap =null;
  int userCount = kinect.getNumberOfUsers();
  if (userCount > 0) {
    userMap = kinect.userMap();
  }
  
  // display users
  loadPixels();
  if (counter >= framerate){
    for (int y=0; y<kinect.depthHeight(); y+=spacing) {
      for (int x=0; x<kinect.depthWidth(); x+=spacing) {
        int index = x + y * kinect.depthWidth();
        if (userMap != null && userMap[index] > 0) {
          userCurID = userMap[index];
          blob_array[index] = 250;
                   
         // user's fill colour controlled by rightHand position         
         fill(map((rightHand.x), 0, width, 100, 50), map((rightHand.y), 0, height, 100, 50), 250, 100);

         //ellipse settings
         ellipseMode(CENTER);
         noStroke();
         ellipse(2 * x, 2 * y,pixelSize,pixelSize);
        }
        else {
              blob_array[index]=0;
          }
       }
    }
    
    smooth();

    //background fill controlled by leftHand position
    fill(map(leftHand.y,0,height,50,100), map(leftHand.x,0,width,50,100),250,35);

    //border  
    rect(0,0,width,height);
  
    counter = 0;
  }    
    counter += 1; 
    
    smooth();

/* SimpleOpenNI Skeleton tracking settings - adapted from http://learning.codasign.com/index.php?title=Skeleton_Tracking_with_the_Kinect */

  // map skeleton limbs (hidden from view)  
  context.drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);
 
  context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);
 
  context.drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);
 
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
 
  context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_LEFT_HIP);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_HIP, SimpleOpenNI.SKEL_LEFT_KNEE);
  context.drawLimb(userId, SimpleOpenNI.SKEL_LEFT_KNEE, SimpleOpenNI.SKEL_LEFT_FOOT);
 
  context.drawLimb(userId, SimpleOpenNI.SKEL_TORSO, SimpleOpenNI.SKEL_RIGHT_HIP);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_HIP, SimpleOpenNI.SKEL_RIGHT_KNEE);
  context.drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_KNEE, SimpleOpenNI.SKEL_RIGHT_FOOT); 
}

// when a skeleton is registered 
void onNewUser(SimpleOpenNI curContext,int userId) {
  println("onNewUser - userId: " + userId);
  println("\tstart tracking skeleton");
  context.startTrackingSkeleton(userId);
  float  ampstate = 1;
  sendOSCMessage("/amp/", new float[] {ampstate});
}
 
// when a user leaves the field of view 
void onLostUser(int userId) {
  println("User Lost - userId: " + userId); 
    float  ampstate = 1;
    sendOSCMessage("/amp/", new float[] {ampstate});
}

// when calibration begins
void onStartCalibration(int userId)
{
  println("Beginning Calibration - userId: " + userId);
}
 
// when calibaration ends - successfully or unsucessfully 
void onEndCalibration(int userId, boolean successfull)
{
  println("Calibration of userId: " + userId + ", successfull: " + successfull);
  
  if (successfull) 
  { 
    println("  User calibrated !!!");
 
    // begin skeleton tracking
    context.startTrackingSkeleton(userId); 
  } 
  else 
  { 
    println("  Failed to calibrate user !!!");
  }
}

/* OSC Settings - adapted from http://learning.codasign.com/index.php?title=Sending_Kinect_Joint_Position_Data_Via_OSC */
void sendJointPosition(int userId)
{
 println("hello");
 
  PVector jointPos = new PVector();   // create a PVector to hold joint positions
 
  // get the joint position of the left hand
  context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_LEFT_HAND,jointPos);
 
   // create an osc message
  OscMessage leftarmMessage = new OscMessage("/leftarm");
 
 // send joint position of y axis by OSC
  leftarmMessage.add(jointPos.x);
  leftarmMessage.add(jointPos.y); 
  leftarmMessage.add(jointPos.z);
 
  // get the joint position of the right hand
  context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_RIGHT_HAND,jointPos);
 
   // create an osc message
  OscMessage rightarmMessage = new OscMessage("/rightarm");
 
 // send joint position of y axis by OSC
  rightarmMessage.add(jointPos.x);
  rightarmMessage.add(jointPos.y); 
  rightarmMessage.add(jointPos.z);
 
  // send the messages
  oscP5.send(rightarmMessage, myRemoteLocation);  
  oscP5.send(leftarmMessage, myRemoteLocation);  
}

//OSC message settings
void sendOSCMessage(String address, float[] values){
  OscMessage msg = new OscMessage(address);
  for (int v=0; v<values.length; v++)
  msg.add(values[v]);
  oscP5.send(msg, myRemoteLocation);
}

// when skeleton is registered 
void onNewUser(SimpleOpenNI curkinect, SimpleOpenNI curContext, int userId){
  println("onNewUser - userId: " + userId);
  println("\tstart tracking skeleton");
  tracking = true;
  println("tracking");
  curkinect.startTrackingSkeleton(userId);
}

void onVisibleUser(SimpleOpenNI curkinect, int userId){
  println("onVisibleUser - userId: " + userId);
}

// when skeleton is lost 
void onLostUser(SimpleOpenNI curkinect, int userId){
  println("onLostUser - userId: " + userId);
}



