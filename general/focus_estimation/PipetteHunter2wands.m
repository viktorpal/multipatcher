classdef PipetteHunter2wands < matlab.mixin.SetGet
    %PIPETTEHUNTER2WANDS Pipette Hunter 3D for DIC microscopy
    %   The class fits the 3D 2-wands model to a stack image of a pipette, then estimates the tip by an assumed tip
    %   width. The algorithm is a variational framework with simple gradient descent. The iterations stop if the
    %   maximum number of iterations is reached or if the estimated tip position did not change much in the last few
    %   iterations. Various parameters can be set. The successful outcome of the detection highly depends on the
    %   starting points of the model. Thus, some smart way of setting the initial parameters is reccommended, eg.
    %   setting by manually or a global optimezer algorithm. When run() method finishes, the model's center point can be
    %   found in the 'center' property, but using the 'estimatedTipPosition' instead is recommended.
    
    properties (Constant, Hidden)
        defaultShow = false;
        defaultBgCorrection = true;
        defaultPhiStepsizeDeg = 7.5;%7.5;
        defaultRhoStepsize = 2;%2;
        defaultNumiter = 5000;
        defaultZScale = 0.115;
        defaultTolerance = 1; %10^1;
        defaultEstimatedTipSizeUm = 2.5;
        defaultZetaStepsize = 2; % 5
        defaultGaussFilter = true;
        defaultInvert = true; %false;
        defaultDeltaRho = 15; % 15 
        defaultZeta1 = 0;
        defaultZeta2 = 1200;
%         defaultPhi1 = pi+deg2rad(0);%-17.5
%         defaultPhi2 = pi/3+deg2rad(0); % -1.5
        defaultPhi3 = 0+deg2rad(0); % yaw?
        defaultEta = 2;
        defaultAlpha = deg2rad(0);%15;
        defaultAlphaShrink = 0;%10^-3;% 10^-3;
        defaultXMult = 10^-3; %10^-3
        defaultPhiMult = 10^-9;
        defaultEtaMult = 10^-4; %10^-4
        defaultAlphaMult = 10^-9; %10^-8;
        defaultPenaltyValue = 0;
        defaultCheckTermination = 100;
        optimizerOpts = optimset('TolFun', 10^-4, 'TolX', 10^-4, 'MaxIter', 5000, 'MaxFunEvals', 5000, 'Display', 'off', 'PlotFcns', []);
    end
    
    properties
        imgTarget
        show
        bgCorrection
        checkTermination
        phiStepsizeDeg
        rhoStepsize
        numiter
        zScale
        tolerance
        estimatedTipSizeUm
        zetaStepsize
        gaussFilter
        invert
        deltaRho 
        zeta1
        zeta2
        center
        phi1
        phi2
        phi3
        eta
        alpha
        alphaShrink
        xMult
        phiMult
        etaMult
        alphaMult
        penaltyValue
    end
    
    properties (SetAccess = protected)
        estimatedTipPosition
        centerStart
        phiStart
        etaStart
        alphaStart
    end
    
    properties (Access = protected)
        projFig
        xprojAx
        yprojAx
        zprojAx
        hStartingPosition
        hCurrentPosition
        startedRunning
    end
    
    methods
        function this = PipetteHunter2wands()
            this.show = this.defaultShow;
            this.bgCorrection = this.defaultBgCorrection;
            this.phiStepsizeDeg = this.defaultPhiStepsizeDeg;
            this.rhoStepsize = this.defaultRhoStepsize;
            this.numiter = this.defaultNumiter;
            this.zScale = this.defaultZScale;
            this.tolerance = this.defaultTolerance;
            this.estimatedTipSizeUm = this.defaultEstimatedTipSizeUm;
            this.zetaStepsize = this.defaultZetaStepsize;
            this.gaussFilter = this.defaultGaussFilter;
            this.invert = this.defaultInvert;
            this.deltaRho = this.defaultDeltaRho;
            this.zeta1 = this.defaultZeta1;
            this.zeta2 = this.defaultZeta2;
            this.phi3 = this.defaultPhi3;
            this.eta = this.defaultEta;
            this.alpha = this.defaultAlpha;
            this.alphaShrink = this.defaultAlphaShrink;
            this.xMult = this.defaultXMult;
            this.phiMult = this.defaultPhiMult;
            this.etaMult = this.defaultEtaMult;
            this.alphaMult = this.defaultAlphaMult;
            this.penaltyValue = this.defaultPenaltyValue;
            this.checkTermination = this.defaultCheckTermination;
            this.startedRunning = false;
        end
        
        function delete(~)
        end
        
        function set.imgTarget(this, value)
            assert(ischar(value) || (ndims(value)==3 && isnumeric(value)) || isa(value, 'ImageStack'));
            this.imgTarget = value;
        end
        
        function set.show(this, value)
            assert(islogical(value), 'Value should be logical');
            this.show = value;
        end
        
        function set.bgCorrection(this, value)
            assert(islogical(value), 'Value should be logical');
            this.bgCorrection = value;
        end
        
        function set.phiStepsizeDeg(this, value)
            assert(~isempty(value) && isnumeric(value) && value>0, 'Value should be a number greater than 0.');
            this.phiStepsizeDeg = value;
        end
        
        function set.rhoStepsize(this, value)
            assert(~isempty(value) && isnumeric(value) && value>0, 'Value should be a number greater than 0.');
            this.rhoStepsize = value;
        end
        
        function set.numiter(this, value)
            assert(~isempty(value) && isnumeric(value) && value>0 && round(value)==value, ...
                'Value should be a round number greater than 1.');
            this.numiter = value;
        end
        
        function set.zScale(this, value)
            assert(~isempty(value) && isnumeric(value) && value>0, 'Value should be a number greater than 0.');
            this.zScale = value;
        end
        
        function set.tolerance(this, value)
            assert(~isempty(value) && isnumeric(value) && value>0, 'Value should be a number greater than 0.');
            this.tolerance = value;
        end
        
        function set.estimatedTipSizeUm(this, value)
            assert(~isempty(value) && isnumeric(value) && value>0, 'Value should be a number greater than 0.');
            this.estimatedTipSizeUm = value;
        end
        
        function set.zetaStepsize(this, value)
            assert(~isempty(value) && isnumeric(value) && value>0, 'Value should be a number greater than 0.');
            this.zetaStepsize = value;
        end
        
        function set.gaussFilter(this, value)
            assert(islogical(value), 'Value should be logical');
            this.gaussFilter = value;
        end
        
        function set.invert(this, value)
            assert(islogical(value), 'Value should be logical');
            this.invert = value;
        end
        
        function set.deltaRho(this, value)
            assert(~isempty(value) && isnumeric(value) && value>0, 'Value should be a number greater than 0.');
            this.deltaRho = value;
        end
        
        function set.zeta1(this, value)
            assert(~isempty(value) && isnumeric(value), 'Value should be a number.');
            this.zeta1 = value;
        end
        
        function set.zeta2(this, value)
            assert(~isempty(value) && isnumeric(value), 'Value should be a number.');
            this.zeta2 = value;
        end
        
        function set.center(this, value)
            assert(~isempty(value) && isnumeric(value) && numel(value)==3 && isrow(value), ...
                'Value should be a 3 element numeric row vector.');
            this.center = value;
        end
        
        function set.phi1(this, value)
            assert(~isempty(value) && isnumeric(value), 'Value should be a number.');
            this.phi1 = value;
        end
        
        function set.phi2(this, value)
            assert(~isempty(value) && isnumeric(value), 'Value should be a number.');
            this.phi2 = value;
        end
        
        function set.phi3(this, value)
            assert(~isempty(value) && isnumeric(value), 'Value should be a number.');
            this.phi3 = value;
        end
        
        function set.eta(this, value)
            assert(~isempty(value) && isnumeric(value), 'Value should be a number.');
            this.eta = value;
        end
        
        function set.alpha(this, value)
            assert(~isempty(value) && isnumeric(value), 'Value should be a number.');
            this.alpha = value;
        end
        
        function set.alphaShrink(this, value)
            assert(~isempty(value) && isnumeric(value) && value>=0, 'Value should be a number greater or equal to 0.');
            this.alphaShrink = value;
        end
        
        function set.xMult(this, value)
            assert(~isempty(value) && isnumeric(value) && value>0, 'Value should be a number greater than 0.');
            this.xMult = value;
        end
        
        function set.phiMult(this, value)
            assert(~isempty(value) && isnumeric(value) && value>0, 'Value should be a number greater than 0.');
            this.phiMult = value;
        end
        
        function set.etaMult(this, value)
            assert(~isempty(value) && isnumeric(value) && value>0, 'Value should be a number greater than 0.');
            this.etaMult = value;
        end
        
        function set.alphaMult(this, value)
            assert(~isempty(value) && isnumeric(value) && value>0, 'Value should be a number greater than 0.');
            this.alphaMult = value;
        end
        
        function set.penaltyValue(this, value)
            assert(~isempty(value) && isnumeric(value), 'Value should be a number.');
            this.penaltyValue = value;
        end
        
        function set.checkTermination(this, value)
            assert(~isempty(value) && isnumeric(value) && value>=0, 'Value should be a number greater or equal to 0.');
            this.checkTermination = value;
        end
        
        function run(this)
            this.validate();
            this.estimatedTipPosition = [];
            this.centerStart = this.center;
            this.phiStart = [this.phi1, this.phi2, this.phi3];
            this.etaStart = this.eta;
            this.alphaStart = this.alpha;
            this.startedRunning = true;
            
            I = this.loadImageFromTarget();

            if this.bgCorrection
            %     bg = imgaussfilt(I, bgcorrSigma);
                bg = median(I,3);
                I = I - bg;
            end
            origStack = I;
            [sy, sx, sz] = size(I);

            dx = [-1 0 1];
            dy = dx';
            dz = zeros(1,1,3);
            dz(:) = dx(:);
            
            if this.show
                this.prepareFigure(I);
                this.visualizeStartingPosition();
                this.updateVisualization();
            end

            I = origStack;
            for i = 1:size(I,3)
                I(:,:,i) = mat2gray(I(:,:,i));
            end

            minvalue = min(I(:));
            I = I - minvalue;
            maxvalue = max(I(:));
            I = I./maxvalue;
            if this.gaussFilter
            %     I = imgaussfilt3(I, [25, 25, 2.5]);
%                 I = imgaussfilt3(I, [5, 5, 0.5]);
                I = imgaussfilt3(I, [1.5, 1.5, 0.5]);
            end
            if this.invert
                I(:) = 1 - I(:);
            end
            %%


            Ix = imfilter(I, dx, 'replicate');
            Iy = imfilter(I, dy, 'replicate');
            Iz = imfilter(I, dz, 'replicate');

            phiStepsize = deg2rad(this.phiStepsizeDeg);
            zetaValues = this.zeta1:this.zetaStepsize:this.zeta2;
            phiValues = 0:phiStepsize:2*pi-eps; % this is supposed to be the capital Phi
            rhoValues = 0:this.rhoStepsize:this.deltaRho;
            params = allcomb(zetaValues, 1:numel(phiValues), rhoValues);
            cPhi = cos(phiValues)';
            sPhi = sin(phiValues)';
            cPhi = cPhi(params(:,2));
            sPhi = sPhi(params(:,2));
            params3cPhi = params(:,3).*cPhi;
            params3sPhi = params(:,3).*sPhi;
            subconvcf = cumprod([sy sx sz]);
            intersection = [Inf Inf Inf];
            lastIntersection = intersection;
            intersectionHistory = zeros(ceil((this.numiter-1)/max(this.checkTermination,1)), 10);

            for iter = 1:this.numiter
                s1 = sin(this.phi1);
                c1 = cos(this.phi1);
                s2 = sin(this.phi2);
                c2 = cos(this.phi2);
                s3 = sin(this.phi3);
                c3 = cos(this.phi3);

                R1 = [ c1, -s1,  0; ...
                       s1,  c1,  0; ...
                       0,    0,  1];
                R2 = [ c2,   0, s2; ...
                        0,   1,  0; ...
                      -s2,   0, c2];
                R3 = [ c3, -s3,  0; ...
                       s3,  c3,  0; ...
                        0,   0,  1];
                R12 = R1*R2;
                Rall = R12*R3;
                e1 = Rall(:,1)';
                e2 = Rall(:,2)';
                n  = Rall(:,3)';

                sa = sin(this.alpha);
                ca = cos(this.alpha);

                params1Sa = params(:,1).*sa;
                params1Ca = params(:,1).*ca;

%                 ctr = 0;

                Pp = params3cPhi*e1 + (+this.eta + params1Sa + params3sPhi*ca)*e2 + (params1Ca - params3sPhi*sa)*n;
                Pm = params3cPhi*e1 + (-this.eta - params1Sa + params3sPhi*ca)*e2 + (params1Ca + params3sPhi*sa)*n;
                Pp(:,3) = Pp(:,3)*this.zScale;
                Pm(:,3) = Pm(:,3)*this.zScale;
                Pp = round(this.center + Pp);
                Pm = round(this.center + Pm);
                [Pp, pp_penalty] = ph3_validatePoint(Pp, sx, sy, sz);
                [Pm, pm_penalty] = ph3_validatePoint(Pm, sx, sy, sz);
                Pp = Pp(:,1) + (Pp(:,2)-1)*subconvcf(1) + (Pp(:,3)-1)*subconvcf(2);
                Pm = Pm(:,1) + (Pm(:,2)-1)*subconvcf(1) + (Pm(:,3)-1)*subconvcf(2);

                nipp = [Ix(Pp(:)), Iy(Pp(:)), Iz(Pp(:))];
                nipm = [Ix(Pm(:)), Iy(Pm(:)), Iz(Pm(:))];
                nipp(pp_penalty,:) = this.penaltyValue;
                nipm(pm_penalty,:) = this.penaltyValue;

                tmp1 = params3cPhi*(c2*e2 - s2*s3*n);
                %%
                dPp_dphi1 = tmp1 ...
                            -(+this.eta + params1Sa + params3sPhi*ca)*(c2*e1 + s2*c3*n) ...
                            +(params1Ca - params3sPhi*sa)*s2*(s3*e1+c3*e2); % the other may be faster (less vectorized, but less multiplications)
                dPm_dphi1 = tmp1 ...
                            -(-this.eta - params1Sa + params3sPhi*ca)*(c2*e1 + s2*c3*n) ...
                            +(params1Ca + params3sPhi*sa)*s2*(s3*e1+c3*e2);
                dPp_dphi2 = ((+this.eta + params1Sa + params3sPhi*ca)*s3 - params3cPhi*c3)*n ...
                            + (params1Ca - params3sPhi*sa)*(c3*e1 - s3*e2);
                dPm_dphi2 = ((-this.eta - params1Sa + params3sPhi*ca)*s3 - params3cPhi*c3)*n ...
                            + (params1Ca + params3sPhi*sa)*(c3*e1 - s3*e2);
                dPp_dphi3 = params3cPhi*e2 - (+this.eta + params1Sa + params3sPhi*ca)*e1;
                dPm_dphi3 = params3cPhi*e2 - (-this.eta - params1Sa + params3sPhi*ca)*e1;
                dPp_dalpha = (+params1Ca - params3sPhi*sa)*e2 + (-params1Sa - params3sPhi*ca)*n;
                dPm_dalpha = (-params1Ca - params3sPhi*sa)*e2 + (-params1Sa + params3sPhi*ca)*n;
                dPp_deta = +e2;
                dPm_deta = -e2;

                Ephi1 = nipp.*dPp_dphi1 + nipm.*dPm_dphi1;
                Ephi1 = sum(Ephi1(:));
                Ephi2 = nipp.*dPp_dphi2 + nipm.*dPm_dphi2;
                Ephi2 = sum(Ephi2(:));
                Ephi3 = nipp.*dPp_dphi3 + nipm.*dPm_dphi3;
                Ephi3 = sum(Ephi3(:));
                Eeta = nipp.*dPp_deta + nipm.*dPm_deta;
                Eeta = sum(Eeta(:));
                Ealpha = nipp.*dPp_dalpha + nipm.*dPm_dalpha;
                Ealpha = sum(Ealpha(:));
                ER = sum(nipp + nipm,1);

                this.center(1) = this.center(1) + this.xMult*ER(1);
                this.center(2) = this.center(2) + this.xMult*ER(2);
                this.center(3) = this.center(3) + this.zScale*this.xMult*ER(3);
                this.phi1 = this.phi1 + this.phiMult*Ephi1;
                this.phi2 = this.phi2 + this.zScale*this.phiMult*Ephi2;
                this.phi3 = this.phi3 + this.phiMult*Ephi3;
                this.eta = this.eta + this.etaMult*Eeta;
                this.alpha = this.alpha + this.alphaMult*Ealpha - this.alphaShrink;

                if this.show
                    fprintf(['%d. \tR = %.3f %.3f %.3f, \tphi = %.4f %.4f %.4f, eta = %.2f, alpha = %.4f, ', ...
                        '\tER = %.2f %.2f %.2f, \tEphi = %.0f %.0f %.0f, \tEeta = %.4f, \tEalpha = %.2f \n'], iter, ...
                        this.center(1), this.center(2), this.center(3), this.phi1, this.phi2, this.phi3, this.eta, ...
                        this.alpha, ER(1), ER(2), ER(3), Ephi1, Ephi2, Ephi3, Eeta, Ealpha);
                    this.updateVisualization();
                end


                if this.checkTermination~=0 &&  mod(iter-1, this.checkTermination) == 0
            %         leg1vec = ca*n+sa*e2;
            %         leg2vec = ca*n-sa*e2;
            %         C1 = R + (eta*e2 + b*leg1vec).*[1, 1, zScale];
            %         C2 = R - (eta*e2 + b*leg2vec).*[1, 1, zScale];
                    leg1vec = ca*n+sa*e2;
                    leg2vec = ca*n-sa*e2;
                    Rp = this.center + this.eta*e2;
                    Rm = this.center - this.eta*e2;
%                     fcn = @(x) norm(Rp + leg1vec.*[1, 1, this.zScale]*x - (Rm + leg2vec.*[1, 1, this.zScale]*x));
                    fcn = @(x) abs(norm(Rp + leg1vec.*[1, 1, this.zScale]*x - ...
                                       (Rm + leg2vec.*[1, 1, this.zScale]*x))-this.estimatedTipSizeUm/this.zScale);
                    x = fminsearch(fcn, 0, this.optimizerOpts);
                    intersection1 = Rm + leg2vec.*[1, 1, this.zScale]*x;
                    intersection2 = Rp + leg1vec.*[1, 1, this.zScale]*x;
                    intersection = (intersection1 + intersection2)./2;

                    intersectionDiffNorm = norm((lastIntersection-intersection)./[1,1,this.zScale]);
                    intersectionHistory(floor(iter/this.checkTermination)+1,:) = ...
                        [intersection, intersection1, intersection2, intersectionDiffNorm];
                    if intersectionDiffNorm < this.tolerance
                        log4m.getLogger().trace(['Termination criteria reached: ', num2str(intersectionDiffNorm)]);
                        break
                    else
                        log4m.getLogger().trace(['Intersection difference norm: ', num2str(intersectionDiffNorm)]);
                    end
                    lastIntersection = intersection;
                end
            end

            if this.show
                this.updateVisualization();
            end
            log4m.getLogger().trace(sprintf(['%Final values: \tR = %.3f %.3f %.3f, \tphi = %.4f %.4f %.4f, eta = %.2f, alpha = %.4f, ', ...
                        '\tER = %.2f %.2f %.2f, \tEphi = %.0f %.0f %.0f, \tEeta = %.4f, \tEalpha = %.2f \n'], iter, ...
                        this.center(1), this.center(2), this.center(3), this.phi1, this.phi2, this.phi3, this.eta, ...
                        this.alpha, ER(1), ER(2), ER(3), Ephi1, Ephi2, Ephi3, Eeta, Ealpha));
            fcn = @(x) abs(norm(Rp + leg1vec.*[1, 1, this.zScale]*x - ...
                (Rm + leg2vec.*[1, 1, this.zScale]*x))-this.estimatedTipSizeUm/this.zScale);
            x = fminsearch(fcn, 0, this.optimizerOpts);
            intersection1 = Rm + leg2vec.*[1, 1, this.zScale]*x;
            intersection2 = Rp + leg1vec.*[1, 1, this.zScale]*x;
            intersection = (intersection1 + intersection2)./2;
            this.estimatedTipPosition = intersection;
        end
        
        function estimatedTipPosition = estimateTipPosition(this)
            s1 = sin(this.phi1);
            c1 = cos(this.phi1);
            s2 = sin(this.phi2);
            c2 = cos(this.phi2);
            s3 = sin(this.phi3);
            c3 = cos(this.phi3);

            R1 = [ c1, -s1,  0; ...
                   s1,  c1,  0; ...
                   0,    0,  1];
            R2 = [ c2,   0, s2; ...
                    0,   1,  0; ...
                  -s2,   0, c2];
            R3 = [ c3, -s3,  0; ...
                   s3,  c3,  0; ...
                    0,   0,  1];
            R12 = R1*R2;
            Rall = R12*R3;
            e1 = Rall(:,1)'; %#ok<NASGU>
            e2 = Rall(:,2)';
            n  = Rall(:,3)';
            sa = sin(this.alpha);
            ca = cos(this.alpha);
            
            leg1vec = ca*n+sa*e2;
            leg2vec = ca*n-sa*e2;
            Rp = this.center + this.eta*e2;
            Rm = this.center - this.eta*e2;
            fcn = @(x) abs(norm(Rp + leg1vec.*[1, 1, this.zScale]*x - ...
                (Rm + leg2vec.*[1, 1, this.zScale]*x))-this.estimatedTipSizeUm/this.zScale);
            x = fminsearch(fcn, 0, this.optimizerOpts);
            intersection1 = Rm + leg2vec.*[1, 1, this.zScale]*x;
            intersection2 = Rp + leg1vec.*[1, 1, this.zScale]*x;
            estimatedTipPosition = (intersection1 + intersection2)./2;
        end
        
        function showStartingPosition(this)
            if ~this.startedRunning
                error('Run the algorithm first with the run() method!');
            end
            if isempty(this.projFig)
                this.prepareFigure();
            end
            if isempty(this.hStartingPosition)
                this.visualizeStartingPosition();
            else
                set(this.hStartingPosition, 'Visible', 'on');
            end
        end
        
        function hideStartingPosition(this)
            if ~isempty(this.hStartingPosition)
                set(this.hStartingPosition, 'Visible', 'off');
            end
        end
        
        function visualize(this)
            if ~this.startedRunning
                error('Run the algorithm first with the run() method!');
            end
            if isempty(this.projFig)
                this.prepareFigure();
            end
            this.updateVisualization();
        end
    end
    
    methods (Access = protected)
        function validate(this)
            assert(~isempty(this.imgTarget), '''imgTarget'' cannot be empty.');
            assert(~isempty(this.center), '''center'' cannot be empty.');
            assert(~isempty(this.phi1), '''phi1'' cannot be empty.');
            assert(~isempty(this.phi2), '''phi2'' cannot be empty.');
            assert(this.zeta2>this.zeta1, '''zeta2'' should be greater than ''zeta1''.');
        end
        
        function I = loadImageFromTarget(this)
            if ischar(this.imgTarget)
                imgstack = ImageStack.load(this.imgTarget);
                I = imgstack.getStack();
            elseif isa(this.imgTarget, 'ImageStack')
                I = this.imgTarget.getStack();
            else
                I = this.imgTarget;
            end
        end
        
        function prepareFigure(this, I)
            if nargin < 2
                I = this.loadImageFromTarget();
            end
            
            dx = [-1 0 1];
            dy = dx';
            dz = zeros(1,1,3);
            dz(:) = dx(:);
            Ix = imfilter(I, dx, 'replicate');
            Iy = imfilter(I, dy, 'replicate');
            Iz = imfilter(I, dz, 'replicate');
            I = abs(Ix+Iy+Iz);

            minvalue = min(I(:));
            I = I - minvalue;
            maxvalue = max(I(:));
            I = I./maxvalue;

            if this.gaussFilter
            %     I = imgaussfilt3(I, [25, 25, 2.5]);
                I = imgaussfilt3(I, [1.5, 1.5, 0.5]);
            end

%                 I = mat2gray(I - median(I,3));

            xproj = squeeze(max(I, [], 2));
            yproj = squeeze(max(I, [], 1));
            zproj = max(I, [], 3);
%                 xproj = squeeze(min(I, [], 2));
%                 yproj = squeeze(min(I, [], 1));
%                 zproj = min(I, [], 3);
            this.projFig = figure;
            ss = get(0,'screensize');
            ss(2) = round(ss(4)*2/3);
            ss(4) = round(ss(4)/3);
            set(this.projFig,'position',ss);
            this.xprojAx = subplot(1,3,1);
            this.yprojAx = subplot(1,3,2);
            this.zprojAx = subplot(1,3,3);
            imagesc(xproj, 'Parent', this.xprojAx), colormap gray
            imagesc(yproj, 'Parent', this.yprojAx), colormap gray
            imagesc(zproj, 'Parent', this.zprojAx), colormap gray
            view(this.xprojAx, [-90, 90]);
            view(this.yprojAx, [-90, 90]);
            this.xprojAx.NextPlot = 'add';
            this.yprojAx.NextPlot = 'add';
            this.zprojAx.NextPlot = 'add';
            drawnow;
        end
        
        function visualizeStartingPosition(this)
            this.hStartingPosition = ph3_visualize2legsProjections(this.xprojAx, this.yprojAx, this.zprojAx, ...
                this.centerStart, this.phiStart(1), this.phiStart(2), this.phiStart(3), this.zeta1, this.deltaRho, ...
                this.etaStart, this.alphaStart, this.zeta2, this.zScale, [247, 255, 218]./255);
        end
        
        function updateVisualization(this)
            delete(this.hCurrentPosition);
            this.hCurrentPosition = ph3_visualize2legsProjections(this.xprojAx, this.yprojAx, this.zprojAx, ...
                this.center, this.phi1, this.phi2, this.phi3, this.zeta1, this.deltaRho, this.eta, this.alpha, ...
                this.zeta2, this.zScale, 'red');
            drawnow;
        end
    end
    
end

