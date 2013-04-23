# Medical diagnosis

This example guides you through the process of diagnosing a tumor.

For illustrating this use case, let us use a breast cancer database of 699
patients analyzed by Dr. William H.  Wolberg at the University of Wisconsin
Hospitals, Madison. He analyzed and scored 9 attributes of a tumor on a scale
of 0 - 10. He also classified the tumor as benign or malignant.

The database has 699 rows, one per patient, and the following columns:

# Clump thickness: scale of 0-10
# Uniformity of cell size: scale of 0-10
# Uniformity of cell shape: scale of 0-10
# Marginal adhesion: scale of 0-10
# Single epithelial cell size: scale of 0-10
# Bare nuclei (16 values are missing): scale of 0-10
# Bland chromatin: scale of 0-10
# Normal nucleoli: scale of 0-10
# Mitoses: scale of 0-10
# Class: "benign" or "malignant".

Your task is: given the attributes of a tumor, to predict whether it is benign
or malignant using a model that was trained with the pre-labelled data from the
above database. This is therefore a 'classification' problem.

## Comparing Classifiers
There are multiple choices when it comes to classification algorithms. In our
system, we have the following:

- [Multinomial Logistic Regression](http://catalog.algorithms.io/catalog/algo/id/47?category=/Classification)
- [Decision Tree](http://catalog.algorithms.io/catalog/algo/id/45?category=/Classification)
- [Random Forest](http://catalog.algorithms.io/catalog/algo/id/46?category=/Classification)
- [Neural Network](http://catalog.algorithms.io/catalog/algo/id/44?category=/Classification)
- [Support Vector Machine](http://catalog.algorithms.io/catalog/algo/id/49?category=/Classification)

Each has its own strengths and weaknesses. How do you determine which one is
the best fit *for your data*?

The best way is to compare the accuracy and performance of each of these
algorithms on a training and a test set. We provide a convenient way to do this
in our system using the [Compare
Classifiers](http://catalog.algorithms.io/catalog/algo/id/50?category=/Classification)
algorithm. To use this algorithm, you have to first split your database into a
training and a test set. Each of the above models will be trained using the
training dataset and evaluated with the test dataset to assess their
performance.

How do you split one database into a training and test datasets? We provide a
convenient way to do that using the [Split
Dataset](http://catalog.algorithms.io/catalog/algo/id/???) algorithm.

#### <a id="Input">Input</a>

Note that there are nine predictive variables (the first 9 columns), and one
dependent variable (the 10th column, "class").

Sample data for this example can be download here: [training
data](https://s3.amazonaws.com/sample_dataset.algorithms.io/customer_data_train.csv)
, [testing
data](https://s3.amazonaws.com/sample_dataset.algorithms.io/customer_data_test.csv).

The data can now be uploaded to the algorithms.io system.

Upload the training data to to algorithms.io. You can do this using curl as follows:

		curl -i -X POST 'http://v1.api.algorithms.io/dataset' 
				-H 'authToken: YOUR\_AUTHORIZATION\_TOKEN'  
				-F theFile=@customer\_data\_train.csv

The response will look like

		{ "api": { "Authentication": "Success" }, "data": 3481 }

indicating that the training data was uploaded to dataset 3481.

Next upload the test data.

		curl -i -X POST 'http://v1.api.algorithms.io/dataset' 
				-H 'authToken: YOUR\_AUTHORIZATION\_TOKEN'  
				-F theFile=@customer\_data\_test.csv

The response will look like

		{ "api": { "Authentication": "Success" }, "data": 3482 }

indicating that the test data was uploaded to dataset 3482.

#### <a id="Execution">Execution</a>
Run classifier aganist the two uploaded datasets.

		curl -X POST 
				-d 'method=sync' 
				-d 'outputType=json' 
				-d 'datasources=[]' 
				-d 'train="3481"' 
				-d 'test="3482"' 
				-d 'dependentVariable="closed"' 
				-H 'authToken: YOUR\_AUTHORIZATION\_TOKEN'  
				http://v1.api.algorithms.io/jobs/swagger/45

#### <a id="Output">Output</a>

The output will be a json list of the predicted categories for each record in
the test data. In this case, it will look like

		[ "TRUE", "TRUE", "FALSE", ... ]

This indicates that the algorithm predicts that the first two accounts in the
test set will close, whereas the third one will not.
