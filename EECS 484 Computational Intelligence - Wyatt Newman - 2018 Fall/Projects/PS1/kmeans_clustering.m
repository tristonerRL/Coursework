%main clustering program
%uses 9 helper scripts: seed_clusters.m, find_minmax_feature_vals.m,
%scale_all_feature_vals.m, do_clustering.m, find_closes_cluster.m,
%remove_pattern_from_cluster.m, put_pattern_into_cluster.m,
%reassign_patterns.m and plot_clusters.m

%note: all  M-file scripts and data files must reside in the same directory.
clear all %make sure all variables from any previous runs are deleted

%start by loading training data

nclusters=20;  %a good number of clusters
max_passes=20; %set max number of sweeps through pattern reassignments...

%read in training data--227 companies from S&P 500 with data from Q1 of
%2008; attributes for these companies are stock-price increase percentages
%from Q1 to Q2.                       
training_data = xlsread('SP_training_data_Q1_w_dpriceQ2.csv');

%use features from Q1 to try to predict stock-price change from Q1 to Q2

%normalized features are in cols 15 to 22
raw_features=training_data(:,15:22);
attributes=training_data(:,23); % percent increase (decrease) in stock price is in col 23

temp = size(raw_features); %examine number of patterns and number of features
npatterns = temp(1); %number of rows is number of patterns in training set
nfeatures = temp(2); %number of feature values

%need to normalize all features w/rt min and max vals within training set
%vector to store max value of each feature
feature_max_vals=raw_features(1,:); %init to pattern 1 vals
feature_min_vals=raw_features(1,:); %same for min vals

%variable to hold features after scaling--initialized to all zeros
feature_scaled_vals=zeros(npatterns,nfeatures); %scaled feature values

find_minmax_feature_vals %invoke this m-fnc to populate feature_max_vals
% and feature_min_vals
scale_all_feature_values %and this to populate feature_scaled_vals

% data organization:
%each pattern belongs to a cluster; cluster #0==> unassigned
pattern_assignments=zeros(npatterns,1); %initialize all patterns to no cluster assignment

%cluster membership matrix: each row is a cluster, each column is a pattern; entries are 1 or 0 to
%mark if respective pattern belongs to respective cluster 
cluster_rosters=zeros(nclusters,npatterns);

%cluster properties: rows are clusters;
% cluster_populations is number of members;
% cluster attributes is avg attribute of each cluster
%cluster_centroids: cols are avg feature values for each cluster
cluster_populations=zeros(nclusters,1); %start w/ zero population in each cluster
cluster_attributes=zeros(nclusters,1); %average attributes need to be properly initialized 
cluster_centroids=zeros(nclusters,nfeatures); %need to be properly initialized

seed_clusters %initialize each cluster by selecting patterns at random from training data

do_clustering %cycle through all patterns at assign them to appropriate clusters

plot_clusters %visualize the clusters by homogeneity of attributes

%suspend code here, waiting for user input, before proceeding to validation
%computations
temp=input('enter to proceed to validation-set evaluation');
%%%%%%%%%%%%% TEST CLUSTERING W/ VALIDATION DATA%%%%%%%

%read in the validation data--51 companies not included in the previous
%clustering
validation_data=xlsread('SP_validation_data_Q1_w_dpriceQ2.csv');
raw_features=validation_data(:,15:22); %overwrites training-data raw features
val_attributes=validation_data(:,23); % percent increase (decrease) in stock price for validation data;
% note--DO NOT USE this data for stock picks (that would be cheating).
% Rather, use this data to score how well (or how poorly) the clustering
% algorithm performed in terms of picking winners from the validation pool

%expected return (per quarter) if invest uniformly over all 51 validation
%companies.  This is the number to beat through a more discriminating
%choice of investments:
index_return_avg = mean(val_attributes);

temp = size(raw_features); %examine number of patterns and number of features in validation set
npatterns = temp(1); %number of rows is number of patterns in validation set
%nfeatures = temp(2) %number of feature values--had better be same as
%training set!
%repeat many of the steps above used for initial clustering
%but don't change original clusters
%scale the validation features--overwrites feature_scaled_vals
feature_scaled_vals=zeros(npatterns,nfeatures); %to hold scaled feature values of validation data
scale_all_feature_values %populate feature_scaled_vals w/ vaidation features, scaled using
%same min/max feature values as used for the training data clustering
val_cluster_populations=zeros(nclusters,1); %start w/ zero population in each cluster
val_cluster_attributes=zeros(nclusters,1); %average attributes need to be properly initialized 
%each pattern belongs to a cluster; cluster #0==> unassigned
val_pattern_assignments = zeros(npatterns,1); %initialize all patterns to no cluster assignment

%run through clustering only once.  Do NOT recluster and do NOT recompute
%centroids or attribute averages of training-data clusters
%for visualization purposes, do compute average performance of validation
%data within each pre-defined cluster
for ipat=1:npatterns
    find_closest_cluster %closest cluster ID is filled in to variable closestClust
    val_pattern_assignments(ipat)=closestClust; %assign pattern ipat to cluster closestClust
    plot(closestClust,val_attributes(ipat),'+g')
    newpop=val_cluster_populations(closestClust)+1;
    val_cluster_populations(closestClust)=newpop;
    old_attribute=val_cluster_attributes(closestClust);
    new_attribute=val_attributes(ipat);
    val_cluster_attributes(closestClust)=old_attribute*(newpop-1)/newpop+new_attribute/newpop;
end

%plot averages of validation data attributes
for jclust=1:nclusters
    if (val_cluster_populations(jclust)>0) %only diplay validation avg if at least one validation pattern in the cluster
       plot(jclust,val_cluster_attributes(jclust),'vm')
    end
end

%DO SOMETHING HERE TO DECIDE WHICH VALIDATION COMPANIES TO PICK, USING
%RESULTS FROM TRAINING-DATA CLUSTERING.

clusters_to_pick = zeros(nclusters, 1);

Q1 = quantile(cluster_attributes,0.25);
Q3 = quantile(cluster_attributes,0.75);
quantile_diff_over_two = (Q3 - Q1) / 2;

avg_centroid = mean(cluster_centroids);

for iclust=1:nclusters
    if (Q1 < cluster_attributes(iclust) && ...
             cluster_attributes(iclust) < Q3) || ...
             (cluster_populations(iclust) > 10 && ...
             cluster_attributes(iclust) >= quantile_diff_over_two) || ...
             (sum(cluster_centroids(iclust)) > sum(avg_centroid))
        clusters_to_pick(iclust) = 1;
    end
end

%COMPUTE THE CORRESPONDING RETURN ON INVESTMENT FOR THESE COMPANIES
%USING THE CORRESPONDING ATTRIBUTE VALUES

population = 0;
avg_return_rate = 0.0;
num_chosen_clusters = 0;

%find average return rate of investments
for iclust=1:nclusters
    if clusters_to_pick(iclust) == 1
        avg_return_rate = avg_return_rate + (val_cluster_attributes(iclust)*val_cluster_populations(iclust));
        population = population + val_cluster_populations(iclust);
        num_chosen_clusters = num_chosen_clusters + 1;
    end
end

%only calculate average return rate if population > 0
if population > 0
    avg_return_rate = avg_return_rate / population;
else
    avg_return_rate = 0.0;
end

fprintf('avg return rate is: %f\n', avg_return_rate);

fprintf('number of clusters chosen from is: %d\n', num_chosen_clusters);

if avg_return_rate > index_return_avg 
    fprintf('you have chosen winning investments\n')
else
    fprintf('you have chosen losing investments\n')
end
    