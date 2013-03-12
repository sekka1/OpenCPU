## Neural Network Classifier
### Overview

Per Wikipedia: Classification is the problem of identifying to which of a set
of categories a new observation belongs, on the basis of a training set of data
containing observations whose category membership is known.

A neural network is a mathematical model inspired by biological neural
networks, which changes its structure during a learning phase. Neural networks
are used to model complex relationships between inputs and outputs or to find
patterns in data.

This particular implmentation allows for the creation of networks with three
layers. One input layer has as many nodes as input features, One output layer
which has as many nodes as output classes, and one hidden node whose size is
configurable. Larger values for hidden layer size will provide the ability to
model more complex functions, at the expense of making the computation more CPU
intensive, and making the network more prone to overfitting.

It compares as follows with other classification algorithms

#### Advantages:
* Can model highly non linear classification problems
* Overfitting can be adjusted via tuning the size of the hidden layer

#### Disadvantages:
* Computationally intensive
* Results are difficult to interpret as a neural network is a 'black box' model.

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
Usage (MB)", "Support Calls" and "Payment Delay (Months)".  The data is
labelled into two categories "FALSE" and "TRUE" indicating whether it was
closed.

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

3. Run classification using [Neural Network](https://www.mashape.com/algorithms-io/algorithms-io#endpoint-Neural Network)
or do that using a this curl command

>		curl --include --request POST 'https://algorithms.p.mashape.com/jobs/swagger/<whatever>' \
>		--header 'X-Mashape-Authorization: <your Mashape header here>' \
>		-d 'method=sync' \
>		-d 'ouputType=json' \
>		-d 'size=10' \
>		-d 'train=3324' \
>		-d 'test=3325'

The output will be a json list of the predicted categories for each row in the
test data.
