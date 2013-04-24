# K-Means Clustering
- **[Overview](#Overview)**
  - **[Description](#Description)**
  - **[Use Cases](#use_cases)**
- **[Tutorial](#Tutorial)**
  - **[Input](#Input_Parameters)**
  - **[Execution](#Execution)**
  - **[Output](#Output_Parameters)**

## <a id="Overview">Overview</a>
#### <a id="Description">Description</a>
Clustering is the process of organizing a set of items into subsets (called clusters) so that items in the same cluster are similar. The similarity between items can be defined by a function or a formula, based on the context. For example, the Euclidean distance between two points acts as a similarity function for list of points/co-ordinates in space. Clustering is a method of unsupervised learning and a common technique for statistical data analysis used in many fields. The term clustering can also refer to automatic classification, numerical taxonomy, topological analysis etc. For more information on Clustering, see <http://en.wikipedia.org/wiki/Cluster_analysis>.

#### <a id="use_cases">Use Cases</a>
K-means is a generic clustering algorithm that can be applied easily to many situations.  It’s can also readily be executed on parallel computers.  Typical use cases include:

- **Market Segmentation:** Used to divide a customer base into groups of individuals that are similar in specific ways relevant to marketing.  This allows a company to target specific groups of customers effectively and allocate marketing resources to best effect.
- **Computer vision:** Commonly used in computer vision as a form of image segmentation. The results of the segmentation are often used to aid border detection and object recognition

##<a id="Tutorial">Tutorial</a>

### Segmenting Customers

Here's an example to segment 1000 users.

#### <a id="Input_Parameters">Input</a>
You can download this data sample.  
This sample data describes cell phone usage of a group of 100 mobile customers.

	"","age","income","voice.minutes","data.usage"
	"1",39,46874,191.041990121121,71
	"2",59,135556,27.6701110472045,37
	"3",43,60147,82.4842368319897,95

First column is a customer ID.  This must be the only column with non-numeric data.  All the other columns of the CSV must be numeric. 
The 2nd to 5th columns represent some charactisterics of customer that will be used for the cluster analysis.
 
Now that there's a basic understanding of what data look like, next step is to upload it to Algorithms.IO with this call

	curl -i -H "authToken: YOUR_TOKEN" -H "friendly_name:ustomer-data" -H "friendly_description:small customer data" -H "version:1" -F theFile=@customer-data.csv http://v1.api.algorithms.io/dataset
		
Once uploaded, you will see a response that looks like this.  Note down the datasource reference.

	{
		"api": {
    		"Authentication": "Success"
    	},
    	"data": 3324
	}

#### <a id="Execution">Execution</a>	
Run clustering algorithm using [k-means endpoint](http://catalog.algorithms.io/dashboard/algodoc/id/51).

Input the data reference for dataset parameter.  To get started, you can leave the rest of parameters with their default values.  It will perform a cluster analysis to break the group down to 3 clusters, allowing for maximum of 100 iterations, by using Euclidean distance measure.

The cluster analysis can also be run with this curl command

	curl -X POST -d 'method=sync' -d 'outputType=json' -d 'dataset=3797' -d 'centers=10' -d "maxiter=100" -d 'measure=euclidean' -H 'authToken: YOUR_TOKEN' http://v1.api.algorithms.io/jobs/swagger/51

#### <a id="Output_Parameters">Output and Analysis</a>

The results will look like this:

	{
    	"output": {
            	"size": [
                	30,
                	41,
                	29
            	],
            	"centers": [
                	[
                    	29.96667,
                    	31972.3,
                    	144.626,
                    	172.5
                	],
                	[
                   		33.39024,
                    	125852.2,
                    	124.1542,
                    	166.3902
                	],
                	[
                    	25.03448,
                    	76086.03,
                    	116.1154,
                    	231.931
                	]
                ]
                "cluster": [
                	1,
                	2,
                	3,
					..
				]
			}
	}
	
The size object has the sizes of the final 3 clusters, 30, 41 and 29.  And the next is the centers of the clusters.  For example, the center of the first cluster has an age of 29.96667, income of 31972.3, voice.minutes of 144.626 and data.usage of 172.5.  Then at last, the cluster section lists out the cluster indices of all customers.  Here we know the first customer in the dataset now belongs to cluster 1 and second customer to cluster 2, etc.	

At a glance, these groups mostly differ in the income charateristic, with values 31972.3, 125852.2 and 76086.03.



