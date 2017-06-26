function r=practicalMixGaussC

%The goal of this practical is to generate some data from an n-Dimensional
%mixtures of Gaussians model, and subsequently to fit an
%n-dimensional mixtures of Gaussians model to it to recover the original
%parameters

%You should use this template for your code and fill in the missing 
%sections marked "TO DO"

%close all open plots
close all;

%define true parameters for mixture of k Gaussians
%we will represent the mixtures of Gaussians as a Matlab structure
%in d dimenisions, the mean field
%will be a dxk matrix and the cov field will be a dxdxk matrix.
mixGaussTrue.k = 3;
mixGaussTrue.d = 2;
mixGaussTrue.weight = [0.1309 0.3966 0.4725];
mixGaussTrue.mean(:,1) = [ 4.0491 ; 4.8597];
mixGaussTrue.mean(:,2) = [ 7.7578 ; 1.6335];
mixGaussTrue.mean(:,3) = [11.9945 ; 8.9206];
mixGaussTrue.cov(:,:,1) = [  4.2534    0.4791;  0.4791    0.3522];
mixGaussTrue.cov(:,:,2) = [  0.9729    0.8723;  0.8723    2.6317];
mixGaussTrue.cov(:,:,3) = [  0.9886   -1.2244; -1.2244    3.0187];

%define number of samples to generate
nData = 400;

%generate data from the mixture of Gaussians
data = mixGaussGen(mixGaussTrue,nData);

%draw data, true Gaussians
figure;
drawEMData2d(data,mixGaussTrue);
drawnow;

%define number of components to estimate
nGaussEst = 3;

%fit mixture of Gaussians
figure;
mixGaussEst = fitMixGauss(data,nGaussEst);


%==========================================================================
%==========================================================================

%the goal of this function is to generate data from a k-dimensional
%mixtures of Gaussians structure.
function data = mixGaussGen(mixGauss,nData);

%create space for output data
data = zeros(mixGauss.d,nData);
%for each data point
for (cData =1:nData)
    %randomly choose Gaussian according to probability distributions
    h = sampleFromDiscrete(mixGauss.weight);
    %draw a sample from the appropriate Gaussian distribution
    %first sample from the covariance matrix (google how to do this - it
    %will involve the Matlab command 'chol').  Then add the mean vector
    %TO DO (f)-
    [T,err] = cholcov(sqrtm(mixGauss.cov(:,:,h)));
    mu = transpose(mixGauss.mean(:,h));
    data(:,cData) = randn(1,size(T,1)) * T + mu;
end;
    
%==========================================================================
%==========================================================================

function mixGaussEst = fitMixGauss(data,k);
        
[nDim nData] = size(data);
%MAIN E-M ROUTINE 
%there are nData data points, and there is a hidden variable associated
%with each.  If the hidden variable is 0 this indicates that the data was
%generated by the first Gaussian.  If the hidden variable is 1 then this
%indicates that the hidden variable was generated by the second Gaussian
%etc.

postHidden = zeros(k, nData);

%in the E-M algorithm, we calculate a complete posterior distribution over
%the (nData) hidden variables in the E-Step.  In the M-Step, we
%update the parameters of the Gaussians (mean, cov, w).  

%we will initialize the values to random values
%mixGaussEst.d = nDim;
%mixGaussEst.k = k;
%mixGaussEst.weight = (1/k)*ones(1,k);
%mixGaussEst.mean = 2*randn(nDim,k);
%for (cGauss =1:k)
%    mixGaussEst.cov(:,:,cGauss) = (0.5+1.5*rand(1))*eye(nDim,nDim);
%end;
mixGaussEst = initializeGaussians(data,k);

%calculate current likelihood
logLike = getMixGaussLogLike(data,mixGaussEst,k);
prevll = logLike;
fprintf('Log Likelihood Iter 0 : %4.3f\n',logLike);

l = zeros(k,1);

nIter = 40;
for (cIter = 1:nIter)
   % ===================== =====================
   %Expectation step
   % ===================== =====================
   
   for (cData = 1:nData)
        %TO DO (g): fill in column of 'hidden' - calculate posterior probability that
        %this data point came from each of the Gaussians
        for h = 1:k
            l(h) = mixGaussEst.weight(h)*calcGaussianProb(data(:,cData),mixGaussEst.mean(:,h),mixGaussEst.cov(:,:,h));
        end
        postHidden(:,cData) = l/(sum(l));
   end;
   
   %Maximization Step
   sum_resp1 = sum(transpose(postHidden));
   %for each constituent Gaussian
   for (cGauss = 1:k) 
        %TO DO (h):  Update weighting parameters mixGauss.weight based on the total
        %posterior probability associated with each Gaussian. 
        mixGaussEst.weight(cGauss) = sum_resp1(cGauss)/nData; 
   
        %TO DO (i):  Update mean parameters mixGauss.mean by weighted average
        %where weights are given by posterior probability associated with
        %Gaussian.  
        resp = repmat(postHidden(cGauss,:),nDim,1);
        m = resp .* data;
        sum_resp = sum(transpose(m));
        sum_post_hidden = sum(postHidden(cGauss,:));
        mixGaussEst.mean(:,cGauss) = sum_resp/sum_post_hidden;
        
        %TO DO (j):  Update covarance parameter based on weighted average of
        %square distance from update mean, where weights are given by
        %posterior probability associated with Gaussian
        mixGaussEst.cov(:,:,cGauss) = resp.*(data-mixGaussEst.mean(:,cGauss))*transpose(data-mixGaussEst.mean(:,cGauss))/sum_post_hidden;
   end;
   
   %draw the new solution
   drawEMData2d(data,mixGaussEst);drawnow;

   %calculate the log likelihood
   logLike = getMixGaussLogLike(data,mixGaussEst,k);
   if logLike == prevll
       fprintf('ENTERED');
       return;
   else
       prevll = logLike;
   end
   fprintf('Log Likelihood Iter %d : %4.3f\n',cIter,logLike);
end;


%==========================================================================
%==========================================================================

%the goal of this routine is to calculate the log likelihood for the whole
%data set under a mixture of Gaussians model. We calculate the log as the
%likelihood will probably be a very small number that Matlab may not be
%able to represent.
function logLike = getMixGaussLogLike(data,mixGaussEst,k);

%find total number of data items
nData = size(data,2);

%initialize log likelihoods
logLike = 0;

%run through each data item
for(cData = 1:nData)
    thisData = data(:,cData);    
    %TO DO - calculate likelihood of this data point under mixture of
    %Gaussians model. Replace this
    like = 0;
    for (h = 1:k)
        like = like + calcGaussianProb(thisData,mixGaussEst.mean(:,h),mixGaussEst.cov(:,:,h))*mixGaussEst.weight(h);
    end;
    %add to total log like
    logLike = logLike+log(like);        
end;

%==========================================================================
%==========================================================================

%the goal of this routine is to evaluate a Gaussian likleihood
function like = calcGaussianProb(data,gaussMean,gaussCov)

[nDim nData] = size(data);
A = 1/((2*pi)^(nData/2)*det(gaussCov)^(0.5));
B = exp(-0.5*transpose(data-gaussMean)*inv(gaussCov)*(data-gaussMean));

like = A*B;



%==========================================================================
%==========================================================================

%The goal fo this routine is to draw the data in histogram form and plot
%the mixtures of Gaussian model on top of it.
function r = drawEMData2d(data,mixGauss)


set(gcf,'Color',[1 1 1]);
plot(data(1,:),data(2,:),'k.');

for (cGauss = 1:mixGauss.k)
    drawGaussianOutline(mixGauss.mean(:,cGauss),mixGauss.cov(:,:,cGauss),mixGauss.weight(cGauss));
    hold on;
end;
plot(data(1,:),data(2,:),'k.');
axis square;axis equal;
axis off;
hold off;drawnow;

    


%=================================================================== 
%===================================================================

%draw 2DGaussian
function r= drawGaussianOutline(m,s,w)

hold on;
angleInc = 0.1;

c = [0.9*(1-w) 0.9*(1-w) 0.9*(1-w)];


for (cAngle = 0:angleInc:2*pi)
    angle1 = cAngle;
    angle2 = cAngle+angleInc;
    [x1 y1] = getGaussian2SD(m,s,angle1);
    [x2 y2] = getGaussian2SD(m,s,angle2);
    plot([x1 x2],[y1 y2],'k-','LineWidth',2,'Color',c);
end

%===================================================================
%===================================================================

%find position of in xy co-ordinates at 2SD out for a certain angle
function [x,y]= getGaussian2SD(m,s,angle1)

if (size(s,2)==1)
    s = diag(s);
end;

vec = [cos(angle1) sin(angle1)];
factor = 4/(vec*inv(s)*vec');

x = cos(angle1) *sqrt(factor);
y = sin(angle1) *sqrt(factor);

x = x+m(1);
y = y+m(2);

%==========================================================================
%==========================================================================

%draws a random sample from a discrete probability distribution using a
%rejection sampling method
function r = sampleFromDiscrete(probDist);

nIndex = length(probDist);
while(1)
    %choose random index
    r=ceil(rand(1)*nIndex);
    %choose random height
    randHeight = rand(1);
    %if height is less than probability value at this point in the
    %histogram then select
    if (randHeight<probDist(r))
        break;
    end;
end;

function mixGaussEst = initializeGaussians(data,k);
    [nDim,nData] = size(data);
    mixGaussEst.d = nDim;
    mixGaussEst.k = k;
    mixGaussEst.weight = (1/k)*ones(1,k);
    mixGaussEst.mean = zeros(nDim,k);
    mixGaussEst.cov = zeros(nDim,nDim,k);
    for iter = 1:k
        i = round(rand*nData);
        mixGaussEst.mean(:,iter) = data(:,i);
        for dim = 1:nDim
            mixGaussEst.cov(dim,dim,iter) = sum(sum((data-mixGaussEst.mean(dim,iter)).^2))/nData;
        end
    end
