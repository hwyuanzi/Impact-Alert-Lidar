# This file takes impactalert results

import csv

# for a given speed threshold and time to impact threshold, count the number
# of alarms
def countalerts(speedthresh, timetoimpactthresh, myspeeds, mytimes):
  print("speedthresh is " + str(speedthresh)) 
  print("timetoimpactthresh is " + str(timetoimpactthresh)) 
  alertcount = 0
  for i in range(len(myspeeds)):
    if (myspeeds[i] < speedthresh) and (mytimes[i] < timetoimpactthresh): 
       alertcount+= 1
  print("alert count is " + str(alertcount))

# for a given speed threshold,  time to impact threshold, 
# and danger indication compute
# the confusion matrix
def confusionmatrix(speedthresh, timetoimpactthresh, myspeeds, mytimes, mydangers):
   trueposcount = 0
   truenegcount = 0
   falseposcount = 0
   falsenegcount = 0
   for i in range(len(myspeeds)):
     if (myspeeds[i] < speedthresh) and (mytimes[i] < timetoimpactthresh) and (mydangers[i] == 'Yes'):
        trueposcount+=1
     elif (myspeeds[i] < speedthresh) and (mytimes[i] < timetoimpactthresh) and (mydangers[i] == 'No'):
        falseposcount += 1
     elif ((myspeeds[i] >= speedthresh) or (mytimes[i] >= timetoimpactthresh)) and (mydangers[i] == 'Yes'):
        falsenegcount+=1
     elif ((myspeeds[i] >= speedthresh) or (mytimes[i] >= timetoimpactthresh)) and (mydangers[i] == 'No'):
        truenegcount+=1
   print("Confusion Matrix")
   print("speedthresh is " + str(speedthresh)) 
   print("timetoimpactthresh is " + str(timetoimpactthresh)) 
   print("trueposcount is: " + str(trueposcount))
   print("falseposcount is: " + str(falseposcount))
   print("falsenegcount is: " + str(falsenegcount))
   print("truenegcount is: " + str(truenegcount))
   print("accuracy is: " + str((trueposcount+truenegcount)/len(myspeeds)))
   precision = (trueposcount)/(trueposcount+falseposcount)
   print("precision is: " + str(precision))
   recall = (trueposcount)/(trueposcount+falsenegcount)
   print("recall is: " + str(recall))
   print("F1-score is: " + str((2*(precision*recall))/(precision+recall)))



# DATA
debugging = 0

# EXECUTION

allrows=[]
allspeeds =[]
alltimes = []
alldangers = []
with open('impactexper.csv') as csvfile:
  csvin = csv.reader(csvfile, delimiter=',', quotechar='|')
  # Skip Header
  next(csvin)
  for row in csvin:
    allrows.append(row)
    allspeeds.append(float(row[2]))
    alltimes.append(float(row[3]))
    alldangers.append(row[4])


# print (allrows)
# print (alldangers)

print("  ")
speedthresh = -2.2
timetoimpactthresh = 3
countalerts(speedthresh, timetoimpactthresh, allspeeds, alltimes)
confusionmatrix(speedthresh,timetoimpactthresh, allspeeds, alltimes, alldangers)

print("  ")
speedthresh = -1.0
timetoimpactthresh = 3
countalerts(speedthresh, timetoimpactthresh, allspeeds, alltimes)
confusionmatrix(speedthresh,timetoimpactthresh, allspeeds, alltimes, alldangers)



print("  ")
speedthresh = -3.0
timetoimpactthresh = 3
countalerts(speedthresh, timetoimpactthresh, allspeeds, alltimes)
confusionmatrix(speedthresh,timetoimpactthresh, allspeeds, alltimes, alldangers)

print("  ")
speedthresh = -5.0
timetoimpactthresh = 3
countalerts(speedthresh, timetoimpactthresh, allspeeds, alltimes)
confusionmatrix(speedthresh,timetoimpactthresh, allspeeds, alltimes, alldangers)

print("  ")
speedthresh = -2.2
timetoimpactthresh = 5
countalerts(speedthresh, timetoimpactthresh, allspeeds, alltimes)
confusionmatrix(speedthresh,timetoimpactthresh, allspeeds, alltimes, alldangers)

print("  ")
speedthresh = -2.2
timetoimpactthresh = 1
countalerts(speedthresh, timetoimpactthresh, allspeeds, alltimes)
confusionmatrix(speedthresh,timetoimpactthresh, allspeeds, alltimes, alldangers)