clear;

lookback=252; % use lookback days as estimation (training) period for determining factor exposures.
numFactors=5;
topN=50; % for trading strategy, long stocks with topN expected 1-day returns.

load('IJR_20080114'); % test on SP600 smallcap stocks. (This MATLAB binary input file contains tday, stocks, op, hi, lo, cl arrays.

mycls=fillMissingData(cl);

positionsTable=zeros(size(cl));

dailyret=(mycls-lag1(mycls))./lag1(mycls); % note the rows of dailyret are the observations at different time periods

for t=lookback+1:length(tday)

    R=dailyret(t-lookback+1:t,:)'; % here the columns of R are the different observations.
    
    hasData=find(all(isfinite(R), 2)); % avoid any stocks with missing returns
    
    R=R(hasData, :);
    
    avgR=smartmean(R, 2);
    R=R-repmat(avgR, [1 size(R, 2)]); % subtract mean from returns
    
    covR=smartcov(R'); % compute covariance matrix, with observations in rows.
    
    [X, B]=eig(covR); % X is the factor exposures matrix, B the variances of factor returns
    
    X(:, 1:size(X, 2)-numFactors)=[]; % Retain only numFactors
    
    results=ols(R(:, end), X); % b are the factor returns for time period t-1 to t.
    b=results.beta;
    
    Rexp=avgR+X*b; % Rexp is the expected return for next period assuming factor returns remain constant.
    
    [foo idxSort]=sort(Rexp, 'ascend');
    
    positionsTable(t, hasData(idxSort(1:topN)))=-1; % short topN stocks with lowest expected returns
    positionsTable(t, hasData(idxSort(end-topN+1:end)))=1; % buy topN stocks with highest  expected returns
end

ret=smartsum(backshift(1, positionsTable).*dailyret, 2); % compute daily returns of trading strategy
avgret=smartmean(ret)*252 % compute annualized average return of trading strategy
% A very poor return!
% avgret =
% 
%    -1.8099