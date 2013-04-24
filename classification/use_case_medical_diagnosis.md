# Medical diagnosis

This example guides you through the process of diagnosing a tumor.

For illustrating this use case, let us use a breast cancer database of 699
patients analyzed by Dr. William H.  Wolberg at the University of Wisconsin
Hospitals, Madison. He analyzed and scored 9 attributes of a tumor on a scale
of 0 - 10. He also classified the tumor as benign or malignant.

The database has 699 rows (one per patient) and the following columns:

* Clump thickness: scale of 0-10
* Uniformity of cell size: scale of 0-10
* Uniformity of cell shape: scale of 0-10
* Marginal adhesion: scale of 0-10
* Single epithelial cell size: scale of 0-10
* Bare nuclei (16 values are missing): scale of 0-10
* Bland chromatin: scale of 0-10
* Normal nucleoli: scale of 0-10
* Mitoses: scale of 0-10
* Class: "benign" or "malignant".

Your task is: given the attributes of a tumor, to predict whether it is benign
or malignant using a model that was trained with the pre-labelled data from the
above database. This is a 'classification' problem where the predictive
variables are the nine numerical attributes and the 'dependent variable' is the
Class (benign or malignant).

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
algorithms using the same data and compare their predictions. We provide a
convenient way to do this in our system using the [Compare
Classifiers](http://catalog.algorithms.io/catalog/algo/id/50?category=/Classification)
algorithm. To use this algorithm, you have to take a small representative
sample of fully labelled data and split it into a training and a test set.
Since our entire patient database has only 699 entries, that qualifies as a
small sample and can therefore be used as is.

How do you split one sample dataset into a training and test datasets? We
provide a convenient way to do that using the [Split
Dataset](http://catalog.algorithms.io/catalog/algo/id/???) algorithm. This
algorithm takes as input the id of the dataset that needs to be split and a
fraction between 0 and 1 which determines how much of the input dataset goes
into the first file. The remaining go into the second file. The output of the
Split Dataset algorithm is a json array of two elements. These are the dataset
ids of the training and test datasets.

Once you have your training and testing datasets, you are ready to compare the
classifiers. You can try that out
[here](https://dashboard.algorithms.io/catalog/algodoc/id/50?category=/Classification&swagger_method=sync&swagger_outputType=json&swagger_train=3351&swagger_test=3352&swagger_dependentVariable=closed).

The output of the Compare Classifiers algorithm is a json object that contains
three parallel arrays. The first, "algos" is the list of algorithms that were
compared. The second, "success" is the fraction of the labels in the test
dataset that was correctly predicted by the corresponding algorithm, and the
third "timePerRecord" is a measure of how fast the algorithm is.

## Choosing and running a classifier

In this case, it looks like they all had comparable performance except for the
Neural Network classifier, which was significantly worse. We will investigate
why in a different article. For now, let us go with the Decision Tree
classifier since it was both accurate and fast with our sample.

Now on to the main task. We have one or more unlabelled records (the new test
dataset) for which we know the values for all nine tumor attributes but not
whether or it is malignant. That is what we wish to predict.  This can be done
using the Decision Tree classifier using a single call as shown
[here](https://dashboard.algorithms.io/catalog/algodoc/id/45?category=/Classification&swagger_method=sync&swagger_outputType=json&swagger_train=3351&swagger_test=3352&swagger_dependentVariable=closed)

The output is a json array whose length is the same as the number of records in
the test dataset. Each element in the array is the predicted value ("benign" or
"malignant") for the corresponding record in the test set.
