#!/bin/bash 
echo "Running the following script: $1, $2 times \r\n \r\n"
COUNTER=0
while [  $COUNTER -lt $2 ]; do
    echo The counter is $COUNTER
    let COUNTER=COUNTER+1
    sh $1    
done
