clear all; clc
%% step 1: write a few lines of code or use FIJI to separately save the
% nuclear channel of the image Colony1.tif for segmentation in Ilastik

%% step 2: train a classifier on the nuclei
% try to get the get nuclei completely but separe them where you can
% save as both simple segmentation and probabilities
%both binary mask and probabilities saved in repository
%% step 3: use h5read to read your Ilastik simple segmentation
% and display the binary masks produced by Ilastik 
% (datasetname = '/exported_data')
% Ilastik has the image transposed relative to matlab
% values are integers corresponding to segmentation classes you defined,
% figure out which value corresponds to nuclei
nuc_mask=h5read('48hColony1_DAPI_Simple Segmentation.h5', '/exported_data');
nuc_mask2=squeeze(nuc_mask==2)'; %to get only nuclear mask, not empty space mask
figure(1)
imshow(nuc_mask2, []);
%% step 3.1: show segmentation as overlay on raw data
nuc_image_original=imread('48hColony1_DAPI.tif');
figure(2)
imshow(cat(3, im2double(imadjust(nuc_image_original)), nuc_mask2, zeros(size(nuc_image_original))));
%% step 4: visualize the connected components using label2rgb
% probably a lot of nuclei will be connected into large objects
L=im2bw(nuc_mask2); 
x=bwconncomp(nuc_mask2);
xx=labelmatrix(x);
rgb=label2rgb(xx,'jet',[.5 .5 .5]);
figure(3)
imshow(rgb);
%% step 5: use h5read to read your Ilastik probabilities and visualize
nuc_prob=h5read('Prediction for Label 2.h5', '/exported_data');
% it will have a channel for each segmentation class you defined
nuc_prob2=squeeze(nuc_prob==1)';
figure(4)
imshow(nuc_prob2, [])
%% step 6: threshold probabilities to separate nuclei better
nuc_prob3=nuc_prob2>0.999;
figure(5)
imshow(cat(3, nuc_mask2, nuc_prob2, zeros(size(nuc_image_original))));%didn't help that much
%% step 7: watershed to fill in the original segmentation (~hysteresis threshold)
CC = bwconncomp(nuc_prob2);
nuc_stats = regionprops(CC,'Area');
nuc_area = [nuc_stats.Area];
s = round(1.2*sqrt(mean(nuc_area))/pi);
nuc_erode = imerode(nuc_prob2,strel('disk',s));
nuc_outside = ~imdilate(nuc_prob2,strel('disk',1));
nuc_basin = imcomplement(bwdist(nuc_outside));
nuc_basin = imimposemin(nuc_basin,nuc_erode|nuc_outside);
L = watershed(nuc_basin);
figure(6)
imshow(label2rgb(L,'jet',[.5 .5 .5])) %helped a lot, but still lots connected
%% step 8: perform hysteresis thresholding in Ilastik and compare the results
% explain the differences
%it's mostly better at separating the nucleai, but still has trouble
%getting at the really connected nuclei
%% step 9: clean up the results more if you have time 
% using bwmorph, imopen, imclose etc
nuc_hyst=h5read('hysteresis_output.h5', '/exported_data');
nuc_hyst2=squeeze(nuc_hyst)';
figure(7)
imshow(label2rgb(nuc_hyst4,'jet',[.5 .5 .5]))
