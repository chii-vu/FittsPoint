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
PVector cursorPos; // real cursor position
PShape artificialCursor;
Robot robot;
long trialStartTime;
ExperimentPhase phase = ExperimentPhase.INSTRUCTIONS;

// Setup the canvas and initialize variables
public void settings() {
  size(SCREEN_WIDTH, SCREEN_HEIGHT, P2D);
  fullScreen();
}

public void setup() {
  // Initialize the artificial cursor
  cursorPos = new PVector(width / 2, height / 2);
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
  conditions.add(new Condition("Sticky-Zero", "Regular", 0, NUM_TRIALS));
  conditions.add(new Condition("Sticky-Low", "STICKY", 2.0, NUM_TRIALS)); // Low sticky
  conditions.add(new Condition("Sticky-Medium", "STICKY", 10.0, NUM_TRIALS)); // Medium sticky
  conditions.add(new Condition("Sticky-High", "STICKY", 30.0, NUM_TRIALS)); // High sticky

  conditions.add(new Condition("Gravity-Zero", "GRAVITY", 0.0, NUM_TRIALS)); // Gravity zero
  conditions.add(new Condition("Gravity-Low", "GRAVITY", 25.0, NUM_TRIALS)); // Low gravity
  conditions.add(new Condition("Gravity-Medium", "GRAVITY", 50.0, NUM_TRIALS)); // Medium gravity
  conditions.add(new Condition("Gravity-High", "GRAVITY", 75.0, NUM_TRIALS)); // High gravity

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
  text("Next condition: " + currentCondition.getName() + "\nClick to start.", width / 2, height / 2);
}

// Display the targets
void displayTargets() {
  for (Target target : targets) {
    target.display();
  }
}

void displayArtificialCursor() {
  shape(artificialCursor, cursorPos.x - 10, cursorPos.y - 10);
  
  // Calculate the delta vector for cursor movement
  PVector delta = new PVector(mouseX - cursorPos.x, mouseY - cursorPos.y);

  // Apply behaviour based on the current condition
  if (currentCondition.getType().equals("STICKY")) {
    applyStickyBehaviour(delta);
  } else if (currentCondition.getType().equals("GRAVITY")) {
    applyGravityBehaviour(delta);
  }
  
  // Update artificial cursor position with the adjusted delta vector
  cursorPos.add(delta);
  
  // Move the real cursor to the artificial cursor position
  robot.mouseMove((int)cursorPos.x, (int)cursorPos.y);
}

// Apply sticky behaviour
void applyStickyBehaviour(PVector delta) {
  for (Target target : targets) {
    // Use provided function to calculate intersection length
    float intersectionLength = target.intersectionLength(cursorPos.x, cursorPos.y, mouseX, mouseY);
    if (intersectionLength > 0) {
      // Calculate the fraction of the delta vector that is inside the target
      float fractionInside = intersectionLength / delta.mag();
      float stickyStrength = currentCondition.getStrength();

      // Scale the delta vector based on the fraction inside and sticky strength
      delta.setMag(delta.mag() * (1 - fractionInside + fractionInside / stickyStrength));
    }
  }
}

// Apply gravity behaviour
void applyGravityBehaviour(PVector delta) {
  PVector gravityEffect = new PVector(0, 0);
  float distanceThreshold = 500;

  // Calculate the cursor's next position
  float cursorX = cursorPos.x + delta.x;
  float cursorY = cursorPos.y + delta.y;

  for (Target target : targets) {
    // Calculate distance from cursor to the center of the target
    float distance = dist(cursorX, cursorY, target.x, target.y);
    
    // Calculate distance relative to the edge of the target
    float distanceFromEdge = distance - target.radius;
    
    // Ignore targets too far away
    if (distanceFromEdge > distanceThreshold) continue;

    // Compute direction from cursor to center of target
    PVector gravityVector = new PVector(target.x - cursorX, target.y - cursorY);
    gravityVector.normalize();

    // Gravity intensity based on how close the cursor is
    float gravityStrength;

    if (distanceFromEdge > 0) {
      // Outside the target: Scale pull based on proximity to edge
      gravityStrength = currentCondition.getStrength() * (1 - (distanceFromEdge / distanceThreshold));
    } else {
      // Inside the target: Stronger pull to the center
      gravityStrength = currentCondition.getStrength() * (1 + abs(distanceFromEdge) / target.radius);
    }

    // Apply gravity force
    gravityVector.mult(gravityStrength);
    gravityEffect.add(gravityVector);
  }
  
  // Apply cumulative gravity effect to the delta vector
  delta.add(gravityEffect);
}

// Display the finished screen
void displayFinishedScreen() {
  fill(0);
  textSize(32);
  textAlign(CENTER, CENTER);
  text("Experiment complete. Thank you for participating.", width / 2, height / 2);
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
      if (targets.get(targetIndex).isClicked(cursorPos.x, cursorPos.y)) {
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
      currentCondition.resetErrorCount();
      currentTrial++;
      if (currentTrial < currentCondition.getTotalTrials()) {
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
  return(float)(log(distance / width + 1) / log(2));
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
