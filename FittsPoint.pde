import java.awt.Robot;
import java.util.ArrayList;

// Constants
final int NUM_TARGETS = 30;
final int NUM_TRIALS = 10;
final int PRACTICE_TRIALS = 5;
final int SCREEN_WIDTH = 1920;
final int SCREEN_HEIGHT = 1080;
final int MIN_RADIUS = 50;
final int MAX_RADIUS = 150;

// Experiment phases
enum ExperimentPhase {
  INSTRUCTIONS, BEFORE_CONDITION, TRIAL, FINISHED
}

// Variables
ArrayList<Target> targets;
ArrayList<Condition> conditions;
Condition currentCondition;
int currentConditionIndex = 0;
int currentTrial = 0;
int targetIndex = -1;
PVector cursorPos;
PVector previousCursorPos; // Track previous cursor position for sticky targets
PShape artificialCursor;
Robot robot;
long trialStartTime;
ExperimentPhase phase = ExperimentPhase.INSTRUCTIONS;

// Sticky targets variables
float stickyStrength = 4.0f; // C:D ratio strength (e.g., 4:1)
boolean isSticky = false; // Whether sticky targets are active

// Setup the canvas and initialize variables
public void settings() {
  size(SCREEN_WIDTH, SCREEN_HEIGHT, P2D);
  fullScreen();
}

public void setup() {
  // Initialize the artificial cursor
  cursorPos = new PVector(width / 2, height / 2);
  previousCursorPos = new PVector(width / 2, height / 2); // Initialize previous position
  artificialCursor = createShape(ELLIPSE, 0, 0, 20, 20);
  artificialCursor.setFill(color(255, 255, 0)); // Yellow cursor
  
  // Initialize the Robot for cursor control
  try {
    robot = new Robot();
  } catch(Exception e) {
    e.printStackTrace();
  }
  
  // Generate non-overlapping targets
  targets = new ArrayList<Target>();
  for (int i = 0; i < NUM_TARGETS; i++) {
    boolean overlap;
    float x, y, radius;
    do {
      overlap = false;
      x = random(MAX_RADIUS, width - MAX_RADIUS);
      y = random(MAX_RADIUS, height - MAX_RADIUS);
      radius = random(MIN_RADIUS, MAX_RADIUS);
      
      // Check for overlaps with existing targets
      for (Target target : targets) {
        if (dist(x, y, target.x, target.y) < radius + target.radius) {
          overlap = true;
          break;
        }
      }
    } while(overlap);
    targets.add(new Target(x, y, radius));
  }
  
  // Initialize conditions
  conditions = new ArrayList<Condition>();
  conditions.add(new Condition("NormalPointing", "Regular", 0, 0, NUM_TRIALS));
  conditions.add(new Condition("StickyTargets", "STICKY", stickyStrength, 0, NUM_TRIALS));
  
  // Hide the real cursor
  noCursor();
}

// Draw the experiment based on the current phase
public void draw() {
  background(200);
  
  switch(phase) {
    case INSTRUCTIONS:
      displayInstructions();
      break;
    
    case BEFORE_CONDITION:
      displayConditionScreen();
      break;
    
    case TRIAL:
      displayTargets();
      displayArtificialCursor();
      break;
    
    case FINISHED:
      displayFinishedScreen();
      break;
  }
}

// Display the instructions screen
void displayInstructions() {
  fill(0);
  textSize(32);
  textAlign(CENTER, CENTER);
  text("Welcome to the experiment!\nClick to begin.", width / 2, height / 2);
}

// Display the condition screen
void displayConditionScreen() {
  fill(0);
  textSize(32);
  textAlign(CENTER, CENTER);
  text("Next condition: " + currentCondition.name + "\nClick to start.", width / 2, height / 2);
}

// Display the targets
void displayTargets() {
  for (Target target : targets) {
    target.display();
  }
}

// Display the artificial cursor
void displayArtificialCursor() {
  shape(artificialCursor, cursorPos.x - 10, cursorPos.y - 10);
  
  // Update the artificial cursor position based on mouse movement
  if (mouseX != cursorPos.x || mouseY != cursorPos.y) {
    PVector mouseDelta = new PVector(mouseX - previousCursorPos.x, mouseY - previousCursorPos.y);
    
    // Apply sticky targets technique if active
    if (currentCondition.type.equals("STICKY")) {
      applyStickyTargets(mouseDelta);
    }
    
    // Update cursor position
    cursorPos.add(mouseDelta);
    previousCursorPos.set(mouseX, mouseY);
    
    // Move the real cursor to the artificial cursor position
    try {
      robot.mouseMove((int) cursorPos.x,(int) cursorPos.y);
    } catch(Exception e) {
      e.printStackTrace();
    }
  }
}

// Display the finished screen
void displayFinishedScreen() {
  fill(0);
  textSize(32);
  textAlign(CENTER, CENTER);
  text("Experiment complete. Thank you for participating.", width / 2, height / 2);
}

// Apply sticky targets technique
void applyStickyTargets(PVector mouseDelta) {
  for (Target target : targets) {
    // Calculate intersection length between the cursor path and the target
    float intersection = target.intersectionLength(previousCursorPos.x, previousCursorPos.y, cursorPos.x, cursorPos.y);
    
    if (intersection > 0) {
      // Adjust the mouse delta based on the sticky strength
      float fractionInside = intersection / mouseDelta.mag();
      mouseDelta.mult(1 + (stickyStrength - 1) * fractionInside);
    }
  }
}

// Handle mouse clicks
public void mousePressed() {
  switch(phase) {
    case INSTRUCTIONS:
      phase = ExperimentPhase.BEFORE_CONDITION;
      startNextCondition();
      break;
    
    case BEFORE_CONDITION:
      phase = ExperimentPhase.TRIAL;
      startNextTrial();
      break;
    
    case TRIAL:
      // Check if the click is on the target
      if (targets.get(targetIndex).isClicked(mouseX, mouseY)) {
        // Correct selection
        if (currentTrial >= PRACTICE_TRIALS) {
          float distance = dist(cursorPos.x, cursorPos.y, targets.get(targetIndex).x, targets.get(targetIndex).y);
          float fittsID = calculateFittsID(distance, targets.get(targetIndex).radius * 2);
          currentCondition.recordTrial(true, millis() - trialStartTime, fittsID, currentCondition.getErrorCount());
        }
      } else {
        // Incorrect selection (error)
        currentCondition.incrementErrorCount();
        if (currentTrial >= PRACTICE_TRIALS) {
          // Record the error trial
          float distance = dist(cursorPos.x, cursorPos.y, targets.get(targetIndex).x, targets.get(targetIndex).y);
          float fittsID = calculateFittsID(distance, targets.get(targetIndex).radius * 2);
          currentCondition.recordTrial(false, millis() - trialStartTime, fittsID, currentCondition.getErrorCount());
        }
      }
      
      // Move to the next trial
      currentTrial++;
      if (currentTrial < currentCondition.totalTrials) {
        startNextTrial();
      } else {
        phase = ExperimentPhase.BEFORE_CONDITION; // Move to next condition
        startNextCondition();
      }
      break;
  
    case FINISHED:
      saveResultsToFile();
      break;
  }
}

// Start the next condition
void startNextCondition() {
  if (currentConditionIndex < conditions.size()) {
    currentCondition = conditions.get(currentConditionIndex);
    currentConditionIndex++;
    currentTrial = 0;
    phase = ExperimentPhase.BEFORE_CONDITION;
  } else {
    phase = ExperimentPhase.FINISHED; // If no conditions left, end the experiment
  }
}

// Start the next trial
void startNextTrial() {
  // Select a random target
  targetIndex = (int) random(targets.size());
  targets.get(targetIndex).setColor(color(0, 255, 0)); // Green target
  
  // Reset other targets to white
  for (int i = 0; i < targets.size(); i++) {
    if (i != targetIndex) {
      targets.get(i).setColor(color(255));
    }
  }
  
  // Track trial start time
  trialStartTime = millis();
}

// Calculate Fitts' ID
float calculateFittsID(float distance, float width) {
  return(float)(log(distance / width + 1) / log(2)); // Use log base 2
}

void saveResultsToFile() {
  try {
    String fileName = "data.csv";
    PrintWriter writer = createWriter(fileName);
    
    writer.println("ConditionName,TrialNumber,FittsID,CompletionTime,Errors");
    
    //Print results to the console and write them to the file
    println("ConditionName,TrialNumber,FittsID,CompletionTime,Errors");
    for (Condition condition : conditions) {
      String result = condition.getResults();
      println(result);
      writer.println(result);
    }
    
    writer.flush();
    writer.close();
    println("Results have been saved to " + fileName);
  } catch(Exception e) {
    println("An error occurred while saving results: " + e.getMessage());
    e.printStackTrace();
  }
}
