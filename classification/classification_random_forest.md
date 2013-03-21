# Random Forest classifier
## Overview
### Description
[Random forest](http://en.wikipedia.org/wiki/Random_forest) is an ensemble
classifier that consists of many decision trees and outputs the class that is
the mode of the classes output by individual trees.

It compares as follows with other classification algorithms

#### Advantages:
* It is one of the most accurate learning algorithms available. For many data sets, it produces a highly accurate classifier.
* It runs efficiently on large databases.
* It can handle thousands of input variables without variable deletion.
* It gives estimates of what variables are important in the classification.
* It generates an internal unbiased estimate of the generalization error as the forest building progresses.
* It has an effective method for estimating missing data and maintains accuracy when a large proportion of the data are missing.
* It has methods for balancing error in class population unbalanced data sets.
* Prototypes are computed that give information about the relation between the variables and the classification.
* It computes proximities between pairs of cases that can be used in clustering, locating outliers, or (by scaling) give interesting views of the data.
* The capabilities of the above can be extended to unlabeled data, leading to unsupervised clustering, data views and outlier detection.
* It offers an experimental method for detecting variable interactions.

#### Disadvantages:
* Random forests have been observed to overfit for some datasets with noisy classification/regression tasks.
* Unlike decision trees, the classifications made by random forests are difficult for humans to interpret.
* For data including categorical variables with different number of levels, random forests are biased in favor of those attributes with more levels. Therefore, the variable importance scores from random forest are not reliable for this type of data. Methods such as partial permutations were used to solve the problem.
* If the data contain groups of correlated features of similar relevance for the output, then smaller groups are favored over larger groups.

### Use Cases
General purpose classification

## Tags
supervised learning, classification, random forest, decision tree, multi-class

## Tutorial
### Customer Churn Example

Let us say that we are a mobile service provider and we wish to predict whether
a customer will close their account in the next 6 months based on their usage
patterns. Assume that we have historical (training) data about how they used
our service, and they are labeled based on whether the account was closed or
not.

#### Input

Sample data for this example can be download here: [training
data](https://s3.amazonaws.com/sample_dataset.algorithms.io/customer_data_train.csv)
, [testing
data](https://s3.amazonaws.com/sample_dataset.algorithms.io/customer_data_test.csv).

The data is formatted as a plain text CSV file with 5 columns. Here is what the
data looks like:

<table border="1">
<tr><td>Voice Usage (Minutes)</td><td>Data Usage (MB)</td><td>Support Calls</td><td>Payment Delay (Months)</td><td>Closed</td></tr>
<tr><td>3.20</td><td>22.85</td><td>0</td><td>1</td><td>FALSE</td></tr>
<tr><td>36.42</td><td>67.40</td><td>2</td><td>1</td><td>TRUE</td></tr>
<tr><td>5.44</td><td>148.13</td><td>1</td><td>0</td><td>FALSE</td></tr>
</table>

There are 4 predictive variables (input dimensions): "Voice Usage (Minutes)",
"Data Usage (MB)", "Support Calls" and "Payment Delay (Months)".  The the
dependent variable (the one we're trying to predict) is "Closed", which
indicates whether the account was closed. It takes the values "FALSE" and
"TRUE". Note that the "Closed" column must be present in the training data. 

The test set contains records for which we have access to the 4 dimensions
mentioned above and want to predict the dependent variable "Closed". If the
dependent variable is is present in the test data, it is ignored.

The data can now be uploaded to the algorithms.io system.

Upload the training data to to algorithms.io. You can do this using curl as follows:

> curl -i -X POST 'http://v1.api.algorithms.io/dataset' 
>      -H 'authToken: <YOUR AUTHORIZATION TOKEN>'  
>      -F theFile=@customer\_data\_train.csv

The response will look like

>   { "api": { "Authentication": "Success" }, "data": 3481 }

indicating that the training data was uploaded to dataset 3481.

Next upload the test data.

> curl -i -X POST 'http://v1.api.algorithms.io/dataset' 
>      -H 'authToken: <YOUR AUTHORIZATION TOKEN>'  
>      -F theFile=@customer\_data\_test.csv

The response will look like

>   { "api": { "Authentication": "Success" }, "data": 3482 }

indicating that the test data was uploaded to dataset 3482.

#### Execution
Run classifier aganist the two uploaded datasets.

> curl -X POST \
> -d 'method=sync' \
> -d 'outputType=json' \
> -d 'datasources=[]' \
> -d 'train={"datatype":"datasource","value":"3481"}' \
> -d 'test={"datatype":"datasource","value":"3482"}' \
> -d 'dependentVariable={"datatype":"string","value":"closed"}' \
> -H 'authToken: <YOUR AUTHORIZATION TOKEN>'  
> http://pod3.staging.v1.api.algorithms.io/jobs/swagger/46

#### Output

The output will be a json list of the predicted categories for each record in
the test data. In this case, it will look like

> [ "TRUE", "TRUE", "FALSE", ... ]

This indicates that the algorithm predicts that the first two accounts in the
test set will close, whereas the third one will not.
