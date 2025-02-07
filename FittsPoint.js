let NUM_TARGETS = 30;
let NUM_TRIALS = 10;
let PRACTICE_TRIALS = 5;
let SCREEN_WIDTH = 1920;
let SCREEN_HEIGHT = 1080;
let MIN_RADIUS = 50;
let MAX_RADIUS = 150;

let targets = [];
let conditions = [];
let currentCondition;
let currentConditionIndex = 0;
let currentTrial = 0;
let targetIndex = -1;
let cursorPos;
let artificialCursor;
let trialStartTime;
let phase = "INSTRUCTIONS";

let stickyStrength = 100.0;
let isSticky = false;

function setup() {
    createCanvas(SCREEN_WIDTH, SCREEN_HEIGHT);
    cursorPos = createVector(width / 2, height / 2);
    previousCursorPos = createVector(width / 2, height / 2);
    
    // Create an off-screen graphics buffer for the artificial cursor
    artificialCursor = createGraphics(20, 20);
    artificialCursor.fill(255, 255, 0); // Yellow color
    artificialCursor.ellipse(10, 10, 20, 20); // Draw the ellipse in the center

    // Initialize targets
    for (let i = 0; i < NUM_TARGETS; i++) {
        let overlap;
        let x, y, radius;
        do {
            overlap = false;
            x = random(MAX_RADIUS, width - MAX_RADIUS);
            y = random(MAX_RADIUS, height - MAX_RADIUS);
            radius = random(MIN_RADIUS, MAX_RADIUS);

            for (let target of targets) {
                if (dist(x, y, target.x, target.y) < radius + target.radius) {
                    overlap = true;
                    break;
                }
            }
        } while (overlap);
        targets.push(new Target(x, y, radius));
    }

    conditions.push(new Condition("StickyTargets", "STICKY", stickyStrength, 0, NUM_TRIALS));
    noCursor();
}

function draw() {
    background(200);

    switch (phase) {
        case "INSTRUCTIONS":
            displayInstructions();
            break;
        case "BEFORE_CONDITION":
            displayConditionScreen();
            break;
        case "TRIAL":
            displayTargets();
            displayArtificialCursor();
            break;
        case "FINISHED":
            displayFinishedScreen();
            break;
    }
}

function displayArtificialCursor() {
    image(artificialCursor, cursorPos.x - 10, cursorPos.y - 10);

    let mouseDelta = createVector(mouseX - previousCursorPos.x, mouseY - previousCursorPos.y);

    if (currentCondition.type === "STICKY") {
        applyStickyTargets(mouseDelta);
    }

    cursorPos.add(mouseDelta);
    previousCursorPos.set(mouseX, mouseY);
}

function applyStickyTargets(mouseDelta) {
    for (let target of targets) {
        let intersection = target.intersectionLength(previousCursorPos.x, previousCursorPos.y, cursorPos.x, cursorPos.y);
        // if (intersection > 0) {
            console.log("Intersection detected with target at:", target.x, target.y);
            let intersectionPoint = createVector(previousCursorPos.x + intersection * mouseDelta.x, previousCursorPos.y + intersection * mouseDelta.y);
            let targetCenter = createVector(target.x, target.y);
            let newCursorPos = p5.Vector.lerp(intersectionPoint, targetCenter, 1.0 / stickyStrength);
            mouseDelta.set(newCursorPos.x - cursorPos.x, newCursorPos.y - cursorPos.y);
            break;
        // }
    }
}

function displayInstructions() {
  fill(0);
  textSize(32);
  textAlign(CENTER, CENTER);
  text("Welcome to the experiment!\nClick to begin.", width / 2, height / 2);
}

function displayConditionScreen() {
  fill(0);
  textSize(32);
  textAlign(CENTER, CENTER);
  text("Next condition: " + currentCondition.name + "\nClick to start.", width / 2, height / 2);
}

function displayTargets() {
  for (let target of targets) {
    target.display();
  }
}

function displayFinishedScreen() {
  fill(0);
  textSize(32);
  textAlign(CENTER, CENTER);
  text("Experiment complete. Thank you for participating.", width / 2, height / 2);
}

function mousePressed() {
  switch (phase) {
    case "INSTRUCTIONS":
      phase = "BEFORE_CONDITION";
      startNextCondition();
      break;
    case "BEFORE_CONDITION":
      phase = "TRIAL";
      startNextTrial();
      break;
    case "TRIAL":
      if (targets[targetIndex].isClicked(mouseX, mouseY)) {
        if (currentTrial >= PRACTICE_TRIALS) {
          let distance = dist(cursorPos.x, cursorPos.y, targets[targetIndex].x, targets[targetIndex].y);
          let fittsID = calculateFittsID(distance, targets[targetIndex].radius * 2);
          currentCondition.recordTrial(true, millis() - trialStartTime, fittsID, currentCondition.getErrorCount());
        }
      } else {
        currentCondition.incrementErrorCount();
        if (currentTrial >= PRACTICE_TRIALS) {
          let distance = dist(cursorPos.x, cursorPos.y, targets[targetIndex].x, targets[targetIndex].y);
          let fittsID = calculateFittsID(distance, targets[targetIndex].radius * 2);
          currentCondition.recordTrial(false, millis() - trialStartTime, fittsID, currentCondition.getErrorCount());
        }
      }

      currentTrial++;
      if (currentTrial < currentCondition.totalTrials) {
        startNextTrial();
      } else {
        phase = "BEFORE_CONDITION";
        startNextCondition();
      }
      break;
    case "FINISHED":
      saveResultsToFile();
      break;
  }
}

function startNextCondition() {
  if (currentConditionIndex < conditions.length) {
    currentCondition = conditions[currentConditionIndex];
    currentConditionIndex++;
    currentTrial = 0;
    phase = "BEFORE_CONDITION";
  } else {
    phase = "FINISHED";
  }
}

function startNextTrial() {
  targetIndex = int(random(targets.length));
  targets[targetIndex].setColor(color(0, 255, 0));

  for (let i = 0; i < targets.length; i++) {
    if (i != targetIndex) {
      targets[i].setColor(color(255));
    }
  }

  trialStartTime = millis();
}

function calculateFittsID(distance, width) {
  return log(distance / width + 1) / log(2);
}

function saveResultsToFile() {
  // Implement saving results to file
}

class Target {
    constructor(x, y, radius) {
        this.x = x;
        this.y = y;
        this.radius = radius;
        this.color = color(255);
    }

    display() {
        fill(this.color);
        ellipse(this.x, this.y, this.radius * 2, this.radius * 2);
    }

    setColor(c) {
        this.color = c;
    }

    isClicked(px, py) {
        return dist(px, py, this.x, this.y) < this.radius;
    }

    intersectionLength(x1, y1, x2, y2) {
        let dx = x2 - x1;
        let dy = y2 - y1;
        let fx = x1 - this.x;
        let fy = y1 - this.y;

        let a = dx * dx + dy * dy;
        let b = 2 * (fx * dx + fy * dy);
        let c = (fx * fx + fy * fy) - this.radius * this.radius;

        let discriminant = b * b - 4 * a * c;
        if (discriminant >= 0) {
            discriminant = sqrt(discriminant);
            let t1 = (-b - discriminant) / (2 * a);
            let t2 = (-b + discriminant) / (2 * a);

            if (t1 >= 0 && t1 <= 1) {
                return t1;
            }
            if (t2 >= 0 && t2 <= 1) {
                return t2;
            }
        }
        return -1;
    }
}

class Condition {
    constructor(name, type, amplitude, width, totalTrials) {
        this.name = name;
        this.type = type;
        this.amplitude = amplitude;
        this.width = width;
        this.totalTrials = totalTrials;
        this.errorCount = 0;
        this.results = [];
    }

    recordTrial(success, completionTime, fittsID, errors) {
        let result = `${this.name},${this.results.length + 1},${fittsID},${completionTime},${errors}`;
        this.results.push(result);
        this.errorCount = 0; // Reset error count after recording trial
    }

    incrementErrorCount() {
        this.errorCount++;
    }

    getErrorCount() {
        return this.errorCount;
    }

    getResults() {
        return this.results.join("\n");
    }
}