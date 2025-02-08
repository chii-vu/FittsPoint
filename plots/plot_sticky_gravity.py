import pandas as pd
import matplotlib.pyplot as plt
from sklearn.linear_model import LinearRegression


# Separate conditions into Sticky and Gravity
sticky_conditions = ["Sticky-Zero", "Sticky-Low", "Sticky-Medium", "Sticky-High"]
gravity_conditions = ["Gravity-Zero", "Gravity-Low", "Gravity-Medium", "Gravity-High"]

# Function to plot grouped conditions from a single data file
def plot_grouped_conditions(data_file, conditions, title, filename):
    plt.figure(figsize=(16, 10))

    # Load data
    data = pd.read_csv(data_file)
    
    for condition in conditions:
        df = data[data["ConditionName"].str.contains(condition)]
        
        # Remove outliers using IQR method
        Q1 = df['CompletionTime'].quantile(0.25)
        Q3 = df['CompletionTime'].quantile(0.75)
        IQR = Q3 - Q1
        df = df[~((df['CompletionTime'] < (Q1 - 1.5 * IQR)) | (df['CompletionTime'] > (Q3 + 1.5 * IQR)))]
        
        # Extract values
        X = df['FittsID'].values.reshape(-1, 1)
        y = df['CompletionTime'].values
        
        # Count total errors
        total_errors = df['Errors'].sum()
        
        # Fit linear regression
        model = LinearRegression()
        model.fit(X, y)
        y_pred = model.predict(X)
        
        # Compute R²
        r_squared = model.score(X, y)
        slope = model.coef_[0]
        intercept = model.intercept_
        
        # Plot data
        plt.scatter(X, y, label=f'{condition} Trials (Errors: {total_errors})', alpha=0.2)
        plt.plot(X, y_pred, label=f'{condition} Fit: y = {slope:.3f}x + {intercept:.1f} (R²={r_squared:.3f})')
    
    plt.xlabel("Fitts' ID")
    plt.ylabel("Completion Time (ms)")
    plt.title(title)
    plt.legend()
    plt.grid()
    plt.savefig(filename, dpi=300, bbox_inches='tight')
    plt.show()

# Plot Sticky and Gravity conditions together for each data file
plot_grouped_conditions("data/increasing-data.csv", sticky_conditions + gravity_conditions, "Increasing Data Conditions", "Both_Increasing.png")
plot_grouped_conditions("data/decreasing-data.csv", sticky_conditions + gravity_conditions, "Decreasing Data Conditions", "Both_Decreasing.png")