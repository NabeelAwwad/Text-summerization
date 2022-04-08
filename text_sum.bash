#!/bin/sh
#Made by Nabeel Awwad 1160158 and Nadeen Shbayeh 1180517
#emptying any existing temporary files.
> temp1
> temp2
> temp3
> temp4
> temp5
> temp6
> summary.txt
#ask the user to enter the input file name
#checks whether the file is valid or not
while true; do
read -p "Enter the name of the desired input file: " inputfile
if [ ! -e "$inputfile" -o ! -f "$inputfile" -o ! -s "$inputfile" ]; then
 echo "The file doesn't exist, isn't ordinary or is empty. Press (R) to
retry or any other button to exit:"
 read answer
 if [ "$answer" = "r" ]; then
 continue
 else
 exit 1
 fi
else
 break
fi
done
#asks the user to enter the summary ratio
#checks whether the value entered is valid
while true; do
read -p "Enter the desired summary ratio(1-50%): " ratio
if [ -z "$ratio" ] || [ "$ratio" -lt 1 -o "$ratio" -gt 50 ]; then
 echo "the percentage must be between 1% and 50%. Press (R) to try again
or any button to exit:"
 read answer
 if [ "$answer" = "r" ]; then
 continue
 else
 exit 1
 fi
else
 break
fi
done
#convert to small letters and move the input to output.txt
sed 's/\(.*\)/\L\1/' $inputfile > temp1
#seperate sentences to be on each line
sed 's/[.?!] */&\n/g' temp1 > temp2
mv temp2 temp1
#remove empty lines
sed '/^$/d' temp1 > temp2
mv temp2 temp1
#remove stop words and remove [.?!]
sed -e 's/ i / /g' -e 's/^i //g' -e 's/ a / /g' -e 's/^a //g' -e 's/
a[snt] / /g' -e 's/^a[snt] //g' -e 's/ the / /g' -e 's/^the //g' -e 's/ by
/ /g' -e 's/^by //g' -e 's/ in / /g' -e 's/^in //g' -e 's/ for / /g' -e
's/^for //g' -e 's/ o[fn] / /g' -e 's/^o[fn] //g' -e 's/^that //g' -e 's/
that / /g' -e 's/[?!.]//g' temp1 > temp2
mv temp2 temp1
#remove similar words from each line
while IFS= read -r line
do
echo "$line" | awk '{for (i=1;i<=NF;i++) if (!a[$i]++)
printf("%s%s",$i,FS)}{printf("\n")}' >> temp2
done < temp1
mv temp2 temp1
#calculate the number of lines in file
numoflines=$( wc -l < temp1)
numoflines=$((numoflines+1))
# i and j are used as in this nested loop in order to find the sum of
similarities
i=1
while [ "$i" -ne "$numoflines" ]
do
 centrality=0
 j=1
 while [ "$j" -ne "$numoflines" ]
 do
 if [ "$i" -ne "$j" ]
 then
 #we take 2 lines each time from the file and send them to another
file for processing
 awk -v var=$i 'NR==var' temp1 >> temp3
 awk -v var=$j 'NR==var' temp1 >> temp3
 #this is where we calculate the number of similar words in both
sentences.
 wordssimilar=$(egrep -o "\b[[:alpha:]]+\b" temp3 | \
 awk ' { count[$0]++ }
 END{for(ind in count)
 {if(count[ind]>1){
 s++}
 }
 { print(s); }}'
 )
 #we set the counter for any results that didnt get counted to 0
 if [ "$wordssimilar" = "" ]
 then
 wordssimilar=0
 fi
 #this is used to calculate the total number of words so we could
find the similarity
 wordstotal=$(wc -w < temp3)
 wordsdifferent=$(expr $wordstotal - $wordssimilar)
 similarity=$(echo "scale=4; $wordssimilar / $wordsdifferent" | bc)
 #we immediately calculate the centrality from the sum of similarties
with each sentence.
 centrality=`echo $centrality + $similarity | bc`

 #clear file content
 > temp3
 fi
 j=$((j+1))
 done
 #we are done comparing the first sentence with the rest of the file. now
we move to the next one and increment i.
 echo "the centrality of sentence number $i is $centrality" >> temp4
i=$((i+1))
done
#after finishing the centrality calculation we sort the results in a new
file.
sort -r -k8 -n temp4 >> temp5
cat temp5
#calculating the number of lines in a file again to calculate the size of
the summary from the ratio entered by the user.
numoflines=$( wc -l < temp1)
summarypercent=$(echo $ratio / 100)
summarysize=`expr $numoflines \* $summarypercent`
#we take the 6th column from the file which contains the sorted index of
each sentence.
awk '{print $6}' temp5 > temp6
w=1
#we print out the lines from the first file as they are ordered.
while IFS= read -r line
do
 #we ignore the sentences that exceed the summary size.
 if [ "$w" -le "$summarysize" ]
 then
 awk -v var=$line 'NR==var' temp1 >> summary.txt
 fi
 w=$((w+1))
done < temp6
echo "$summarysize sentences were saved to summary.txt here is what's in
it:"
cat summary.txt