/* A class to represent a game die */
public class Die extends Object {
 
  // store the current face of the die
  private int currentFace = 1;
  
  // store the size of the die
  private final int dieSize;
  
  /* A constructor to set the size of the die */
  public Die(int dieSize) {
    this.dieSize = dieSize;
  }
  
  /* a method to return the current face of the die */
  public int getCurrentFace() {
    return currentFace;
  }
  
  /* a method to set the current face of the die */
  public void setCurrentFace(int currentFace) {
    this.currentFace = currentFace;
  }
  
  /* a method to roll a die */
  public int roll() {
    int x = (int)(Math.random() * this.dieSize + 1);
    this.setCurrentFace(x);
    return x;
  }
}