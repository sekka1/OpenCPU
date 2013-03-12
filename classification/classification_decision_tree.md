## Decision Tree Classifier
### Overview

Per Wikipedia: Classification is the problem of identifying to which of a set
of categories a new observation belongs, on the basis of a training set of data
containing observations whose category membership is known.

Decision tree learningi uses a decision tree as a predictive model which maps
observations about an item to conclusions about the item's target value. In
these tree structures, leaves represent class labels and branches represent
conjunctions of features that lead to those class labels.

It compares as follows with other classification algorithms

#### Advantages:
* Simple to understand and interpret.
* Requires little data preparation.
* Able to handle both numerical and categorical data.
* Possible to validate a model using statistical tests.
* Robust. Performs well even if its assumptions are somewhat violated by the true model from which the data were generated.
* Performs well with large data in a short time. Large amounts of data can be analysed using standard computing resources.

#### Disadvantages:
* Optimal Trees are difficult to calculate
* Prone to overfitting to the training data.
* For data including categorical variables with different numbers of levels, information gain in decision trees is biased in favor of those attributes with more levels.


### Customer Churn Example

Let us say that we are a mobile service provider and we wish to predict whether
a customer will close their account in the next 6 months based on their usage
patterns. Assume that we have historical (training) data about how they used
our service, and they are labeled based on whether the account was closed or
not. The data looks like:

<table>
<tr><td>Voice Usage (Minutes)</td><td>Data Usage (MB)</td><td>Support Calls</td><td>Payment Delay (Months)</td><td>Closed</td></tr>
<tr><td>3.20</td><td>22.85</td><td>0</td><td>1</td><td>FALSE</td></tr>
<tr><td>36.42</td><td>67.40</td><td>2</td><td>1</td><td>TRUE</td></tr>
<tr><td>5.44</td><td>148.13</td><td>1</td><td>0</td><td>FALSE</td></tr>
</table>

To paraphrase this example in the terms that we introduced earlier: We have 4
dimensional training data. The dimensions are "Voice Usage (Minutes)", "Data
Usage (MB)", "Support Calls" and "Payment Delay (Months)".  The target class
labels are "FALSE" and "TRUE" indicating whether it was closed.

Now let us see how this can be implemented on the Algorithms.io platform.

1. Download the [training
data](https://s3.amazonaws.com/sample_dataset.algorithms.io/customer_data_train.csv)
and the [testing
data](https://s3.amazonaws.com/sample_dataset.algorithms.io/customer_data_test.csv)

2.  [Upload](https://www.mashape.com/algorithms-io/algorithms-io#endpoint-Upload)
the files to algorithms.io.  Once uploaded, you will see a responses that look
like this
>   { "api": { "Authentication": "Success" }, "data": 3324 } # For training
>   { "api": { "Authentication": "Success" }, "data": 3325 } # For testing

3. Run classification using [Decision Tree](https://www.mashape.com/algorithms-io/algorithms-io#endpoint-Decision-Tree)
or do that using a this curl command

>		curl --include --request POST 'https://algorithms.p.mashape.com/jobs/swagger/<whatever>' \
>		--header 'X-Mashape-Authorization: <your Mashape header here>' \
>		-d 'method=sync' \
>		-d 'ouputType=json' \
>		-d 'train=3324' \
>		-d 'test=3325'

The output will be a json list of the predicted categories for each row in the
test data.
