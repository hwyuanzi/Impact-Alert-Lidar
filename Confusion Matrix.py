import re
from collections import defaultdict

# LaTeX
latex_table = r"""
\textbf{Video ID} & \textbf{Time In Video} & \textbf{Speed} & \textbf{Time to Impact} & \textbf{Collision Danger} \\ \hline
Walking1 & 0:03:50 & -0.77 m/sec & 5.48s sec & No \\ \hline
Walking1 & 0:04:10 & -0.63 m/sec & 6.33 sec & No \\ \hline
Walking1 & 0:04:30 & -2.5 m/sec & 1.75 sec & Yes \\ \hline
Walking1 & 0:04:50 & -3.63 m/sec & 1.12 sec & Yes \\ \hline
Walking1 & 0:05:10 & -4.28 m/sec & 0.91 sec & Yes \\ \hline
Walking1 & 0:05:30 & -6.34 m/sec & 0.58 sec & Yes \\ \hline
Walking1 & 0:05:50 & -7.05 m/sec & 0.47 sec & Yes \\ \hline
Walking2 & 0:03:00 & -0.27 m/sec & 21.38 sec & No \\ \hline
Walking2 & 0:03:20 & -7.73 m/sec & 0.73 sec & Yes \\ \hline
Walking2 & 0:03:40 & -7.77 m/sec & 0.62 sec & Yes \\ \hline
Walking2 & 0:04:00 & -8.78 m/sec & 0.52 sec & Yes \\ \hline
Walking2 & 0:04:20 & -10.40 m/sec & 0.39 sec & Yes \\ \hline
Walking2 & 0:04:40 & -8.80 m/sec & 0.41 sec & Yes \\ \hline
Walking2 & 0:05:00 & -8.10 m/sec & 0.37 sec & Yes \\ \hline
Car1 & 0:01:15 & -1.67 m/sec & 4.52 sec & No \\ \hline
Car1 & 0:01:35 & -5.08 m/sec & 1.58 sec & Yes \\ \hline
Car1 & 0:01:55 & -6.02 m/sec & 1.18 sec & Yes \\ \hline
Car1 & 0:02:15 & -7.18 m/sec & 0.94 sec & Yes \\ \hline
Car1 & 0:02:35 & -10.58 m/sec & 0.59 sec & Yes \\ \hline
Car1 & 0:02:55 & -8.93 m/sec & 0.7 sec & Yes \\ \hline
Car1 & 0:03:15 & -0.11 m/sec & 12.7 sec & No \\ \hline
Car2 & 0:01:30 & -2.30 m/sec & 4.18 sec & No \\ \hline
Car2 & 0:01:50 & -3.78 m/sec & 2.82 sec & Yes \\ \hline
Car2 & 0:02:10 & -6.04 m/sec & 1.56 sec & Yes \\ \hline
Car2 & 0:02:30 & -7.54 m/sec & 1.07 sec & Yes \\ \hline
Car2 & 0:02:50 & -8.23 m/sec & 0.36 sec & Yes \\ \hline
Car2 & 0:03:10 & -4.05 m/sec & 1.76 sec & Yes \\ \hline
Car2 & 0:03:30 & -6.16 m/sec & 1.18 sec & Yes \\ \hline
Car2 & 0:03:50 & -0.08 m/sec & 116.03 sec & No \\ \hline
Car3 & 0:00:45 & -3.92 m/sec & 9999.00 sec & No \\ \hline
Car2 & 0:01:05 & 4.33 m/sec & 9999.00 sec & No \\ \hline
Car2 & 0:01:25 & 3.37 m/sec & 9999.00 sec & No \\ \hline
Car2 & 0:01:45 & -0.95 m/sec & 8.92 sec & No \\ \hline
Bus1 & 0:16:40 & -0.68 m/sec & 24.91 sec & No \\ \hline
Bus1 & 0:17:00 & -0.62 m/sec & 21.24 sec & No \\ \hline
Bus1 & 0:17:20 & -4.12 m/sec & 3.44 sec & No \\ \hline
Bus1 & 0:17:40 & -6.35 m/sec & 1.57 sec & Yes \\ \hline
Bus1 & 0:18:00 & -10.90 m/sec & 0.76 sec & Yes \\ \hline
Bus1 & 0:18:20 & -12.26 m/sec & 0.62 sec & Yes \\ \hline
Bus1 & 0:18:40 & -11.96 m/sec & 0.70 sec & Yes \\ \hline
Bus1 & 0:19:00 & -7.24 m/sec & 1.40 sec & Yes \\ \hline
Bus2 & 0:05:25 & -1.54 m/sec & 7.62 sec & No \\ \hline
Bus2 & 0:05:45 & -2.92 m/sec & 3.71 sec & No \\ \hline
Bus2 & 0:06:05 & -3.61 m/sec & 3.00 sec & No \\ \hline
Bus2 & 0:06:35 & -3.20 m/sec & 3.57 sec & No \\ \hline
Bus2 & 0:06:55 & -3.05 m/sec & 3.54 sec & No \\ \hline
Scooter1 & 0:00:22 & -4.50 m/sec & 2.73 sec & Yes \\ \hline
Scooter1 & 0:00:42 & -0.90 m/sec & 11.81 sec & Yes \\ \hline
Scooter1 & 0:01:05 & -0.53 m/sec & 21.63 sec & No \\ \hline
Scooter2 & 0:00:35 & -3.5 m/sec & 1.03 sec & Yes \\ \hline
Scooter2 & 0:00:55 & -4.86 m/sec & 1.03 sec & No \\ \hline
Trike1 & 0:04:50 & -0.25 m/sec & 45.90 sec & No \\ \hline
Trike1 & 0:05:10 & -6.03 m/sec & 2.37 sec & Yes \\ \hline
Trike1 & 0:05:30 & -8.75 m/sec & 1.39 sec & Yes \\ \hline
Trike1 & 0:05:50 & -7.97 m/sec & 1.09 sec & Yes \\ \hline
"""


# Extraction
def parse_latex_table(latex_table):
    data = []
    skipped_count = 0 #Counter

    for line in latex_table.split("\n"):
        if "&" in line:
            parts = [x.strip() for x in line.split("&")]
            if len(parts) >= 5:
                speed_match = re.search(r"-?\d+\.?\d*", parts[2])
                tti_match = re.search(r"\d+\.?\d*", parts[3])
                danger_str = re.sub(r"\\.*", "", parts[4]).strip().lower()
                if speed_match and tti_match:
                    speed = float(speed_match.group())
                    tti = float(tti_match.group())
                    if tti >= 9999:
                        skipped_count += 1
                        continue
                    danger = danger_str == "yes"
                    data.append((speed, tti, danger))

    print(f"\n Skipped rows due to TTI ≥ 9999: {skipped_count}")
    return data

def compute_confusion_by_vehicle(latex_table, speed_thresh=-2.2, tti_thresh=3.0):
    vehicle_confusion = defaultdict(lambda: defaultdict(int))

    for line in latex_table.strip().split("\n"):
        if "&" not in line:
            continue
        parts = [x.strip() for x in line.split("&")]
        if len(parts) >= 5:
            vehicle_match = re.match(r"([A-Za-z]+)", parts[0])
            if not vehicle_match:
                continue
            vehicle = vehicle_match.group()
            speed_match = re.search(r"-?\d+\.?\d*", parts[2])
            tti_match = re.search(r"\d+\.?\d*", parts[3])
            danger_str = re.sub(r"\\.*", "", parts[4]).strip().lower()
            if speed_match and tti_match:
                speed = float(speed_match.group())
                tti = float(tti_match.group())
                if tti >= 9999:
                    continue
                actual_danger = danger_str == "yes"
                predicted_danger = (speed <= speed_thresh) and (tti <= tti_thresh)

                if actual_danger and predicted_danger:
                    vehicle_confusion[vehicle]["TP"] += 1
                elif not actual_danger and predicted_danger:
                    vehicle_confusion[vehicle]["FP"] += 1
                elif actual_danger and not predicted_danger:
                    vehicle_confusion[vehicle]["FN"] += 1
                else:
                    vehicle_confusion[vehicle]["TN"] += 1

    return vehicle_confusion

data = parse_latex_table(latex_table)

# Threshold
SPEED_THRESHOLD = -2.2
TTI_THRESHOLD = 3.0

# Confusion Matrix
confusion_matrix = defaultdict(int)  # TP, FP, FN, TN

for speed, tti, actual_danger in data:
    predicted_danger = (speed <= SPEED_THRESHOLD) and (tti <= TTI_THRESHOLD)
    if actual_danger and predicted_danger:
        confusion_matrix["TP"] += 1
    elif not actual_danger and predicted_danger:
        confusion_matrix["FP"] += 1
    elif actual_danger and not predicted_danger:
        confusion_matrix["FN"] += 1
    else:
        confusion_matrix["TN"] += 1


# Indicators
def compute_metrics(confusion_matrix):
    TP = confusion_matrix["TP"]
    FP = confusion_matrix["FP"]
    FN = confusion_matrix["FN"]
    TN = confusion_matrix["TN"]

    accuracy = (TP + TN) / (TP + FP + FN + TN)
    precision = TP / (TP + FP) if (TP + FP) > 0 else 0
    recall = TP / (TP + FN) if (TP + FN) > 0 else 0
    specificity = TN / (TN + FP) if (TN + FP) > 0 else 0

    return {
        "Accuracy": accuracy,
        "Precision": precision,
        "Recall (Sensitivity)": recall,
        "Specificity": specificity,
    }

metrics = compute_metrics(confusion_matrix)

# Outputs
print("=== Confusion Matrix ===")
print(f"True Positives (TP): {confusion_matrix['TP']}")
print(f"False Positives (FP): {confusion_matrix['FP']}")
print(f"False Negatives (FN): {confusion_matrix['FN']}")
print(f"True Negatives (TN): {confusion_matrix['TN']}\n")

print("=== Performance Metrics ===")
for metric, value in metrics.items():
    print(f"{metric}: {value:.2%}")

print("\n=== Summary ===")
print(f"Total Samples: {len(data)}")
print(
    f"Predicted Danger (Speed ≤ {SPEED_THRESHOLD} & TTI ≤ {TTI_THRESHOLD}): {confusion_matrix['TP'] + confusion_matrix['FP']}")
print(f"Actual Danger (Yes): {confusion_matrix['TP'] + confusion_matrix['FN']}")
print(f"Actual Safe (No): {confusion_matrix['TN'] + confusion_matrix['FP']}")

vehicle_confusions = compute_confusion_by_vehicle(latex_table, SPEED_THRESHOLD, TTI_THRESHOLD)

print("\n=== Confusion Matrix by Vehicle Type ===")
for vehicle in sorted(vehicle_confusions):
    cm = vehicle_confusions[vehicle]
    print(f"{vehicle}: TP={cm['TP']}, TN={cm['TN']}, FP={cm['FP']}, FN={cm['FN']}")