# Analysis of Target Assistance Techniques in Pointing Tasks

This project investigates the effectiveness of various target assistance techniques in pointing tasks, with a focus on two techniques: Sticky Targets and Target Gravity. The experimental setup and data analysis were designed to evaluate these techniques through controlled trials, measuring their impact on pointing accuracy and completion time.

## File Structure
- **Data Files**: Stored in the `data/` directory.  
  - `data/increasing` and `data/decreasing`: Contain individual data files for the two experimental orders. These are split for easier plotting.
- **Plot Scripts**: Located in the `plots/` directory.  
  - `plots/increasing` and `plots/decreasing`: Contain individual plots for each condition.
  - Other plots in `plots/` are included in the report.
- **Report**: The final report summarizing the experiment is located in the root directory as `report.pdf`.

## Part 1: Fitts’ Law Targeting with Artificial Cursor
- A fullscreen canvas displays 30 randomly-placed, non-overlapping circular targets with radii ranging from 50 to 150 pixels.
- An artificial cursor is implemented using `java.awt.Robot`, and the real cursor is hidden during the experiment.
- Performance data is recorded for each trial, including:
  - Completion time
  - Errors
  - Fitts’ Index of Difficulty (ID)
- The Fitts’ ID is calculated using the formula provided in the class notes.
- Instructions are displayed before each condition, and trials begin immediately after the previous one completes.

## Part 2: Sticky Targets Technique
- The Sticky Targets technique is fully implemented.
- The C:D (cursor to target) ratio of the artificial cursor is adjusted when crossing a target, based on the strength level (low, medium, high).
- A line-circle intersection algorithm ensures accurate detection of cursor crossings, addressing any sampling issues.
- The delta vector (`dx`, `dy`) is adjusted before updating the artificial cursor’s position.

## Part 3: Target Gravity Technique
- The Target Gravity technique is fully implemented.
- For each mouse movement, gravity vectors are calculated for targets within a 500-pixel threshold.
- These vectors are scaled according to the strength level (low, medium, high) and added to the artificial cursor’s movement.

## Part 4: Experimental Data and Report
- Data has been gathered for all conditions:
  - **Sticky Targets**: Zero, low, medium, and high strength.
  - **Target Gravity**: Zero, low, medium, and high strength.
  - Conditions were tested in both orders:
    - Sticky then Gravity (increasing strength)
    - Gravity then Sticky (decreasing strength)
- Charts are included showing the relationship between Fitts’ ID and completion time for each condition, with best-fit lines and R-squared values.
- A detailed report summarizes the goals, procedures, results, and discussion of the findings. This is located in the `report.pdf` file.

## Running the Experiment
To run the experiment:
1. If you just want to run the **FittsPoint** program:
   - Simply execute `FittsPoint` to start the experiment.
   - Results will be saved in the `data/` directory.
   
2. If you would like to generate the plots for the data:
   - First, activate a virtual environment:
     ```bash
     python -m venv venv
     source venv/bin/activate  # On Windows use `venv\Scripts\activate`
     ```
   - Install the required dependencies:
     ```bash
     pip install -r requirements.txt
     ```
   - Follow the plotting scripts located in the `plots/` directory to generate the desired plots for the different conditions.