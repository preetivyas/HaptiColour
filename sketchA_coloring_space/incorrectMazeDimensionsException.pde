class incorrectMazeDimensionsException extends Exception{
    incorrectMazeDimensionsException(float expectedW, float expectedH, int actualW, int actualH){
        super("Incorrect maze dimensions! Expected maze of " 
              + expectedW + " width and "
              + expectedH + " height but received maze of "
              + actualW + " width and "
              + actualH + " height");
    }
}
