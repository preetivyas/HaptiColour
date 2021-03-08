//public class LineTexture {
//  private float wallwidth; // wall width
//  private float spacing; // distance between walls
//  private float x; // x position of top left corner
//  private float y; // y position of top left corner
//  private float dim_x; //x dimension of texture box
//  private float dim_y; //y dimension of texture box
//  private float damp;  //dampening of each wall
//  private int code; //code: vertical line (1), horizontal line (2)

//  public LineTexture(float x, float y, float dim_x, float dim_y) {
//    this.x = x;
//    this.y = y;
//    this.dim_x = dim_x;
//    this.dim_y = dim_y;
//    this.t_wallList = new ArrayList<Wall>();
    
//  }

////setup code, 
//  //public void changeCode(int code) {
//  //  this.SetupWalls(this.spacing, this.wallwidth, this.damp, code);
//  //}

//  public void SetupWalls(float spacing, float wallwidth, float damp, int code) {
//    //TODO: can be added as separate function
//    if (code==1) { //vertical line
//      for (int i=0; i < (this.dim_x/spacing); i++) {
//        this.t_wallList.add(new Wall(wallwidth, this.dim_y, this.x+wallwidth/2+i*spacing, this.y+this.dim_y/2, 0x000000)); //width, height, x and y position
//      }
//    }

//    if (code==2) { //horizontal line
//      for (int i=0; i < (this.dim_y/spacing); i++) {
//        this.t_wallList.add(new Wall(this.dim_x, wallwidth, this.x+this.dim_x/2, this.y+wallwidth/2+i*spacing, 0x000000)); //width, height, x and y position
//      }
//    }
    
//    if (code==3) {  //criss cross lines
//      for (int i=0; i < (this.dim_y/spacing); i++) {
//        t_wallList.add(new Wall(this.dim_x, wallwidth, this.x+this.dim_x/2, this.y+wallwidth/2+i*spacing, 0x000000)); //width, height, x and y position
//      }
//      for (int i=0; i < (this.dim_x/spacing); i++) {
//        t_wallList.add(new Wall(wallwidth, this.dim_y, this.x+wallwidth/2+i*spacing, this.y+dim_y/2, 0x000000)); //width, height, x and y position
//      }
//    }
//  }

//  public float getW() {
//    return this.w; //width will be changed by slider or be x axis
//  }

//  public float getH() { //height will be changed by slider or be y axis
//    return this.y;
//  }

//  /*
// class Texture:
//   def __init__(w, d, x, y):
//   self.w = w
//   self.d = d
//   def main():
//   my_texture_1 = Texture(1, 2, 3, 4)
//   my_texture_2 = Texture(11, 12, 13, 14)
//   print(my_texture_1.d) = 2
//   */

//  public float getX() {
//    return this.x;
//  }

//  public float getY() {
//    return this.y;
//  }
//}
