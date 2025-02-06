class Condition {
  String name;
  String type;
  float strength; // strength of stickiness or gravity
  int totalTrials;
  int errorCount = 0;
  ArrayList<String> results = new ArrayList<String>();
  
  Condition(String name, String type, float strength, int totalTrials) {
    this.name = name;
    this.type = type;
    this.strength = strength;
    this.totalTrials = totalTrials;
  }
  
  void recordTrial(boolean success, long completionTime, float fittsID, int errors) {
    String result = name + "," + (results.size() + 1) + "," + fittsID + "," + completionTime + "," + errors;
    results.add(result);
  }
  
  void incrementErrorCount() {
    errorCount++;
  }
  
  int getErrorCount() {
    return errorCount;
  }
  
  void resetErrorCount() {
    errorCount = 0;
  }
  
  String getResults() {
    StringBuilder sb = new StringBuilder();
    for (String result : results) {
      sb.append(result).append("\n");
    }
    return sb.toString();
  }
}