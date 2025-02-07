import pandas as pd
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression

def plot_data(file_path, save_dir):
    # Load the data
    data = pd.read_csv(file_path)

    # Get the unique conditions
    conditions = data['ConditionName'].unique()

    # Create a plot for each condition
    for condition in conditions:
        condition_data = data[data['ConditionName'] == condition]
        
        # Extract the FittsID and CompletionTime
        X = condition_data['FittsID'].values.reshape(-1, 1)
        y = condition_data['CompletionTime'].values
        
        # Fit a linear regression model
        model = LinearRegression()
        model.fit(X, y)
        y_pred = model.predict(X)
        
        # Get regression parameters
        slope = model.coef_[0]
        intercept = model.intercept_
        r_squared = model.score(X, y)
        
        # Plot data
        plt.figure()
        plt.scatter(X, y, label="Data")
        plt.plot(X, y_pred, color="red", label=f"Fit: y = {slope:.3f}x + {intercept:.1f}\nR² = {r_squared:.3f}")
        
        # Labels and title
        plt.xlabel("Fitts' ID")
        plt.ylabel("Completion Time (ms)")
        plt.title(f"{condition} - Fitts' Law: Completion Time vs. Index of Difficulty")
        plt.legend()
        
        # Save the plot
        plt.savefig(f'{save_dir}/{condition}.png')

# Plot increasing data
plot_data('data/increasing-data.csv', 'plots/increasing')

# Plot decreasing data
plot_data('data/decreasing-data.csv', 'plots/decreasing')

# Show plot
plt.show()